function Get-ValidInput {
    param (
        [string]$Prompt,            # The prompt for the user
        [array]$ValidValues,        # Array of valid values
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
            # Check if the input is in the valid set, respecting case
            if ($ValidValues -contains $input) {
                return $input
            } else {
                Write-Host "Invalid input. Please enter one of the valid values: $($ValidValues -join ', ')"
            }
        }
        else {
            # Case-insensitive check
            if ($ValidValues -contains $input.ToUpper()) {
                return $input.ToUpper()
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
    $ResourceGroup = ".$ResourceGroup"
}

if ($Resource) {
    $Resource = ".$Resource"
}

# Combine variables for the group name
$Delimiter = ":"
$DisplayName = "$GroupType$AssignmentType-$Context$Delimiter$Subscription$ResourceGroup$Resource$Delimiter$Role"

try {
    New-EntraGroup -DisplayName "$DisplayName" `
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

# Example output
Write-Host "Group Created successfully in Entra: $DisplayName"
