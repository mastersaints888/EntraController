
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
    return
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


#region MgContext

function con {

    param (
        [switch]$mgc,
        [switch]$mgs
    )
  

$UserContext = $null
$UserContext = Get-MgContext 
    
if ($mgc){    
    

    $MgContextOut = @()

    $MgContextOut = [PSCustomObject]@{
        Account = $UserContext.Account
        Tenant = $UserContext.TenantId
    }

    Write-Host -ForeGroundColor Yellow "Your Microsoft Graph Context is below, all calls will be against these contexts:"
    $MgContextOut | Format-List
}


if($mgs){

    $Confirmation = $false
    
    while($Confirmation -eq $false){    

        write-host -ForegroundColor Green "Currently Logged in on:"$UserContext.Account
        write-host -ForegroundColor Green "On Tennant:"$UserContext.TenantId
        $Answer = read-host "Would you like to switch to another tenant or user account? (Y/N)"
         
        switch($Answer){
            "Y" {
                Disconnect-MgGraph -ErrorAction Ignore 
                Connect-MgGraph 
                $Confirmation = $true
                return
            }
            "N" {
                write-host "returning to menu"
                $Confirmation = $true
                return
            }
            default {
                write-host "please type (Y/N)"
            }
          
        } 

    }

}

}




#region Get-RbacCache



function Get-RbacCache {

    param(
        [switch]
        $subcache,

        [switch]$mancache,

        [switch]$rgcache
    )

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

    if($subcache){
        return $subscriptionsCache
    }

    if($mancache){
        return $mgCache
    }

    if($rgcache){
        return $resourceGroupsCache
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

        [switch]$DryRun,
        [switch]$RemoveRoleAssignments
    )

    Write-Host -ForegroundColor Yellow "Attempting to open up excel Dynamic groups database..."

    Start-Process "$env:USERPROFILE\Documents\EntraController\SubsAndRBAC\rbac.csv"

    #set confirmation for breaking the loop if Y is selected
 
$Confirmed = $false

#user prompt
    while (-not $Confirmed) {
       
        
        try {

            $P = Read-Host "Please build out your RBAC Framework, save the csv and exit the csv. type Y to continue this WILL NOT APPLY until you confirm on the next prompt (or type Q to quit)"

            switch ($P.ToUpper()) {
                "Y" {
                    Write-Host "Proceeding with script..." -ForegroundColor Green
                    $Confirmed = $true
                }
        
                "Q" {
                    Write-Host "Exiting script. Goodbye!" -ForegroundColor Yellow
                    return
                }
                default {
                    Write-Host "Invalid input. Please type 'Y' to continue or 'Q' to quit." -ForegroundColor Red
                }
            }
        }
        catch {
            Write-Host "An error occurred: $_" -ForegroundColor Red
        }
    }
   
    $Cache = Get-RbacCache

    $CsvPath = "$env:USERPROFILE\Documents\EntraController\SubsAndRBAC\rbac.csv" 
    


    $csv = Import-Csv -Path $CsvPath



$Confirmed = $false
While (-not $Confirmed) {


    #Begin Switch for DryRun/Remove/Assign
    $P = Read-Host "Please type 'Y' to apply 'C' to dry run 'R' to remove assignments or 'Q' to quit." 

    switch ($P.ToUpper()){
        
        #Dry Run Switch 
        "C" { 
            
            foreach ($entry in $csv){
            
            
                if($entry.SubscriptionName){
                Write-Host -ForeGroundColor Yellow "[DRYRUN] Would apply to '$($entry.RoleName)' to '$($entry.PrincipalName)' in scope subname: '$($entry.SubscriptionName)' with resource group: '$($entry.ResourceGroupName)'"
                }
                if($entry.ManagementGroupName){
                    Write-Host -ForeGroundColor Yellow "[DRYRUN] would apply to '$($entry.RoleName)' to '$($entry.PrincipalName)' in scope '$scope' ManagementGroup: '$($entry.ManagementGroupName)'"
                }
            
        }
        #Break?   
        } 

        #Remove Role Assignment Switch   
        "R" {foreach ($entry in $csv){


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

                try {
                    Remove-AzRoleAssignment -ObjectId $principalId -RoleDefinitionId $roleId -Scope $scope -ErrorAction Stop
                    Write-Host -ForeGroundColor Yellow "Removed '$roleName' from '$principalName' in scope '$scope'"
                }catch
                { 
                    Write-Host "An error during the Role removal has occured $_.Exception"
                }
            }
        $Confirmed = $true
        } 
        

        #Assigning the roles from spreadsheet 
        "Y" {

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



                try {
                New-AzRoleAssignment -ObjectId $principalId -RoleDefinitionId $roleId -Scope $scope -ErrorAction Stop
                Write-Host "Assigned '$roleName' to '$principalName' in scope '$scope'"
                }catch
                { Write-Host "An error during the Role assignment has occured $_.Exception"
                }
                if ($null -eq $scope -or $null -eq $roleId -or $null -eq $principalId) {
                Write-Warning "Missing lookup: $($entry | ConvertTo-Json -Compress)"
                }
            }

            
        $Confirmed = $true
        }
        "Q" {
                    Write-Host "Exiting script. Goodbye!" -ForegroundColor Yellow
                    return
                }
        default {
                    Write-Host "Invalid input. Please type 'Y' to apply 'C' to dry run 'R' to remove assignments or 'Q' to quit." -ForegroundColor Red
                }
    }
} 
}




