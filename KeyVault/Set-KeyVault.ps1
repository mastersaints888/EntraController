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

#Store username and password in keyvault
Get-AzKeyVault -SubscriptionId $Subscription | Select-Object VaultName | Format-Table
$KV = Read-Host "Please select a vault from your subscription"
Write-Host "Please put aruguments where Name is the Key Name and Password is the keys Secret"


$cred = Get-Credential 
$Name = $cred.UserName

###Expiration Date Logic###
$ExDate = Read-Host "If you would like to set an expiration date please do it here (MM-DD-YYYY)"

try {
    if($ExDate){
        #Parse the expiration date
        $ExDateParsed = [DateTime]::ParseExact($ExDate, "MM-dd-yyyy", [System.Globalization.CultureInfo]::InvariantCulture)

        #Convert to UTC (Set-AzKeyVaultSecret requires UTC)
        $ExDateParsedUtc = $ExDateParsed.ToUniversalTime()

        #Set the expiration date for the Key Vault secret
        Set-AzKeyVaultSecret -VaultName $KV -Name $Name -SecretValue $cred.Password -Expires $ExDateParsedUtc
    }  
    else {
        #If no expiration date provided, just set the secret
        Set-AzKeyVaultSecret -VaultName $KV -Name $Name -SecretValue $cred.Password
    }
}
catch {
    Write-Host "An error has occurred: $_"
}

#endregion 

# $secretuser = ConvertTo-SecureString $cred.Password -AsPlainText -Force #have to make a secure string
# Set-AzKeyVaultSecret -VaultName 'PS-masterclass-vault' -Name $Name -SecretValue $secretuser



$username = (get-azkeyvaultsecret -vaultName $KV -Name $Name)
$password = (get-azkeyvaultsecret -vaultName $KV -Name $Name).SecretValue
$passwordtext = (get-azkeyvaultsecret -vaultName $KV -Name $Name).Expires
$username
$password
$passwordtext

#Convert password from secure string 
$DecryptedPassword = ConvertFrom-SecureString -AsPlainText $password
Write-Host -ForegroundColor Cyan "Youre Secret is: $DecryptedPassword"

$ErrorActionPreference = "Continue" 
