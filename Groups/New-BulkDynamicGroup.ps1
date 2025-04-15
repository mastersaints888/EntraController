Connect-MgGraph
#import users config
$DGs = Import-Csv -Path "C:\Users\$env:USERNAME\Documents\EntraController\Groups\DynamicGroupDb.csv"


#'(user.accountEnabled -eq true) and (user.companyName -eq "ContractorTest")'

foreach ($group in $DGs) {
    try {
        # Cast string values to boolean
        $mailEnabled = [System.Convert]::ToBoolean($group.MailEnabled)
        $securityEnabled = $true  # Required for dynamic groups
        $mailNickname = ($group.DisplayName -replace '\s+', '') + (Get-Random -Minimum 1000 -Maximum 9999)

        $newGroup = New-MgGroup -DisplayName $group.DisplayName `
            -MailEnabled:$mailEnabled `
            -MailNickname $mailNickname `
            -SecurityEnabled:$securityEnabled `
            -GroupTypes @("DynamicMembership") `
            -MembershipRuleProcessingState "On" `
            -MembershipRule $group.GroupQuery

            $newGroup

        Write-Host "Created group: $($group.DisplayName)" -ForegroundColor Green
    }
    catch {
        Write-Host "Error creating group '$($group.DisplayName)': $_" -ForegroundColor Red
    }
}


