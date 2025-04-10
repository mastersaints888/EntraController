Import-Module Microsoft.Graph.Groups
Connect-MgGraph
Import-Module Az.Accounts

# Define allowed properties
$ValidProperty = @(
    "accountEnabled","dirSyncEnabled","city", "country", "companyName", "department", "displayName",
    "employeeId", "facsimileTelephoneNumber", "givenName", "jobTitle",
    "mail", "mailNickName", "memberOf", "mobile", "objectId",
    "onPremisesDistinguishedName", "onPremisesSecurityIdentifier", "passwordPolicies",
    "physicalDeliveryOfficeName", "postalCode", "preferredLanguage",
    "sipProxyAddress", "state", "streetAddress", "surname",
    "telephoneNumber", "usageLocation", "userPrincipalName", "userType","employeeHireDate"
)

# Define allowed operators
$FilterOperators = @(
    "-endsWith", "-notEndsWith", "-ne", "-eq",
    "-notStartsWith", "-startsWith", "-notContains", "-contains",
    "-notMatch", "-match", "-in", "-notIn"
)

function Get-UserSelection {
    param (
        [string]$Prompt,
        [array]$Options
    )
    Write-Host "`n$Prompt"
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i+1). $($Options[$i])"
    }

    do {
        $selection = Read-Host "Enter the number of your choice"
        # Create a ref variable to hold the parsed int
        [int]$parsed = 0
        $isValidNumber = [int]::TryParse($selection, [ref]$parsed)
        } while (-not $isValidNumber -or $parsed -lt 1 -or $parsed -gt $Options.Count)

# Return the selected option
return $Options[$parsed - 1]
}

# Step 1: Get user input to build the rule
$SelectedProperty = Get-UserSelection -Prompt "Select a user property for dynamic rule:" -Options $ValidProperty
$SelectedOperator = Get-UserSelection -Prompt "Select an operator:" -Options $FilterOperators
$Value = Read-Host "Enter the value to compare (use null for null checks, or surround string with quotes if needed)"

# Step 2: Build rule string
$Rule = "(user.$SelectedProperty $SelectedOperator $Value)"
Write-Host "`nGenerated Dynamic Membership Rule:" -ForegroundColor Cyan
Write-Host $Rule -ForegroundColor Green

# Step 3: Optional group creation
$DoCreate = Read-Host "Do you want to create a new group with this rule? (Y/N)"
if ($DoCreate.ToUpper() -eq "Y") {
    $DisplayName = Read-Host "Enter Display Name for the new group"
    $MailNickname = ($DisplayName -replace '\s+', '') + (Get-Random -Minimum 1000 -Maximum 9999)

    $Group = New-MgGroup -DisplayName $DisplayName `
        -MailEnabled:$false `
        -MailNickname $MailNickname `
        -SecurityEnabled `
        -GroupTypes "DynamicMembership" `
        -MembershipRuleProcessingState "On" `
        -MembershipRule $Rule

    Write-Host "`n✅ Group created successfully!" -ForegroundColor Green
    #$Group
} else {
    Write-Host "No group was created. You can use the rule elsewhere:" -ForegroundColor Yellow
}
