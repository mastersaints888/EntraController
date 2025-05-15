


function Get-EzContactInfo {
# Ask user for the UPN
$UserUPN = Read-Host "Please enter the UPN of the user in question to show its Entra Identity-based attributes"

# List of Entra Identity attributes to fetch
$ContactInfoAttributes = @(
    "streetAddress",
    "city",
    "state",
    "postalCode",
    "country",
    "businessPhones",
    "mobilePhone",
    "mail",
    "otherMails",
    "proxyAddresses",
    "faxNumber",
    "imAddresses",
    "mailNickname"
)

# Initialize output array
$ArrayConactInfo = @()

# Loop through each attribute
foreach ($Prop in $ContactInfoAttributes) {
    $Value = $null

    try {
        switch ($Prop) {
            default {
                $Result = Get-MgUser -UserId $UserUPN -Property $Prop
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
    $ArrayConactInfo += [PSCustomObject]@{
        Attribute = $Prop
        Value     = ($Value -join ', ')
    }
}

# Show output
$ArrayConactInfo | Format-Table -AutoSize

}


