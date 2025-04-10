function set-main {
    
    #Prompt user to input a key name and secret 
    $cred = Get-Credential 
    $Key = $cred.UserName
    
    ###Expiration Date Logic###
    $ExDate = Read-Host "If you would like to set an expiration date please do it here (MM-DD-YYYY)"
    
    try {
        if($ExDate){
            #Parse the expiration date
            $ExDateParsed = [DateTime]::ParseExact($ExDate, "MM-dd-yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
    
            #Convert to UTC (Set-AzKeyVaultSecret requires UTC)
            $ExDateParsedUtc = $ExDateParsed.ToUniversalTime()
    
            #Set the expiration date for the Key Vault secret
            Set-AzKeyVaultSecret -VaultName $KV -Name $Key -SecretValue $cred.Password -Expires $ExDateParsedUtc
        }  
        else {
            #If no expiration date provided, just set the secret
            Set-AzKeyVaultSecret -VaultName $KV -Name $Key -SecretValue $cred.Password
        }
    }
    catch {
        Write-Host "An error has occurred: $_"
    }

    #Get Az Secret metadata and secret values 
    $keyName = (get-azkeyvaultsecret -vaultName $KV -Name $Key)
    $password = (get-azkeyvaultsecret -vaultName $KV -Name $Key).SecretValue
    $passwordtext = (get-azkeyvaultsecret -vaultName $KV -Name $Key).Expires
    $keyName | Format-Table
    $password
    $passwordtext
    
    #Convert password from secure string 
    $DecryptedPassword = ConvertFrom-SecureString -AsPlainText $password
    Write-Host -ForegroundColor Cyan "Youre Secret is: $DecryptedPassword"   
}




#Set Error action preference 
$ErrorActionPreference = "Stop" 


#region 1: dependency checks
#Connecting to your sub Module Dependency 
#Write-Host -ForegroundColor Green "Getting Az Subs..."


# Ensure Az.Accounts module is available and proceed to sign in
if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
    Install-Module -Name Az.Accounts -Force -Scope CurrentUser
}
Import-Module -Name Az.Accounts

# Check for an active Azure connection
$context = Get-AzContext

if ($null -eq $context) {
    # No active session found; connect to Azure
    try {
        Write-Host "No active session found. Connecting to Azure..."
        Connect-AzAccount | Out-Null
    }
    catch {
        Write-Host -ForegroundColor Red "Something went wrong during the connection to Azure: $_"
        return
    }
} else {
    Write-Host -ForegroundColor Green "User is already connected. Proceeding..."
}


###------------------------------------------###
###check if user has proper installed modules###
###------------------------------------------### 

try {
    # Install and import the Microsoft KeyVault module if it's not already installed
        if (-not (Get-Module -ListAvailable -Name Az.KeyVault)) {
        Install-Module -Name Az.KeyVault -Force
    }
        Import-Module Az.KeyVault
}
catch {
        Write-Host "An Error occured while attempting to install and import the module $_"
}   


#endregion 
#print all az subs to screen

#region 2: Key Configuration 
try {
    $Subs = Get-AzSubscription -WarningAction SilentlyContinue
    Write-Output "Attempted to fetch subscriptions with warning suppression..."
    Write-Output $Subs

}
catch {
    Write-Host "Error encountered: $_"
}


#ask user for sub
$Subs = Get-AzSubscription
$Subs
$Subscription = Read-Host "Please paste in the subscription ID from above"
Select-AzSubscription -Subscription $Subscription

##############################################################
#######Get Az Role assignment for check of permissions########
##############################################################

try {
    # Get the account context
    $Identity = (Get-AzContext).Account

    # Convert the Account object to a string (this will give you the UserPrincipalName as a string)
    $StringID = $Identity.ToString()

    # Use the string ID to fetch the Azure AD user
    $ObjectID = (Get-AzADUser -UserPrincipalName $StringID).Id

    #Grab roles for RBAC check
    $AzUserRoles = Get-AzRoleAssignment -ObjectId $ObjectID
    $RbacTable = $AzUserRoles | Select-Object RoleDefinitionName, Scope | Format-Table
    $RbacTable 
}catch {
    Write-Host "An error occured while attempting to fetch your rbac roles $_"
}

###########################
########  USER INFO  ######
###########################

