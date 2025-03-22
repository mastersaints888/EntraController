# Entra Controller Launcher Script
Clear-Host

Function Show-Menu {
    cls
    Write-Host "Select an option:"
    Write-Host "1) Create users"
    Write-Host "2) Create basic group"
    Write-Host "3) Create dynamic group (option to add license)"
    Write-Host "4) Create app registration and add users"
    Write-Host "5) Exit"
}

Function Create-Users {
    Write-Host "Creating users..."
    # Add the user creation logic here
    # Example: New-AzureADUser -DisplayName "John Doe" -UserPrincipalName "john.doe@domain.com" -AccountEnabled $true
    Read-Host "Press Enter to return to the menu"
}

Function Create-BasicGroup {
    # Basic Security Group Parameters 
    [CmdletBinding()]
    param (
        # Group type parameter 
        [Parameter(Mandatory=$true, HelpMessage="Please Enter in a Valid GroupType case sensitive. Valid GroupTypes: UG, AR, PR")]
        [ValidateSet('UG','AR','PR', IgnoreCase=$false)]
        [String]
        $GroupType,

        # Assignment type is static, dynamic or function
        [Parameter(Mandatory=$true, HelpMessage="Please Enter in a Valid GroupType case sensitive. Valid GroupTypes: UG, AR, PR")]
        [ValidateSet('s','d','f', IgnoreCase=$false)]
        [string]
        $AssignmentType,
        
        # Group Context here ie: Azure, Entra, keyvault etc
        [Parameter(Mandatory=$True)]
        [ValidateSet('Azure', 'SharePoint', 'SQL', 'Teams', 'ADO', 'Entra', 'RedGate', 'KeyVault')]
        [String]
        $Context,

        #Resource Scope Subscription
        [Parameter(Mandatory=$True)]
        [String]
        $Subscription,
        
        #Resource scope rg
        [Parameter(Mandatory=$false)]
        [string]
        $ResourceGroup,

        #Resource (mostly shouldnt use this)
        [Parameter(Mandatory=$false)]
        [string]
        $Resource,

        #Role
        [Parameter(Mandatory=$true)]
        [String]
        $Role
    )


    # If ResourceGroup is not provided, prompt user for input
    if (-not $ResourceGroup) {
        $ResourceGroup = Read-Host "Please enter the ResourceGroup (Leave blank if not required)"
    }

    # If Resource is not provided, prompt user for input
    if (-not $Resource) {
        $Resource = Read-Host "Please enter the Resource (Leave blank if not required)"
    }

    # Now process the rest of the parameters as normal
    Write-Host "Group Type: $GroupType"
    Write-Host "Assignment Type: $AssignmentType"
    Write-Host "Context: $Context"
    Write-Host "Subscription: $Subscription"
    Write-Host "Role: $Role"

    # If ResourceGroup and Resource are provided, handle them here
    if ($ResourceGroup) {
        Write-Host "Resource Group: $ResourceGroup"
    }
    if ($Resource) {
        Write-Host "Resource: $Resource"
    }
    else {
        Write-Host "No Resource provided."
    }

    #iF resourcegroup provided add the dot delimiter here
    if ($ResourceGroup){
        $ResourceGroup = ".$ResourceGroup"
    }

    #If resource provided add the dot delimiter here
    if ($Resource){
        $Resource = ".$Resource"
    }

    # Script to run 
    $Delimiter = ":"
    try {
        New-EntraGroup -DisplayName "$GroupType$AssignmentType-$Context$Delimiter$Subscription$ResourceGroup$Resource$Delimiter$Role" `
        -SecurityEnabled $true `
        -Description 'tbd' `
        -MailEnabled $false -MailNickname NotSet -IsAssignableToRole $false
    }
    catch {
        Write-Host $_
    }
    # New-EntraGroup -DisplayName ARs-Azure:sub-SHC-Hub_Management.rg-SHC-Dev-Hub:Reader 
    # -SecurityEnabled $true -Description 'Group Type: AR | Assignment Type: s | Context: Azure | Ressource scope: sub-SHC-Hub:Management.rg-SHC-Dev-Hub | Role: Reader' 
    # -MailEnabled $false -MailNickname NotSet -IsAssignableToRole $false
}


    Write-Host "Creating basic group..."
    # Add the logic for creating basic groups here
    # Example: New-AzureADGroup -DisplayName "GroupName" -MailEnabled $false -SecurityEnabled $true
    Read-Host "Press Enter to return to the menu"


Function Create-DynamicGroup {
    Write-Host "Creating dynamic group..."
    # Add the logic for creating dynamic groups here
    # Example: New-AzureADMSGroup -DisplayName "Dynamic Group" -GroupTypes @("DynamicMembership") -SecurityEnabled $true -MailEnabled $false
    # Optionally add license assignment logic if needed
    Read-Host "Press Enter to return to the menu"
}

Function Create-AppRegistrationAndAddUsers {
    Write-Host "Creating App Registration and adding users..."
    # Add the logic for creating an app registration and adding users here
    # Example: New-AzureADApplication -DisplayName "AppName"
    Read-Host "Press Enter to return to the menu"
}

# Main loop
do {
    Show-Menu
    $userChoice = Read-Host "Enter your choice"

    switch ($userChoice) {
        "1" { Create-Users }
        "2" { Create-BasicGroup }
        "3" { Create-DynamicGroup }
        "4" { Create-AppRegistrationAndAddUsers }
        "5" { Write-Host "Exiting..."; break }
        default { Write-Host "Invalid selection. Please try again." }
    }
} while ($true)





