###############################
# Web Request Set a Cloud Extension Attributes on Many Users In A Group
###############################

#Install-Module MSAL.PS -Force


# You MUST already be logged in using Connect-MgGraph
#Connect-MgGraph -Scopes "Application.Read.All"
function Set-EzCloudExtensionAttribute {

<#    $ctx = Get-MgContext

$clientId = $ctx.ClientId
$tenantId = $ctx.TenantId
$scopes   = $ctx.Scopes

# Use MSAL to silently grab the same token Graph PowerShell is using
$tokenResponse = Get-MsalToken -ClientId $clientId -TenantId $tenantId -Scopes $scopes 

$accessToken = $tokenResponse.AccessToken

#>



# Get all applications
function Get-EzCloudAppExtensionProperties {



$apps = Get-MgApplication -All

# Collect extension properties for each app
$results = foreach ($app in $apps) {
    $extProps = Get-MgApplicationExtensionProperty -ApplicationId $app.Id -ErrorAction SilentlyContinue

    foreach ($ext in $extProps) {
        [PSCustomObject]@{
            AppDisplayName     = $app.DisplayName
            AppId              = $app.AppId
            ObjectId           = $app.Id
            ExtensionName      = $ext.Name
            DataType           = $ext.DataType
            MultiValued        = $ext.IsMultiValued
            SyncedFromOnPrem   = $ext.IsSyncedFromOnPremises
            Targets            = ($ext.TargetObjects -join ",")
        }
    }
}

return $results 

}

function Get-EzCloudAppExtentionOptions {

    param (
        [string]$Prompt,
        [array]$Options
    )
 #fill the options into an array with the available licenses in the tenant
 $OptionsArray = @()

 $OptionsArray += Get-EzCloudAppExtensionProperties
 
 $Options = $OptionsArray.ExtensionName
 
    #User prompt 
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

#Get the selected attribute of the the user
$SelectedCloudAttribute = Get-EzCloudAppExtentionOptions



$CloudAttributeValue = Read-Host "Please put in the value of the cloud attribute $SelectedCloudAttribute "


<#
# Prepare headers
$Headers = @{
    "Authorization" = "Bearer $accessToken"
    "Content-Type"  = "application/json"
}
#>

# Prepare body
$Body = @{ "$SelectedCloudAttribute" = "$CloudAttributeValue" } | ConvertTo-Json





#apply this to a user or a group selection 

$confirmed = $false

while (-not $confirmed){

    $TypeSelection = Read-Host "Would you like to apply [Attribute] '$SelectedCloudAttribute' with [Value] '$CloudAttributeValue' this to a single user or group of users? (Type U for single user or G for group of users)"


        switch($TypeSelection){
            
            "G"{
            #Input the group ID of the users you wish to apply this attribute to below
            $GroupSelection = Read-Host "Please type or paste in the group name of which you would like to apply the attribute to "
            
            try {
                $Group = Get-MgGroup -Filter "displayName eq '$($GroupSelection)'" -ErrorAction Stop
                $Users = $null
                $Users = Get-MgGroupMemberAsUser -GroupId $Group.Id -ErrorAction Stop | Select-Object userPrincipalName
            }
            catch {
                Write-Host -ForegroundColor Red "An error has occured $($_.Exception.Message)"
                $raw = $_.Exception.Message.ToString()
                Write-Host -ForegroundColor Red "An error has occurred: $raw"

                # normalize - remove newlines and trim
                $msg = ($raw -replace '\s+',' ') -replace '\r','' -replace '\n',''
                $msg = $msg.Trim()

                if ($msg -match "Cannot bind argument to parameter\s+'GroupId'\s+because it is an empty string") {
                Write-Host -ForegroundColor Yellow "[IMPORTANT] Check if group name is spelled correctly or if group exists"
                }

            }
            

            #Loop thru each user and apply the extension attribute
            foreach($User in $Users){

                try {

                    Write-Host -ForegroundColor Cyan "Applying [Attribute] '$SelectedCloudAttribute' with [Value] '$CloudAttributeValue' to User --- $($User.userPrincipalName)" 
                    # PATCH request
                    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/users/$($User.userPrincipalName)" `
                        -Method PATCH `
                        -Body $Body `
                        -ContentType "application/json" `
                        -ErrorAction Stop
                }           
                catch {
                    Write-Host "-Error applying to User $($User.userPrincipalName) : $_" -ForegroundColor Red
                    }

                }

                $confirmed = $true

            }
            "U"{

                $UserSelection = Read-Host "Please type or paste in the user principal name (UPN) of the user you would like to apply the attribute to "
                

                
                try {
                    $User = Get-MgUserByUserPrincipalName -UserPrincipalName $UserSelection -ErrorAction Stop
                    Write-Host -ForegroundColor Cyan "Applying [Attribute] '$SelectedCloudAttribute' with [Value] '$CloudAttributeValue' to User --- $($UserSelection)" 
                    # PATCH request
                    Invoke-MgGraphRequest -Uri "https://graph.microsoft.com/v1.0/users/$($User.UserPrincipalName)" `
                        -Method PATCH `
                        -Body $Body `
                        -ContentType "application/json" `
                        -ErrorAction Stop
                }           
                catch {
                    Write-Host "-Error applying to User $($UserSelection) : $($_.Exception.Message)" -ForegroundColor Red
                    }
                
                $confirmed = $true

            }
            default {

                Write-Host "Invalid Entry: Please select U for single user or G for Group of Users"

            }
        }


}

}

