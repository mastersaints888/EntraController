

$ResourceNames = Import-Csv -Path "$ENV:USERPROFILE\Documents\EntraController\AccessPackages\New-EZBulkAccessSecurityGroupAssignment.csv"
function New-EzAccessPackageGroupResource {

  param (

    [Parameter(Mandatory=$true)][String]$GroupName,
    [Parameter(Mandatory=$true)][String]$CatalogName,
    [Parameter(Mandatory=$True)][String]$AccessPackageName
  
  )


$GroupName = $GroupName.Trim()
$CatalogName = $CatalogName.Trim()
$AccessPackageName = $AccessPackageName.Trim()
# Catalog, Access Package and Group ID names
#$CatalogName = "IT" # Sample: "General"
#$AccessPackageName = "AP - TechBridge - IT  - Humberto - Testing" # Sample: "Access Package 1"
#$GroupName = "Administrators" # Sample: "Group 1"

# Get catalog by its Display Name
try{
$GetCataLog = Get-MgEntitlementManagementCatalog -Filter "displayName eq '$CatalogName'" -All -ErrorAction Stop
$GetCataLog | Select-Object DisplayName, Id
}catch{
  Write-Host "Error retrieving catalog $CatalogName :" $_.Exception.Message -ForegroundColor Red
}

# Get Access Package ID by its Display Name
try{
$GetAccessPackage = Get-MgEntitlementManagementAccessPackage -All | Select-Object DisplayName, Id | Where-Object { $_.DisplayName -eq "$AccessPackageName" } -ErrorAction Stop
$GetAccessPackage | Select-Object DisplayName, Id 
}
catch{
  Write-Host "Error retrieving access package $AccessPackageName :" $_.Exception.Message -ForegroundColor Red
}

# Get the Object ID of a group in Entra ID by its name
try {
  $GetGroup = Get-MgGroup -Filter "DisplayName eq '$GroupName'" -All -ErrorAction Stop
}
catch {
  Write-Host "Error retrieving group $GroupName :" $_.Exception.Message -ForegroundColor Red
}

$GetGroup | Select-Object DisplayName, Id



# Catalog Id AP ID and Group Object Id for the Catalog where the Group needs to be added
$CatalogId = $GetCatalog.Id # Catalog ID - Sample: "db4859bf-43c3-49fa-ab13-8036bd333ebe"
$GroupObjectId  = $GetGroup.Id # Object ID of the group - Sample: "b3b3b3b3-3b3b-3b3b-3b3b-3b3b3b3b3b3b"
$AccessPackageId = $GetAccessPackage.Id



# Add the Group as a resource to the Catalog
$GroupResourceAddParameters = @{
  requestType = "adminAdd"
  resource = @{
    originId = $GroupObjectId 
    originSystem = "AadGroup"
  }
  catalog = @{ id = $CatalogId }
}

try{
New-MgEntitlementManagementResourceRequest -BodyParameter $GroupResourceAddParameters -ErrorAction Stop
}
catch{
  Write-Host "Error adding group $GroupName as a resource to catalog $CatalogName :" $_.Exception.Message -ForegroundColor Red
}


# Get the Group as a resource from the Catalog
$CatalogResources = Get-MgEntitlementManagementCatalogResource -AccessPackageCatalogId $CatalogId -ExpandProperty "scopes" -all
$GroupResource = $CatalogResources | Where-Object OriginId -eq $GroupObjectId 
$GroupResourceId = $GroupResource.id
$GroupResourceScope = $GroupResource.Scopes[0]

# Add the Group as a resource role to the Access Package
$GroupResourceFilter = "(originSystem eq 'AadGroup' and resource/id eq '" + $GroupResourceId + "')"
$GroupResourceRoles = Get-MgEntitlementManagementCatalogResourceRole -AccessPackageCatalogId $CatalogId -Filter $GroupResourceFilter -ExpandProperty "resource"
$GroupMemberRole = $GroupResourceRoles | Where-Object DisplayName -eq "Member"

$GroupResourceRoleScopeParameters = @{
  role = @{
      displayName =  "Member"
      description =  ""
      originSystem =  $GroupMemberRole.OriginSystem
      originId =  $GroupMemberRole.OriginId
      resource = @{
          id = $GroupResource.Id
          originId = $GroupResource.OriginId
          originSystem = $GroupResource.OriginSystem
      }
  }
  scope = @{
      id = $GroupResourceScope.Id
      originId = $GroupResourceScope.OriginId
      originSystem = $GroupResourceScope.OriginSystem
  }
 }
try{
New-MgEntitlementManagementAccessPackageResourceRoleScope -AccessPackageId $AccessPackageId -BodyParameter $GroupResourceRoleScopeParameters -ErrorAction Stop
}
catch{
  Write-Host "Error adding group $GroupName as a resource role to access package $AccessPackageName :" $_.Exception.Message -ForegroundColor Red
}

}



foreach($Group in $ResourceNames){
try{
New-EzAccessPackageGroupResource -GroupName $Group.GroupName -CatalogName $Group.CatalogName -AccessPackageName $Group.AccessPackageName -ErrorAction Stop
Write-Host "Successfully added group $Group to Access Package." -ForegroundColor Green
}
catch{ Write-Host "Failed to add group $Group to Access Package." $_ -ForegroundColor Red
}
}
