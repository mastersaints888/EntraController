
try {
    #Import-Module -Name Microsoft.Graph
    Connect-MgGraph -Scopes "Directory.Read.All"
}
catch {
    Write-Host -ForegroundColor Green "Microsoft Graph is Loaded"
}

#region Get License
function Get-EzLicense {
param (
    [hashtable]
    $skuLookup,
    [switch]
    $Pretty
)


# Step 1: Download CSV if needed
$csvUrl = "https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv"
$csvPath = "$env:TEMP\licensing_reference.csv"

if (-not (Test-Path $csvPath)) {
    Invoke-WebRequest -Uri $csvUrl -OutFile $csvPath
}

# Step 2: Import CSV and build SKU lookup
$csv = Import-Csv -Path $csvPath

# Building lookup table: String ID => Display Name
$skuLookup = @{}
foreach ($line in $csv) {
    if (-not $skuLookup.ContainsKey($line.String_ID)) {
        $skuLookup[$line.String_ID] = $line.Product_Display_Name
    }
}

# Step 3: Get Subscribed SKUs and show friendly names
$skus = Get-MgSubscribedSku

foreach ($sku in $skus) {
    $skuId = $sku.SkuPartNumber # like "ENTERPRISEPREMIUM"
    $skuGuid = $sku.SkuId       # GUID
    $friendlyName = $skuLookup[$skuId]

    [PSCustomObject]@{
        FriendlyName  = $friendlyName
        ConsumedUnits = $sku.ConsumedUnits
        PrepaidUnits  = $sku.PrepaidUnits.Enabled
        SkuGuid       = $skuGuid
        SkuPartNumber = $skuId
        
    }
}

    #pretty output switch will format it in a nice table for the user to see at the bottom
    if ($pretty) {
        Get-EzLicense | Select-Object ConsumedUnits, PrepaidUnits, FriendlyName, skupartnumber | Format-Table
    }

}

#endregion


#region Set License




<#This is a specific function for use in the Set-EzLicenseGroup function because when we create a lookup table for skus the empty friendly name
keys will throw errors
#>
function Get-ValidOptions {
    $OptionsArray = @()
    $OptionsArray += Get-EzLicense

    $Options = @{}  # <<-- This was changed to a hashtable, not an array now

    foreach ($Option in $OptionsArray) {
        try {
            if ($null -eq $Option.FriendlyName) {
                $Option.FriendlyName = "Not Available"
            }
            $Options[$Option.FriendlyName] = $Option.SkuGuid
        }
        catch {
            Write-Host "An Error has occured $_"
        }
    }

    $Options
}


#Get-ValidOptions



function Set-EzLicenseUserSelection {

    param (
        [string]$Prompt,
        [array]$Options
    )

    #fill the options into an array with the available licenses in the tenant
    $OptionsArray = @()

    $OptionsArray += Get-EzLicense
    
    $OutputOptions = @()

    #Creating a table with friendlyname and a fallback if friendlyname doesnt exist to skupartnumber
    foreach($Option in $OptionsArray) {
    $OutputOptions += [PSCustomObject]@{
        FriendlyName = $Option.FriendlyName
        BackupName   = $Option.SkuPartNumber
    }
    }
    
    #here i am accounting for possible null values
    
    foreach($Option in $OutputOptions){
        try {
            #If null we must account for that 
            if(-not $Option.FriendlyName){
            $Option = $Option.BackupName
        }
            if($Option.FriendlyName){
                $Option = $Option.FriendlyName
            }

            $Options += $Option
        

    }
        catch {
            Write-Host "An Error has occured $_"
        }
    }

    $Options 

    
    
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




#foreach($License in $OptionsArray)

}

#Set-EzLicenseUserSelection


#region Set License Group
function Set-EzLicenseGroup {
    param (
        [string]$Prompt,
        [array]$Options
    )



# Set key value pairs for the available licenses 
$SkuNameToGuidMapping = @()
$SkuNameToGuidMapping += Get-ValidOptions

# Create a hashtable for lookup
$GuidLookup = Get-ValidOptions

# Ask user to select license
$LicenseSelection = Set-EzLicenseUserSelection -Prompt "Select a license"

# Lookup the GUID based on the readable license name
$SelectedGuid = $GuidLookup[$LicenseSelection]

# Output
$SelectedGuid


#Define the parameters for the license assignment, If you need multiple you must create another expression each time within the array

    $addLicenses = @(
        @{
            disabledPlans = @()      # Any plans you want disabled would go here
            skuId = $SelectedGuid      # Expression 1: Replace with your actual SKU ID currently E3
        }
    )
    $removeLicenses = @()      # If you want anything removed from a group they'd go here


    #This will Assign the license to the group using the above params
    #Set-MgGroupLicense -GroupId $GroupID -BodyParameter $params



#Get the output here for all security groups 
$GroupSelection = @()
$AllGroups = Get-MgGroup -All


# Get all groups where SecurityEnabled is $true
$AllGroups = Get-MgGroup -All | Where-Object { $_.SecurityEnabled -eq $true }


foreach($Group in $AllGroups){
        
    $GroupSelection += [PSCustomObject]@{
        DisplayName = $Group.DisplayName
        Id = $Group.Id
        securityEnabled = $Group.SecurityEnabled
    }
} 

$GroupSelection | Sort-Object -Descending DisplayName | Format-Table

#sort the security group hashtable
#$GroupSelection.GetEnumerator() | Sort-Object Key -Descending


Start-Sleep -Seconds 10

$GroupID = Read-Host "Please paste in a group ID to apply the licesne to" 

$GroupName = (Get-MgGroup -GroupId $GroupID).DisplayName

#Confirmation switch statement 
$Confirmed = $false

while (-not $Confirmed) {
   
    Write-Host -ForegroundColor Yellow "The license [$LicenseSelection] is about to be applied to the group: $GroupName"
    $GroupConfirm = Read-Host "Please press Y to confirm or N to exit"
    
try{
    switch ($GroupConfirm) {
        "Y" { $Confirmed = $True 
                break }
        "N" { write-host "Exiting Script..." 
                exit 
            }
        
        else { write-host "Invalid selection please select either Y/N"
        } 
    
    }
}
catch{ 
    write-host "An error has occured $_"
}

} 


try {
    Set-MgGroupLicense -GroupId $GroupID -AddLicenses $addLicenses -RemoveLicenses @()
    Write-Host -ForegroundColor Green "The license [$LicenseSelection] is NOW applied to the group: $GroupName"
}
catch {
    Write-Host "An error occured $_.Exception.Message"
}


    
}

#Set-EzLicenseGroup



#Get-EzLicense | Select-Object ConsumedUnits, PrepaidUnits, FriendlyName

