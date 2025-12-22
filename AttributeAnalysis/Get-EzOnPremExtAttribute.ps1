function Get-EzOnPremExtAttribute {

param (

    [switch]$ActionType,
    [string]$UserUPN

)

#for single user attribute retrieval
switch($ActionType){

        $true { 
        
            # Ask user for the UPN
            $UserUPN = Read-Host "Please enter the UPN of the user in question to show its on prem stored attributes in Entra"
        
        }
        "default" {
        
            continue
        
        }

}
# Ask user for the UPN
#$UserUPN = Read-Host "Please enter the UPN of the user in question to show its on prem stored attributes in Entra"

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
        
        $Values = Get-MgUser -UserId $UserUPN -Property $Prop -ErrorAction Stop | Select-Object -ExpandProperty $Prop

    }
    catch {
        Write-Host -ForegroundColor Yellow "Failed to retrieve $Prop for $UserUPN : "
        Write-Host -ForegroundColor Red $_.Exception
        $Value = "N/A"
    }

        foreach($Value in $Values){

              $ExtensionAttributes = [PSCustomObject]@{
                $Prop = $Value
              }
        }

    $ArrayOnPremExtAttributes += $ExtensionAttributes   
}

$OutputOnPremAttributes = @()

#Formatting for pretty output
foreach($Attribute in $Values){
    $OutputOnPremAttributes += [PSCustomObject]@{
    extensionAttribute1  = $Attribute.extensionAttribute1
    extensionAttribute2  = $Attribute.extensionAttribute2
    extensionAttribute3  = $Attribute.extensionAttribute3
    extensionAttribute4  = $Attribute.extensionAttribute4
    extensionAttribute5  = $Attribute.extensionAttribute5
    extensionAttribute6  = $Attribute.extensionAttribute6
    extensionAttribute7  = $Attribute.extensionAttribute7
    extensionAttribute8  = $Attribute.extensionAttribute8
    extensionAttribute9  = $Attribute.extensionAttribute9
    extensionAttribute10 = $Attribute.extensionAttribute10
    extensionAttribute11 = $Attribute.extensionAttribute11
    extensionAttribute12 = $Attribute.extensionAttribute12
    extensionAttribute13 = $Attribute.extensionAttribute13
    extensionAttribute14 = $Attribute.extensionAttribute14
    extensionAttribute15 = $Attribute.extensionAttribute15
    }

}

if ($ActionType -eq $true) {

    Write-Host -ForegroundColor Cyan "Here are the on prem stored attributes for $UserUPN :"
    $OutputOnPremAttributes | Format-List 

} else {

 return $OutputOnPremAttributes
}

}

