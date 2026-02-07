
$AttributeValue = @(
    "Development_Team"
    #"ClockCode"
)


function New-EzBulkCreateCloudAttributes {

param (

    [Parameter(Mandatory=$true)]
    [String]$AttributeName

)

$Value = $AttributeName

$ErrorActionPreference = 'Stop'

# App registration credentials
$tenantId = "35c02c30-b172-4bc7-92ca-fadf285091a9"
$clientId = "14824416-d79a-4d3c-ab20-a620caea7c1f"
$clientSecret = "jZ~8Q~O1PbhtxkBz2eHx9UQGORZ7YYnyiC2_ZbD1"

# Acquire access token
$body = @{
    grant_type    = "client_credentials"
    scope         = "https://graph.microsoft.com/.default"
    client_id     = $clientId
    client_secret = $clientSecret
}

$tokenResponse = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token" -Body $body
$accessToken = $tokenResponse.access_token
$secureAccessToken = ConvertTo-SecureString -String $accessToken -AsPlainText -Force

Connect-MgGraph -AccessToken $secureAccessToken -NoWelcome

# check extension app id for building out api query
$ExtensionApp = Get-MgApplication -Filter "displayName eq 'Tenant Schema Extension App'" -ErrorAction Stop

    if($null -eq $ExtensionApp){
    
        Write-Host "Tenant directory extensions may not be enabled in AAD. Please enable it in the Entra Connect." -ForegroundColor Red
        Write-Host "you can find documentation on how to enable this here: https://learn.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-configure-tenant-schema-extensions" -ForegroundColor Yellow
    
    }
# Extension Applications Object Id
$ExtObjID = $ExtensionApp.Id

#Extension apps app ID
$ExtenstionAppId = $ExtensionApp.AppId

# modified versions for API Call removing the dashes. If needed not using now
$ExtObjIDAPI = $ExtObjID -replace '-', ''
$ExtensionAppIdAPI = $ExtenstionAppId -replace '-', ''



# build json body for creating the new attributes 
$JsonBody = @{
    name          = "$Value"
    dataType      = "String"
    targetObjects = @("User")
} | ConvertTo-Json -Depth 5

try{
    # initial attempt at creating the new attribute
    #Write-Host -ForegroundColor Yellow "[CREATING] Attempting to Create Attribute : $Value"
    $request = Invoke-MgGraphRequest -URI "https://graph.microsoft.com/v1.0/applications/$ExtObjID/extensionProperties" `
        -Method POST `
        -Body $JsonBody `
        -ContentType "application/json"

        if ($request){
            Write-Host -ForegroundColor GREEN "[ATTRIBUTE CREATION] $($request.name) has been created"
        }else {
            Write-Host -ForegroundColor YELLOW "[WARNING] Attribute : $Value may not have been successfully created"
        }

    }catch
    {
        Write-Host -ForegroundColor RED "[ATTRIBUTE CREATION ERROR] Error creating attribute $Value :" $_.Exception.Message
    }
$ErrorActionPreference = 'Continue'

}




foreach ($Attribute in $AttributeValue){

    New-EzBulkCreateCloudAttributes -AttributeName $Attribute

}