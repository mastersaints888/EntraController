#Set Error action preference 
$ErrorActionPreference = "Stop" 


#region 1: dependency checks
#Connecting to your sub Module Dependency 
#Write-Host -ForegroundColor Green "Getting Az Subs..."
$AzSubs = Get-AzSubscription


#Check if user is connected 
try {
    #Check if Az Account is connected if its not connect the account
        If(-not $AzSubs){
            Connect-AzAccount -UseDeviceAuthentication
        }
     }
catch {
    Write-Host "An Error occured while attempting to connect your account $_"
}  

###------------------------------------------###
###check if user has proper installed modules###
###------------------------------------------### 
try {
    # Install and import the Microsoft Accounts module if it's not already installed
        if (-not (Get-Module -ListAvailable -Name Az.Accounts)) {
        Install-Module -Name Az.Accounts -Force
    }
        #import the module 
        Import-Module Az.Accounts
}
catch {
        Write-Host "An Error occured while attempting to install and import the module $_"
}   


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

#Store username and password in keyvault
try {
    Get-AzKeyVault -SubscriptionId $Subscription | Select-Object VaultName | Format-Table
    $KV = Read-Host "Please select a vault from your subscription:"
    Get-AzKeyVaultSecret -VaultName $KV | Format-Table 
}
catch {
    Write-Host "Role required: At least Key Vault Reader. Error: $_"
} 

#Ask if user would like to view a secret
# Ask if user would like to view a secret
while ($True) {
    $answer = Read-Host "Would you like to view a secret? (Y/N)"
    $answer = $answer.ToUpper()  # Convert to uppercase for case insensitivity

    try {
        if ($answer -eq "Y") {
            $Name = Read-Host "Please enter your Key Name from above to view its secret"
            # Grab encrypted secret value
            $SecurePassword = (Get-AzKeyVaultSecret -VaultName $KV -Name $Name).SecretValue
            # Decrypt the secret
            $DecryptedPassword = ConvertFrom-SecureString -AsPlainText $SecurePassword
            # Write plain text secret output
            Write-Host -ForegroundColor Cyan "Your Secret is: $DecryptedPassword"
            # Return to menu here when we get to that point
            break
        }
        elseif ($answer -eq "N") {
            Write-Host "Exiting script..."
            exit
        }
        else {
            Write-Host "Invalid input. Please enter 'Y' or 'N'."
        }
    }
    catch {
        Write-Host "Key Vault Secrets User RBAC Role or higher required to view $_"
    }
}



