function Get-ValidInput {
    param (
        [string]$Prompt,            # The prompt for the user
        [array] $ValidValues,        # Array of valid values
        [switch]$Mandatory,         # Whether the input is mandatory
        [switch]$CaseSensitive,      # Whether the validation should be case-sensitive
        [switch]$NotMandatory       # Non Manditory Flag
    )

    do {
        # Prompt the user for input
        $input = Read-Host $Prompt

        # For non-mandatory fields, we exit the loop if the input is empty
        if ($NotMandatory -and [string]::IsNullOrWhiteSpace($input)) {
            return $null  # Optional fields can return null if left blank
        }

        # Handle mandatory field validation
        if ($Mandatory -and [string]::IsNullOrWhiteSpace($input)) {
            Write-Host "This field is mandatory. Please enter a value."
            continue
        }

        # Case-sensitive validation
        if ($CaseSensitive) {
            # Directly compare the input with the valid set (case-sensitive comparison)
            if ($ValidValues -ccontains $input) {
                return $input
            } 
            else {
                Write-Host "Invalid input. Please enter one of the valid values: $($ValidValues -join ', ')"
            }
        }
        else {
            # Case-insensitive check
            $validMatch = $ValidValues | Where-Object { $_.ToLower() -eq $input.ToLower() }
            if ($validMatch) {
                return $validMatch
            } else {
                Write-Host "Invalid input. Please enter one of the valid values: $($ValidValues -join ', ')"
            }
        }

    } while ($true)
}

# Define valid values
$validGroupTypes = @("UG", "AR", "PR")
$validAssignmentTypes = @("s", "d", "f")
$validContexts = @("Azure", "SharePoint", "SQL", "Teams", "ADO", "Entra", "RedGate", "KeyVault")

# Example usage of Get-ValidInput function
$GroupType = Get-ValidInput -Prompt "Please enter a Group Type (Valid options: UG, AR, PR)" -ValidValues $validGroupTypes -Mandatory $true -CaseSensitive $true
$AssignmentType = Get-ValidInput -Prompt "Please enter an Assignment Type (Valid options: s, d, f)" -ValidValues $validAssignmentTypes -Mandatory $true -CaseSensitive $true
$Context = Get-ValidInput -Prompt "Please enter a Context (Valid options: Azure, SharePoint, SQL, Teams, ADO, Entra, RedGate, KeyVault)" -ValidValues $validContexts -Mandatory $true -CaseSensitive $true

# Resource Group and Resource (optional)
$ResourceGroup = Get-ValidInput -Prompt "Please enter a Resource Group (Leave blank if not required)"  -NotMandatory $true -CaseSensitive $false
$Resource = Get-ValidInput -Prompt "Please enter a Resource (Leave blank if not required)" -NotMandatory $true -CaseSensitive $false

# Subscription and Role (mandatory checks)
do {
    $Subscription = Read-Host "Please enter a Subscription (Mandatory)"
    if ([string]::IsNullOrWhiteSpace($Subscription)) {
        Write-Host "Subscription is mandatory. Please enter a value."
    }
} while ([string]::IsNullOrWhiteSpace($Subscription))

do {
    $Role = Read-Host "Please enter a Role (Mandatory)"
    if ([string]::IsNullOrWhiteSpace($Role)) {
        Write-Host "Role is mandatory. Please enter a value."
    }
} while ([string]::IsNullOrWhiteSpace($Role))

# Optional processing
if ($ResourceGroup) {
    $ResourceGroup = "$ResourceGroup"
}

if ($Resource) {
    $Resource = "$Resource"
}

    ############                             ############
    ############ Defining Group Descriptions ############
    ############                             ############

    #Set the the description variable for GroupType User 
    if ($GroupType -eq "UG"){
        $DescGT = "GroupType: User Group | "
    }

    #Set the the description variable for GroupType Application ROle 
    if ($GroupType -eq "AR"){
        $DescGT = "GroupType: Application Role | "
    }
   
   
    #Set the the description variable for GroupType PimRole
    if ($GroupType -eq "PR"){
        $DescGT = "GroupType: Pim Role | "
    }


    #Set the the description variable for Assignment Type if static
    if ($AssignmentType -eq "s"){
        $DescAssType = "Assignment Type: Static | "
    }

    #Set the the description variable for Assignment Type if dynamic
    if ($AssignmentType -eq "d"){
        $DescAssType = "Assignment Type: Dynamic | "
    }

    #Set the the description variable for Assignment Type if Function
    if ($AssignmentType -eq "f"){
        $DescAssType = "Assignment Type: Function | "
    }

    #Set the the description variable for Context
    if ($Context){
        $DescContext = "Context: $Context | "
    }

    #Set the the description variable for Sub
    if ($Subscription){
        $DescSub = "Subscription: $Subscription | "
    }

    #iF resourcegroup provided add the dot delimiter here and set the description variable for it 
    if ($ResourceGroup){
        $DescRG = "ResourceGroup: $ResourceGroup | " 
    }

    #If resource provided add the dot delimiter here and set the description variable for it 
    if ($Resource){
        $DescR = " $Resource | "
    }

    #Set role description 
    if ($Role){
        $DescRole = "Role: $Role"
    }



# Combine variables for the group name
$Delimiter = ":"
$DisplayName = "$GroupType$AssignmentType-$Context$Delimiter$Subscription.$ResourceGroup.$Resource$Delimiter$Role"
$Description = "$DescGT$DescAssType$DescContext$DescSub$DescRG$DescR$DescRole"

try {
    $NewGroup = New-EntraGroup -DisplayName "$DisplayName" `
    -SecurityEnabled $true `
    -Description $Description `
    -MailEnabled $false -MailNickname NotSet -IsAssignableToRole $false
    $NewGroup
}
catch {
    Write-Host "The Group failed to create see error: $_"
}

if ($null -ne $NewGroup){
     Write-Host -ForegroundColor Yellow "Creating group... Sit tight!" 
     Write-Host -ForegroundColor Green "Group Created successfully in Entra: $DisplayName"
}