
<#try{
    Connect-AzAccount 
Import-Module -Name Az.Resources                                                  
Import-Module -Name Az.Accounts 
Import-Module -Name Microsoft.Graph.Authentication                                
Import-Module -Name Microsoft.Graph.Groups
}
catch {
    
    Import-Module -Name Az.Accounts
}
#>
#when we come to the final build this will be edited and used at the top of the script 
function Get-UserSelection {
    
    param (
        [string]$Prompt,
        [array]$Options
    )
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
}



#region swc



function swc {

    param (
        [switch]
        $show
    )
    
    
    #Show current context only
if ($show) {
    Write-Host -ForeGroundColor Green "Current Sub---->"(Get-AzContext).Name
    exit
} 



    #Show user current context every time
    $SwcContext = Write-Host -ForeGroundColor Green "Current Sub---->"(Get-AzContext).Name 

    $SwcContext
    
    $AvailableSubscription = Get-AzSubscription
    #$AvailableSubscription

    #formating the available subs into a hashtable i can work with strings for input into $c switch
    $SubTable = @{}

    foreach($Sub in $AvailableSubscription){
        
        try{
            if (-not $SubTable.ContainsKey($Sub.Name)){
            $SubTable[$Sub.Name] = $Sub.Id

        }
    } catch { Write-Host "An error occured during the creation of the Subscription Key Table" $_.Exception.Message}
    }

   

    #Options array from subtable
    $Options = @()

    foreach($Op in $AvailableSubscription){
        $Options += $Op.Name
        }
    

    #Get user selection here and then map this output to the SubTable value which is the sub ID

    $SelectedSub = Get-UserSelection -Options $Options

    $SubId = $SubTable[$SelectedSub]
    
    try{
    Set-AzContext -Subscription "$SubId" 
    }
    catch{
        $_.Exception
    }


}





#region Get-RbacCache



function Get-RbacCache {

    #cash the subscriptions
    $subscriptionsCache = @{}
    Get-AzSubscription | ForEach-Object {
        $subscriptionsCache[$_.Name.ToLower()] = $_.Id
    }

    #Cache the RGs
    $resourceGroupsCache = @{}
    foreach ($sub in $subscriptionsCache.Values) {
        Set-AzContext -SubscriptionId $sub | Out-Null
        Get-AzResourceGroup | ForEach-Object {
            $key = "$sub|$($_.ResourceGroupName.ToLower())"
            $resourceGroupsCache[$key] = $_.ResourceId
        }
    }

    #cache all the roles
    $roleDefinitionsCache = @{}
    Get-AzRoleDefinition | ForEach-Object {
        $roleDefinitionsCache[$_.Name.ToLower()] = $_.Id
    }

    #Cache for groups and Users
    $principalCache = @{}
    Get-AzADUser | ForEach-Object {
        $principalCache[$_.UserPrincipalName.ToLower()] = $_.Id
    }
    Get-AzADGroup | ForEach-Object {
        $principalCache[$_.DisplayName.ToLower()] = $_.Id
    }

    #management group cache
    $mgCache = @{}
    Get-AzManagementGroup | foreach-object {
        $mgCache[$_.DisplayName] = $_.Id

    }

    #Return a master hashtable with all sub-caches
    return @{
        Subscriptions    = $subscriptionsCache
        ResourceGroups   = $resourceGroupsCache
        RoleDefinitions  = $roleDefinitionsCache
        Principals       = $principalCache
        ManagementGroups = $mgCache
    }
}


#region Set-EzBulkRbac

function Set-EzBulkRbac {

    [CmdletBinding()]
    param (

        [switch]$DryRun
    )

    $Cache = Get-RbacCache

    $CsvPath = "$env:USERPROFILE\Documents\EntraController\SubsAndRBAC\rbac.csv" 
    


    $csv = Import-Csv -Path $CsvPath
    foreach ($entry in $csv) {

        $subName = $entry.SubscriptionName.ToLower()
        $rgName = $entry.ResourceGroupName.ToLower()
        $roleName = $entry.RoleName.ToLower()
        $principalName = $entry.PrincipalName.ToLower()
        $managementGroupName = $entry.managementGroupName.ToLower()

        $subscriptionId = $Cache['Subscriptions'][$subName]
        $resourceGroupKey = "$subscriptionId|$rgName"
        $scope = $Cache['ResourceGroups'][$resourceGroupKey]
        $roleId = $Cache['RoleDefinitions'][$roleName]
        $principalId = $Cache['Principals'][$principalName]


        #Pre command checks for sub level scope
        if(-not $scope -and $subscriptionId){
            $scope = "/subscriptions/$subscriptionId"
        }

        #pre commend check for MG level scope
        if(-not $scope -and (-not $subscriptionId)){
            $scope = $Cache['ManagementGroups'][$managementGroupName]
        }

        if ($subscriptionId -or $managementGroupName -and $scope -and $roleId -and $principalId) {
            if ($DryRun) {
                if($subscriptionId){
                Write-Host "[DRYRUN] Would assign '$roleName' to '$principalName' in scope '$scope' subname: '$subName'"
                }
                if($managementGroupName){
                    Write-Host "[DRYRUN] Would assign '$roleName' to '$principalName' in scope '$scope' subname: '$managementGroupName'"
                }
            } else {

                #Assigning the roles from spreadsheet 
                try {
                New-AzRoleAssignment -ObjectId $principalId -RoleDefinitionId $roleId -Scope $scope
                Write-Host "Assigned '$roleName' to '$principalName' in scope '$scope'"
                }catch
                { Write-Host "An error during the Role assignment has occured $_.Exception"
                }

            }
        } else {
            Write-Warning "Missing lookup: $($entry | ConvertTo-Json -Compress)"
        }
    }

}

#Set-EzBulkRbac -DryRun

#endregion




#region Get-EzRbacReport

function Get-EzRbacReport {
[CmdletBinding()]

param( 
    [switch]
    $Show
)

#$Cache = Get-RbacCache



$TenantRoles = Get-AzRoleAssignment 

$Report = @()
$TenantRoles | ForEach-Object {
    $Report += [PSCustomObject]@{
        Type        = $_.ObjectType
        UPN         = $_.SignInName
        DisplayName = $_.DisplayName
        ObjectId    = $_.ObjectId
        RoleName    = $_.RoleDefinitionName  
        Scope       = $_.Scope
        
    }
}

#show output on screen switch
if ($Show){
    $Report 
    exit
}


$EnvPath = $env:USERPROFILE 

$FileName = Read-Host "Please enter the name of your file, DO NOT include .csv"

try{
#Report Generation

Write-Host -ForegroundColor Yellow "Generating RBAC Report..."
$Report | Export-Csv -Path "$EnvPath\Downloads\$FileName.csv"
Write-Host -ForeGroundColor Green "Successfully Generated Report at $EnvPath\Downloads\$FileName.csv"

}
catch
{ Write-Host "Something went wrong during the geration of the report: $_.Exception" }



}


#"$env:USERPROFILE\Downloads\rbaccache.txt"
