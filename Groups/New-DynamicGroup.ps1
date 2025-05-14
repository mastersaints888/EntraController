#Import-Module Microsoft.Graph.Groups
#Connect-MgGraph
#Import-Module Az.Accounts

# Define allowed properties
function New-EzDynamicGroup { 

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

#define and/or operators for the rules
$AndOrOperand = @(
    "or", "and", ""
)

#Set and or operator variable as global so it can be used outside of the func
$Global:AddExpression = $null

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
        # this is an invalid inpuut check while condition
        } while (-not $isValidNumber -or $parsed -lt 1 -or $parsed -gt $Options.Count)

# Return the selected option
return $Options[$parsed - 1]
}

function Get-UserAndOr {
    param (
        [string]$Prompt,
        [Parameter(Mandatory = $False)]
        [array]$Options
    )
    Write-Host "`n$Prompt"
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i+1). $($Options[$i])"
    }

    do {
        $selection = Read-Host "if you would like to add another querry, Enter Number OR type '3' to continue to group creation"
        # Create a ref variable to hold the parsed int
        [int]$parsed = 0
        $isValidNumber = [int]::TryParse($selection, [ref]$parsed)

        # this is an invalid inpuut check while condition
        } while (-not $isValidNumber -or $parsed -lt 1 -or $parsed -gt $Options.Count)

# Return the selected option
return $Options[$parsed - 1]

}


# Step 1: Get user input to build the rule

#Array to store possibly multiple dynamic querries 
$Array = @()

while ($true) {
    # Prompt user to build the rule
    $Answer = Read-Host "Add a Dynamic query? (Y/N)"
    $Answer = $Answer.ToUpper()

    try {
        if ($Answer -eq "Y") {
            # Prompt user for each part of the dynamic query
            $SelectedProperty  = Get-UserSelection -Prompt "Select a user property for dynamic rule:" -Options $ValidProperty
            $SelectedOperator  = Get-UserSelection -Prompt "Select an operator:" -Options $FilterOperators
            $Value             = Read-Host "Enter the value - if BOOLEANS do NOT use quotes, If STRING value use quotes!"
            $Global:AddExpression = Get-UserAndOr -Prompt "IMPORTANT: press type '3' to proceed to group creation. Press 1 or 2 to add additional Logic" -Options $AndOrOperand
            # As soon as input is collected, add it to the array
            $QueryLogic = [PSCustomObject]@{
                Property = $SelectedProperty
                Operator = $SelectedOperator
                Value    = $Value
                AdditionalLogic = $Global:AddExpression
            }

            # Add to the array
            $Array += $QueryLogic
            

            # Print current state of the array
            Write-Host "`nCurrent dynamic queries:"
            $Array | Format-Table -AutoSize
        }
        elseif ($Answer -eq "N") {
            break
        }
        else {
            Write-Host "Invalid operator, please choose Y/N"
        }
    }
    catch {
        Write-Host "An error occurred: $_.Exception.Message"
    }
}


#This will convert to json so we can work with the strings
$Array | ConvertTo-Json -Compress

#building out all objects into strings for passing into the command
$Rule = foreach($item in $Array){
    $line = "(user.$($item.Property) $($item.Operator) $($item.Value)) $($item.AdditionalLogic)"
    Write-Output $line
}


# Step 2: Build rule string
$Rule

Write-Host "`nGenerated Dynamic Membership Rule:" -ForegroundColor Cyan
Write-Host $Rule -ForegroundColor Green


# Step 3: Optional group creation
$DoCreate = Read-Host "Do you want to create a new group with this rule? (Y/N)"
$securityEnabled = $true  # Required for dynamic groups

try {
    if ($DoCreate.ToUpper() -eq "Y") {
    $DisplayName = Read-Host "Enter Display Name for the new group, No quotes needed"
     
    #Clean DisplayName: remove non-alphanumerics and compress spaces
    $baseNickname = ($DisplayName -replace '[^a-zA-Z0-9]', '') 
    $mailNickname = "$baseNickname$(Get-Random -Minimum 1000 -Maximum 9999)"

    $Group = New-MgGroup -DisplayName $DisplayName `
        -MailEnabled:$false `
        -MailNickname $mailNickname `
        -SecurityEnabled:$securityEnabled `
        -GroupTypes "DynamicMembership" `
        -MembershipRuleProcessingState "On" `
        -MembershipRule "$Rule" #"$Rule"
    $Group
    Write-Host "`n Group created successfully!" -ForegroundColor Green
    #$Group
} else {
    Write-Host "No group was created. You can use the rule elsewhere:" -ForegroundColor Yellow
}
}
catch {
    Write-Host $_.Exception.Message
}

}