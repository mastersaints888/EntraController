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
    Write-Host "Creating basic group..."
    # Add the logic for creating basic groups here
    # Example: New-AzureADGroup -DisplayName "GroupName" -MailEnabled $false -SecurityEnabled $true
    Read-Host "Press Enter to return to the menu"
}

Function Create-DynamicGroup {
    Write-Host "Creating dynamic group..."
    # Add the logic for creating dynamic groups here
    # Example: New-AzureADMSGroup -DisplayName "Dynamic Group" -GroupTypes @("DynamicMembership") -SecurityEnabled $true -MailEnabled $false
    # Optionally add license assignment logic if needed
    s
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
