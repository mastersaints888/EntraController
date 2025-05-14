function Get-UserCsv {
    Add-Type -AssemblyName System.Windows.Forms
    $FileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $FileDialog.InitialDirectory = [Environment]::GetFolderPath("MyDocuments")
    $FileDialog.Filter = "CSV files (*.csv)|*.csv|All files (*.*)|*.*"
    $FileDialog.Multiselect = $false

    if ($FileDialog.ShowDialog() -eq 'OK') {
        return $FileDialog.FileName
    } else {
        Write-Warning "User cancelled file selection."
        return $null
    }
}

#region Contact Info
function Get-EzContactInfoBulk {
    [CmdletBinding()]
    param (
        [switch]$ExportToCsv,
        [string]$ExportPath = "$env:USERPROFILE\Documents\EzContactInfo.csv"
    )

    Import-Module -Name Microsoft.Entra -ErrorAction Stop
    Connect-Entra
    Connect-MgGraph -UseDeviceAuthentication

    function Get-EzContactInfoDetails {
        param (
            [string]$User
        )

        $ContactInfoAttributes = @(
            "streetAddress", "city", "state", "postalCode", "country",
            "businessPhones", "mobilePhone", "mail", "otherMails",
            "proxyAddresses", "faxNumber", "imAddresses", "mailNickname"
        )

        foreach ($Prop in $ContactInfoAttributes) {
            $Value = $null
            try {
                $Result = Get-EntraUser -UserId $User -Property $Prop
                $Value = $Result.$Prop
            }
            catch {
                Write-Host -ForegroundColor Yellow "Failed to retrieve $Prop for $User, $Prop may not be applied"
                $Value = "N/A"
            }

            if (-not $Value) {
                $Value = "N/A"
            }

            [PSCustomObject]@{
                User      = $User
                Attribute = $Prop
                Value     = ($Value -join ', ')
            }
        }
    }

    # Prompt for CSV
    $CsvPath = Get-UserCsv
    if (-not $CsvPath){ return }

    $CsvData = Import-Csv -Path $CsvPath

    $AllResults = foreach ($User in $CsvData.userPrincipalName) {
        Get-EzContactInfoDetails -User $User
    }


    # command switch for exporting to csv
    if ($ExportToCsv) {
        try {
            $AllResults | Export-Csv -Path $ExportPath -NoTypeInformation -Force
            Write-Host "Exported to $ExportPath" -ForegroundColor Green
        }
        catch {
            Write-Warning "Failed to export to CSV: $_"
        }
    }

    return $AllResults
}

#endregion














#region Idnetity Attribute
function Get-EzIdentityAttributeBulk {

    [CmdletBinding()]
    param (
        [switch]$ExportToCsv,
        [string]$ExportPath = "$env:USERPROFILE\Documents\EzContactInfo.csv"
    )

    Import-Module -Name Microsoft.Entra -ErrorAction Stop
    Connect-Entra
    Connect-MgGraph -UseDeviceAuthentication 


#func that provides each users attributes
function Get-EzIdentityAttributeDetails {

Param (
    [string]$User
)

$IdentityAttributeValues = @(
    "assignedLicenses",                     # Assigned licenses
    "displayName",                          # Display name
    "givenName",                            # First name
    "surname",                              # Last name
    "userPrincipalName",                    # User principal name
    "id",                                   # Object ID
    "identities",                           # Identities
    "userType",                             # User type
    "creationType",                         # Creation type
    "createdDateTime",                      # Created date time
    "lastPasswordChangeDateTime",           # Last password change date time
    "externalUserState",                    # Invitation state (closest match)
    "externalUserStateChangeDateTime",      # External user state change date time
    "passwordPolicies",                     # Password policies
    "passwordProfile",                      # Password profile
    "preferredLanguage",                    # Preferred language
    "signInSessionsValidFromDateTime",      # Sign in sessions valid from date time
    "authorizationInfo"                     # Authorization info
)

#Loop through each attribute and expand 
foreach($Prop in $IdentityAttributeValues){
    
    try {

    #This is the value of the Property at the current iteration of the loop
    $Values = Get-EntraUser -UserId $User -Property $Prop | Select-Object -ExpandProperty $Prop

    #Check for Null and Write NA if Values are Null
    if($null -eq $Values){
        #Set Identity attribute to Null Value 
            [PSCustomObject]@{
            userPrincipalName = $User    
            Property = $Prop
            Value = "N/A"
            }
        }

        #Store the key value pairs in a hashtable for rich output
        foreach($Value in $Values){

            #assigned License check need to expand more 
            if($Prop -eq "assignedLicenses"){
                [PSCustomObject]@{
                    userPrincipalName = $User    
                    Property = $Prop
                    Value = $Value
                    }
            }
            else{
            #Store key value pairs 
            [PSCustomObject]@{
            userPrincipalName = $User
            Property = $Prop
            Value = $Value
            }
        }
    }
    }
    catch{
        Write-Host -ForegroundColor Yellow "An error has occured for $User"
    }
    #Store of values  
    
}

} 

# Prompt for CSV
$CsvPath = Get-UserCsv
if (-not $CsvPath){ return }

$CsvData = Import-Csv -Path $CsvPath

$AllResults = @()

foreach ($User in $CsvData.userPrincipalName) {
    $AllResults += Get-EzIdentityAttributeDetails -User $User
}

#Export to csv Command switch
if ($ExportToCsv) {
    try {
        $AllResults | Export-Csv -Path $ExportPath -NoTypeInformation -Force
        Write-Host "Exported to $ExportPath" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to export to CSV: $_"
    }
}


return $AllResults

}



#endregion