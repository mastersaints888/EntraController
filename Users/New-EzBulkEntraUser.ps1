function New-EzBulkUser {
    [CmdletBinding()]
    param(
        [switch]$DryRun
    )

    $Users = Import-Csv -Path "$ENV:USERPROFILE\Documents\EntraController\Users\users.csv"

    foreach ($User in $Users) {
        switch ($User.AccountEnabled) {
            "TRUE" { $accountEnabled = $true }
            "FALSE" { $accountEnabled = $false }
        }

        try {
            $PasswordProfile = [Microsoft.Graph.PowerShell.Models.MicrosoftGraphPasswordProfile]::new()
            $PasswordProfile.ForceChangePasswordNextSignIn = $true
            $PasswordProfile.Password = $User.Password

            $mailNickNameBase = ($User.FirstName + $User.LastName).ToLower()
            $uniqueMailNickName = $mailNickNameBase
            $i = 1

            while (Get-MgUser -Filter "mailNickname eq '$uniqueMailNickName'" -ErrorAction SilentlyContinue) {
                $uniqueMailNickName = "$mailNickNameBase$i"
                $i++
            }

            if ($DryRun) {
                Write-Host -ForegroundColor Yellow "[DryRun] Would create user:" $User.UserPrincipalName
            } else {
                Write-Host -ForegroundColor Green "Creating user..." $User.DisplayName

                New-MgUser -UserPrincipalName $User.UserPrincipalName `
                           -DisplayName $User.DisplayName `
                           -PasswordProfile $PasswordProfile `
                           -AccountEnabled:$accountEnabled `
                           -MailNickName $uniqueMailNickName `
                           -GivenName $User.FirstName `
                           -Surname $User.LastName `
                           -JobTitle $User.JobTitle `
                           -CompanyName $User.CompanyName `
                           -Department $User.Department `
                           -UserType $User.UserType `
                           -EmployeeType $User.EmployeeType `
                           -UsageLocation $User.UsageLocation
            }
        }
        catch {
            Write-Host "Error Creating User:" $_.Exception.Message
        }
    }
}
