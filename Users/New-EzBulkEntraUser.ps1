function New-EzBulkUser {
    [CmdletBinding()]
    param (
        [switch]$DryRun
    )

    # Import users from CSV
    $Users = Import-Csv -Path "$ENV:USERPROFILE\Documents\EntraController\Users\users.csv"

    foreach ($User in $Users) {
        
        # Set account status based on the value in CSV
        $accountEnabled = $false
        switch ($User.AccountEnabled) {
            "TRUE"  { $accountEnabled = $true }
            "FALSE" { $accountEnabled = $false }
        }

        try {
            # Generate unique mail nickname
            $mailNickNameBase = ($User.FirstName + $User.LastName).ToLower()
            $uniqueMailNickName = $mailNickNameBase
            $i = 1

            # Check for existing users with the same mailNickname
            while (Get-MgUser -Filter "mailNickname eq '$uniqueMailNickName'" -ErrorAction SilentlyContinue) {
                $uniqueMailNickName = "$mailNickNameBase$i"
                $i++
            }

            # If DryRun, show the user creation details without making changes
            if ($DryRun) {
                Write-Host -ForegroundColor Yellow "[DryRun] Would create user:" $User.UserPrincipalName
            } else {
                # Prepare user creation body
                $body = @{
                    accountEnabled        = $accountEnabled
                    displayName           = $User.DisplayName
                    mailNickname          = $uniqueMailNickName
                    userPrincipalName     = $User.UserPrincipalName
                    usageLocation         = $User.UsageLocation
                    givenName             = $User.FirstName
                    surname               = $User.LastName
                    jobTitle              = $User.JobTitle
                    companyName           = $User.CompanyName
                    department            = $User.Department
                    userType              = $User.UserType
                    employeeType          = $User.EmployeeType
                    passwordProfile       = @{
                        password                        = $User.Password.Trim()
                        forceChangePasswordNextSignIn   = $true
                    }
                } | ConvertTo-Json -Depth 10

                # Make the API call to create the user
                try {
                    $response = Invoke-MgGraphRequest -Method POST -Uri "https://graph.microsoft.com/v1.0/users" -Body $body -ContentType "application/json"
                    Write-Host -ForegroundColor Green "Created: $($User.UserPrincipalName)"
                } catch {
                    Write-Host -ForegroundColor Red "Error creating $($User.UserPrincipalName): $($_.Exception.Message)"
                }
            }
        } catch {
            Write-Host -ForegroundColor Red "Error processing $($User.UserPrincipalName): $($_.Exception.Message)"
        }
    }
}
