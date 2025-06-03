function Set-EzGroupSp {


try {
     # Get the Service Principal
    $AllSps = Get-MgServicePrincipal -All | Sort-Object DisplayName
    $All = $AllSps | Select-Object DisplayName, Id, SignInAudience


        $AllServicePrincipalSelection = @()
            foreach ($sp in $All) {

                $AllServicePrincipalSelection += [PSCustomObject]@{
                    DisplayName = $sp.DisplayName
                    Id = $sp.Id
                    SignInAudience = $sp.SignInAudience
                }           

            }

            $AllServicePrincipalSelection | Format-Table
        }catch{
            
            Write-Host "There was an error grabbing your service principals" $_.Exception
        }


#Start-Sleep -Seconds 5

$spId = Read-Host "Please paste in the app Id of your app from the table above"
$sp = Get-MgServicePrincipal -ServicePrincipalId $spId


$sp.AppRoles | Select-Object DisplayName | Format-Table

Write-Host -ForegroundColor Green "Your available application roles are listed above"

Start-Process -FilePath "$ENV:USERPROFILE\Documents\EntraController\ServicePrincipals\SpGroups.csv"

$Confirmed = $false

while (-not $Confirmed) {
       
        
        try {

            $P = Read-Host "Please build out your Enterprise App Groups and roles, save the csv and exit the csv. type C to dryrun type Y to confirm (or type Q to quit)"

            # Import the CSV (must contain columns: Group, Role)
            $csv = Import-Csv -Path "$ENV:USERPROFILE\Documents\EntraController\ServicePrincipals\SpGroups.csv"

            Write-Host -ForegroundColor Yellow "[CONFIRM] This will create the following groups and roles..."


            switch ($P.ToUpper()) {
                
                "Y" {
                    Write-Host "Proceeding with script..." -ForegroundColor Green
                    $Confirmed = $true
                }
                "Q" {
                    Write-Host "Exiting script. Goodbye!" -ForegroundColor Yellow
                    return
                }
                "C" {
                        foreach($row in $csv){
                            
                            write-host -ForeGroundColor Yellow "[CONFIRM] Applying to App $($sp.DisplayName) - This will add group: $($Row.Group) with Role: $($Row.Role)"
                        }
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





#Build AppRole DisplayName ID cache
$AvailableAppRolesCache = @{}
foreach ($role in $sp.AppRoles) {
    $AvailableAppRolesCache[$role.DisplayName] = $role.Id
}

#Build unique group name list
$uniqueGroupNames = $csv.Group | Sort-Object -Unique

#Resolve each group name to ID and cache it
$groupIdMap = @{}
foreach ($groupName in $uniqueGroupNames) {
    $groupObj = Get-MgGroup -Filter "DisplayName eq '$groupName'"
    if ($groupObj) {
        $groupIdMap[$groupName] = $groupObj.Id
    } else {
        Write-Warning "Group '$groupName' not found!"
    }
}

#roles based on the CSV mapping
foreach ($row in $csv) {
    $groupName = $row.Group.Trim()
    $roleName  = $row.Role.Trim()

    $groupId = $groupIdMap[$groupName]
    $roleId  = $AvailableAppRolesCache[$roleName]

    if (-not $groupId) {
        Write-Warning "Skipping: Group ID not found for '$groupName'"
        continue
    }
    if (-not $roleId) {
        Write-Warning "Skipping: AppRole ID not found for '$roleName'"
        continue
    }

    $params = @{
        principalId = $groupId
        resourceId  = $spId
        appRoleId   = $roleId
    }

    try {
        New-MgServicePrincipalAppRoleAssignment -ServicePrincipalId $spId -BodyParameter $params
        Write-Host "Assigned role '$roleName' to group '$groupName'"
    } catch {
        Write-Warning "Failed to assign role '$roleName' to group '$groupName': $_"
    }
}

}