#Notify user of their current RBAC Roles
Write-Host -ForegroundColor Yellow -BackgroundColor DarkRed `
"IMPORTANT: Your Azure RBAC Roles are listed above and you may need additional access to view or set keys and secrets"
Write-Host -ForegroundColor Green "Below is a list of RBAC Permissions you may need to complete certain operations" 

#List of RBAC Roles presented to user as information
$KeyVaultRoles = @{
    "Key Vault Administrator" = "Full access to secrets, keys, and certs. No RBAC or vault settings."
    "Key Vault Reader" = "View metadata only. No secret or key access."
    "Key Vault Purge Operator" = "Can permanently delete soft-deleted vaults."
    "Key Vault Certificates Officer" = "Manage certificates only. No secret/key read or permissions."
    "Key Vault Certificate User" = "Read full certificate including private key."
    "Key Vault Crypto Officer" = "Manage keys. No access to permissions."
    "Key Vault Crypto Service Encryption User" = "Wrap/unwrap key operations only."
    "Key Vault Crypto User" = "Perform cryptographic operations with keys."
    "Key Vault Crypto Service Release User" = "Release keys for secure compute use."
    "Key Vault Secrets Officer" = "Manage secrets. No access to permissions."
    "Key Vault Secrets User" = "Read secret values and private cert info."
}

$KeyVaultRoles | Out-Host

Start-Sleep -Milliseconds 500

# a while loop that will prompt user to either update or create a secret
while ($true) {
    $answer = Read-Host "Would you like to Update an existing secret(Y/N)? Selecting 'N' you will proceed to viewing keys and secrets"
    $answer = $answer.ToUpper() #convert to upper case

    #if true then we will print out secrets if not we will continue and prompt for input of the new key
    try {
        if($answer -eq "Y"){
            #Print Vaults for user to select from 
            Get-AzKeyVault -SubscriptionId $Subscription | Select-Object VaultName | Format-Table
            $KV = Read-Host "Please select a vault from your subscription: $Subscription"
            Get-AzKeyVaultSecret -VaultName $KV | Format-Table
            Write-Host -ForegroundColor Yellow "Please input the key you wish to edit into the name field below"
            # call the set main function which is a function to create/set keys 
            set-main
            exit
        }
        elseif ($answer -eq "N"){
            break
        }
        else {
            Write-Host "Invalid input. Please enter 'Y' or 'N'."
        }

    }
    catch {
        Write-Host "Key Vault Secrets User RBAC Role or higher required to view $_"   
    }
}


#Store username and password in keyvault#
While($True) {
    #Get Subscriptions
    Get-AzKeyVault -SubscriptionId $Subscription | Select-Object VaultName | Format-Table

    ###Prompts###
    #Vault Prompt
    $KV = Read-Host "Please select a vault from your subscription"
    $vaultName = Get-AzKeyVault -Name $KV

        #ErrorChecking Loop
        if($null -eq $vaultName){
            Write-Host -ForegroundColor Red "This is not a valid KeyVault: $_"
            continue
        }
        

    #Key select prompt
    try {
        #Output Key Names to screen
        $Keys = (get-azkeyvaultsecret -vaultName "$KV").Name
        $Keys
        if($null -eq $Keys){
            Write-Host -ForegroundColor Yellow "There are no keys in this vault"
            continue
        }
    }
    catch {
        Write-Host "An error has occured: $_"
    }
    
    $Key = Read-Host "Please paste in a key above from your vault to view its metadata"
    $keyName = (get-azkeyvaultsecret -vaultName $KV -Name $Key)

        #error checking loop if null loop and prompt
        
        If($null -eq $keyName){
            Write-Host -ForegroundColor Red "This is not a valid keyName: $_"
            continue
        }
    
        Write-Host -ForegroundColor Green "This is a valid Key, Grabbing metadata..." 
        

    #Function for viewing keys, lives inside main
    #Get Az Secret metadata and secret values 

    #####$keyName = (get-azkeyvaultsecret -vaultName $KV -Name $Key)
        $password = (get-azkeyvaultsecret -vaultName $KV -Name $Key).SecretValue
        $passwordExpire = (get-azkeyvaultsecret -vaultName $KV -Name $Key).Expires
        $keyName | format-list
        $passwordExpire
        
        # Wait for 2 seconds 
        Start-Sleep -Seconds 2

        #$keyName
        #$password
        #$passwordtext

        #Convert password from secure string 
        $PlainPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
        )
        #Write Secret
        Write-Host -ForegroundColor Cyan "Your Secret is: $PlainPassword"
        

    #ask to view another vault
    $answer = Read-Host "Would you like to view another key?(Y/N)" 
    $answer = $answer.ToUpper()
    try{
          if($answer -eq "Y"){
        continue
        }
        elseif ($answer -eq "N"){
        break
        }
        else {
        Write-Host "Invalid input. Please enter 'Y' or 'N'."
        }
    }

    catch {
        Write-Host "an error occured: $_"   
    }


}

$ErrorActionPreference = "Continue" 

