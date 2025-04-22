Connect-MgGraph -UseDeviceAuthentication

# Ask user for the UPN
$UserUPN = Read-Host "Please enter the UPN of the user in question to show its on prem stored attributes in Entra"

# List of Entra Identity attributes to fetch
$OnPremAttributeValues = @(
    "onPremisesSyncEnabled",
    "onPremisesLastSyncDateTime",
    "onPremisesDistinguishedName",
    "onPremisesImmutableId",
    "onPremisesProvisioningErrors",
    "onPremisesSamAccountName",
    "onPremisesSecurityIdentifier",
    "onPremisesUserPrincipalName",
    "onPremisesDomainName"
)


# Initialize output array
$ArrayOnPremAttributes = @()

# Loop through each attribute
foreach ($Prop in $OnPremAttributeValues) {
    $Value = $null

    try {
        switch ($Prop) {
            default {
                $Result = Get-EntraUser -UserId $UserUPN -Property $Prop
                $Value = $Result.$Prop
            }
        }
    }
    catch {
        Write-Host -ForegroundColor Yellow "Failed to retrieve $Prop for $UserUPN, $Prop may not be applied"
        $Value = "N/A"
    }

    # Normalize value (if still null or empty)
    if (-not $Value) {
        $Value = "N/A"
    }

    # Add object to array
    $ArrayOnPremAttributes += [PSCustomObject]@{
        Attribute = $Prop
        Value     = ($Value -join ', ')
    }
}

# Show output
$ArrayOnPremAttributes | Format-Table -AutoSize
