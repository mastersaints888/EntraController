function New-EzBulkUser {
    [CmdletBinding()]
    param (
        [switch]$DryRun
    )


    Write-Host -ForeGroundColor Yellow "Attempting to open user creation csv, please wait..."

    Start-Process "$ENV:USERPROFILE\Documents\EntraController\Users\users.csv"

    #set confirmation for breaking the loop if Y is selected
$Confirmed = $false

#user prompt
    while (-not $Confirmed) {
       
        
        try {

            $P = Read-Host "Please build out your Bulk Users. When done, save the csv and exit. Type Y when finished (or type Q to quit)"

            switch ($P.ToUpper()) {
                "Y" {
                    Write-Host "Proceeding with script..." -ForegroundColor Green
                    $Confirmed = $true
                }
                "Q" {
                    Write-Host "Exiting script. Goodbye!" -ForegroundColor Yellow
                    return
                }
                default {
                    Write-Host "Invalid input. Please type 'Y' to continue or 'Q' to quit." -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "An error occurred: $_" -ForegroundColor Red
        }
    }


    # Import users from CSV
    $Users = Import-Csv -Path "$ENV:USERPROFILE\Documents\EntraController\Users\users.csv"

    foreach ($User in $Users) {


    $password           = $User.Password.Trim()
    $userPrincipalName  = $User.UserPrincipalName.Trim()
    $displayName        = $User.DisplayName.Trim()
    $firstName          = $User.FirstName.Trim()
    $lastName           = $User.LastName.Trim()
    $usageLocation      = $User.UsageLocation.Trim()
    $jobTitle           = $User.JobTitle.Trim()
    $companyName        = $User.CompanyName.Trim()
    $department         = $User.Department.Trim()
    $userType           = $User.UserType.Trim()
    $employeeType       = $User.EmployeeType.Trim()

    $mailNickNameBase   = ($firstName + $lastName).ToLower()
    $uniqueMailNickName = $mailNickNameBase
    $i = 1

    # Set account status based on the value in CSV
        switch ($User.AccountEnabled) {
            "TRUE"  { $accountEnabled = $true }
            "FALSE" { $accountEnabled = $false }
        }

    while (Get-MgUser -Filter "mailNickname eq '$uniqueMailNickName'" -ErrorAction SilentlyContinue) {
        $uniqueMailNickName = "$mailNickNameBase$i"
        $i++
    }

    $body = @{
        accountEnabled = $accountEnabled
        displayName    = $displayName
        mailNickname   = $uniqueMailNickName
        userPrincipalName = $userPrincipalName
        usageLocation  = $usageLocation
        givenName      = $firstName
        surname        = $lastName
        jobTitle       = $jobTitle
        companyName    = $companyName
        department     = $department
        userType       = $userType
        employeeType   = $employeeType
        passwordProfile = @{
            password = $password
            forceChangePasswordNextSignIn = $true
        }
    } | ConvertTo-Json -Depth 10

    try {
        $response = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users" -Body $body -ContentType "application/json"
        Write-Host -ForegroundColor Green "Created: $userPrincipalName"
    }
    catch {
        Write-Host -ForegroundColor Red "Error creating : $userPrincipalName $($_.Exception.Message)" $_
    }
}

}