#Set-EzBulkRbac -DryRun

#endregion

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


#region Get-EzRbacReport

function Get-EzRbacReport {
[CmdletBinding()]

param( 
    [switch]
    $Show,
    [switch]$cleanview
)

$SubCache = @{}
$SubCache += Get-RbacCache -subcache

$MgCache = @{}
$MgCache += Get-RbacCache -mancache

#foreach($Sub in $Cache.)


#building out a report cache for all subs root and resource groups then need to throw into the Get-AzRoleAssignment -scope 




$EnvPath = $env:USERPROFILE 

While ($true){

    $Prompt = Get-UserSelection -Options @("Root", "Sub", "ManagementGroup", "AllTenant")

    switch ($Prompt) {
    "Root" {
        $Report = Get-AzRoleAssignment -Scope "/"
    }
    "Sub" {
        $SubscriptionName = Get-UserSelection -Options $SubCache.Keys
        $SubscriptionId = $SubCache["$SubscriptionName"]
        $Report = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId"
    }
    "ManagementGroup" { 
        $MgGroupName = Get-UserSelection -Options $MgCache.Keys
        $MgId = $MgCache["$MgGroupName"]
        $Report = Get-AzRoleAssignment -Scope "$MgId"
    }
    "AllTenant" {
        $Report = @()
        foreach($sub in $SubCache.Values){
            $Report += Get-AzRoleAssignment -Scope "/subscriptions/$sub"
        }
    }
}

$ReportOut = $Report

if($cleanview){  #Clean output view switch 
    $ReportOut = @()
    $Report | ForEach-Object {
        $ReportOut += [PSCustomObject]@{
        Type        = $_.ObjectType
        UPN         = $_.SignInName
        DisplayName = $_.DisplayName
        ObjectId    = $_.ObjectId
        RoleName    = $_.RoleDefinitionName  
        Scope       = $_.Scope
        
        }
    }
}

#show output on screen switch
if ($Show){
    $Report 
    return
}


    $FileName = Read-Host "Please enter the name of your file, DO NOT include .csv"


    ###Report Generation####
    try{
    

    Write-Host -ForegroundColor Yellow "Generating RBAC Report..."
    $ReportOut | Export-Csv -Path "$EnvPath\Downloads\$FileName.csv"
    Write-Host -ForeGroundColor Green "Successfully Generated Report at $EnvPath\Downloads\$FileName.csv"
    
    #Report loop/exit prompt 
    # Report loop/exit prompt
$validResponse = $false
do {
    $ReportPrompt = Read-Host "Would you like to generate another report? Y/N"

    switch ($ReportPrompt.ToUpper()) {
        "Y" {
            $validResponse = $true
        }
        "N" {
            return
        }
        default {
            Write-Host "Invalid input. Please enter Y or N."
        }
    }
} while (-not $validResponse)

}
    catch
    { Write-Host "Something went wrong during the geration of the report: $_.Exception" }



}
}

#"$env:USERPROFILE\Downloads\rbaccache.txt"
#Get-EzRbacReport