function Get-EzOnPremExtAttribute {

# Ask user for the UPN
$UserUPN = Read-Host "Please enter the UPN of the user in question to show its on prem stored attributes in Entra"

# List of Entra Identity attributes to fetch
$OnPremExtAttributes = @(
    "onPremisesExtensionAttributes"
)


# Initialize output array
$ArrayOnPremExtAttributes = @()

# Loop through each attribute
foreach ($Prop in $OnPremExtAttributes) {
    
    #Grab on prem extension attributes
    try {
        
        $Values = Get-EntraUser -UserId $UserUPN -Property $Prop | Select-Object -ExpandProperty $Prop

    }
    catch {
        Write-Host -ForegroundColor Yellow "Failed to retrieve $Prop for $UserUPN, $Prop may not be applied"
        $Value = "N/A"
    }

        foreach($Value in $Values){

              $ExtensionAttributes = [PSCustomObject]@{
                $Prop = $Value
              }
        }

    $ArrayOnPremExtAttributes += $ExtensionAttributes   
}

#Formatting for pretty output
foreach($Attribute in $Values){
    $ArrayOnPremExtAttributes += [PSCustomObject]@{
    extensionAttribute1  = $Value.extensionAttribute1
    extensionAttribute2  = $Value.extensionAttribute2
    extensionAttribute3  = $Value.extensionAttribute3
    extensionAttribute4  = $Value.extensionAttribute4
    extensionAttribute5  = $Value.extensionAttribute5
    extensionAttribute6  = $Value.extensionAttribute6
    extensionAttribute7  = $Value.extensionAttribute7
    extensionAttribute8  = $Value.extensionAttribute8
    extensionAttribute9  = $Value.extensionAttribute9
    extensionAttribute10 = $Value.extensionAttribute10
    extensionAttribute11 = $Value.extensionAttribute11
    extensionAttribute12 = $Value.extensionAttribute12
    extensionAttribute13 = $Value.extensionAttribute13
    extensionAttribute14 = $Value.extensionAttribute14
    extensionAttribute15 = $Value.extensionAttribute15
    }

}

$ArrayOnPremExtAttributes | Format-List

}