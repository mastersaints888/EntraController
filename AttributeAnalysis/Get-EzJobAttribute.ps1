function Get-EzJobAttribute {
# Ask user for the UPN
$UserUPN = Read-Host "Please enter the UPN of the user in question to show its Mg Identity-based attributes"

# List of Mg Identity attributes to fetch
$JobInfoAttributeValues = @(
    "sponsors",
    "manager",
    "jobTitle",
    "companyName",
    "department",
    "employeeId",
    "employeeType",
    "employeeHireDate",
    "employeeOrgData",
    "officeLocation"
)

# Initialize output array
$ArrayJobAttributes = @()

# Loop through each attribute
foreach ($Prop in $JobInfoAttributeValues) {
    $Value = $null

    try {
        switch ($Prop) {
            "sponsors" {
                try{
                    $Sponsor = Get-MgUserSponsor -UserId $UserUPN -ErrorAction Stop
                    if ($Sponsor) {
                        $SponsorDetails = Get-MgUser -UserId $Sponsor.ID
                        $Value = @($SponsorDetails.DisplayName, $SponsorDetails.UserPrincipalName, $SponsorDetails.Id)
                    }
                }
                catch{
                    Write-Host -ForegroundColor Yellow "Failed to retrieve $Prop for $UserUPN : "
                    Write-Host -ForegroundColor Red $_.Exception
                }
            }
            "manager" {
                
                try {
                    $Manager = Get-MgUserManager -UserId $UserUPN -ErrorAction Stop
                    if ($Manager) {
                    $ManagerDetails = Get-MgUser -UserId $Manager.ID
                    $Value = @($ManagerDetails.DisplayName, $ManagerDetails.UserPrincipalName, $ManagerDetails.Id)
                }
                }
                catch {
                    Write-Host -ForegroundColor Yellow "Failed to retrieve $Prop for $UserUPN : "
                    Write-Host -ForegroundColor Red $_.Exception
                }
                
            }
            default {
                try {
                    $Result = Get-MgUser -UserId $UserUPN -Property $Prop -ErrorAction Stop
                    $Value = $Result.$Prop
                }
                catch {
                    Write-Host -ForegroundColor Yellow "Failed to retrieve $Prop for $UserUPN : "
                    Write-Host -ForegroundColor Red $_.Exception
                }
                
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
    $ArrayJobAttributes += [PSCustomObject]@{
        Attribute = $Prop
        Value     = ($Value -join ', ')
    }
}

# Show output
$ArrayJobAttributes | Format-Table -AutoSize

}