function New-EzGroupMembership {


# Import the CSV file with user details (Name and GroupID)
#open excel file for user to edit
Start-Process "$env:USERPROFILE\Documents\EntraController\Groups\bulkUserGroupAdd.csv"

#set confirmation for breaking the loop if Y is selected
$Confirmed = $false

#user prompt
    while (-not $Confirmed) {
       
        
        try {

            $P = Read-Host "Please add in each user with a corresponding group. When done, save the csv and exit. Type C to DryRun, Type A to add users to groups, Type D to remove users from groups. when finished (or type Q to quit)"

            switch ($P.ToUpper()) {
                
                "A" {

                    Write-Host "Proceeding with script..." -ForegroundColor Green

                    $userGroupAdd = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\Groups\bulkUserGroupAdd.csv"

                    foreach ($Item in $userGroupAdd) {
    
                        try {
                        # Retrieve group Id of each group
                        $groupId = Get-MgGroup -Filter "displayName eq '$($Item.groupName.Trim())'" -ErrorAction Stop
                        $groupId = $groupId.Id

                        #retrieve directory object ID of each user
                        $userId = Get-MgUserByUserPrincipalName -UserPrincipalName $Item.userPrincipalName.Trim() -ErrorAction stop
                        $userId = $userId.Id
                        }
                        catch {
                            Write-Host -ForegroundColor Red "An error occurred while processing user '$($Item.userPrincipalName)' or group '$($Item.groupName)': $_"
                        }

                        #add each user to each group
                        try {

                            New-MgGroupMember -GroupId $groupId -DirectoryObjectId $userId -ErrorAction Stop
                            Write-Host -ForegroundColor Green "[ADD] Adding user $($Item.userPrincipalName) to group $($Item.groupName)"

                        }
                        catch {
                            Write-Host -ForegroundColor Red "Error adding user $($Item.userPrincipalName) to group $($Item.groupName): $_"
                        }
    
    
   
                    }
                    $Confirmed = $true
                }
                "D" {

                    Write-Host "Proceeding with script..." -ForegroundColor Green

                    $userGroupAdd = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\Groups\bulkUserGroupAdd.csv"

                    foreach ($Item in $userGroupAdd) {
    
                        try {
                        # Retrieve group Id of each group
                        $groupId = Get-MgGroup -Filter "displayName eq '$($Item.groupName.Trim())'" -ErrorAction Stop
                        $groupId = $groupId.Id

                        #retrieve directory object ID of each user
                        $userId = Get-MgUserByUserPrincipalName -UserPrincipalName $Item.userPrincipalName.Trim() -ErrorAction stop
                        $userId = $userId.Id
                        }
                        catch {
                            Write-Host -ForegroundColor Red "An error occurred while processing user '$($Item.userPrincipalName)' or group '$($Item.groupName)': $_"
                        }

                        #add each user to each group
                        try {

                            Remove-MgGroupMemberByRef -GroupId $groupId -DirectoryObjectId $userId -ErrorAction Stop
                            Write-Host -ForegroundColor Yellow "[REMOVE] Removing user $($Item.userPrincipalName) from group $($Item.groupName)"
                            
                        }
                        catch {
                            Write-Host -ForegroundColor Red "Error Removing user $($Item.userPrincipalName) to group $($Item.groupName): $_"
                        }
    
    
   
                    }
                    $Confirmed = $true
                
                }
                "Q" {
                    Write-Host "Exiting script. Goodbye!" -ForegroundColor Yellow
                    return
                }
                "C"{
                    $userGroupAdd = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\Groups\bulkUserGroupAdd.csv"
                    foreach($Item in $userGroupAdd){
                            write-host -ForegroundColor Cyan "[CONFIRM] This will apply to USER: $($Item.userPrincipalName) and to the GROUP: $($Item.groupName) "
                        }
                        Write-Host "Dry Run completed. No changes were made." -ForegroundColor Yellow
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


$ErrorActionPreference = 'Continue'

}