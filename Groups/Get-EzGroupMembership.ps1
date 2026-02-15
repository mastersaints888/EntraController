# Import the CSV file with user details (Name and GroupID)
#open excel file for user to edit
function Get-EzGroupMembership{

Write-Host -ForeGroundColor Yellow "Attempting to Open CSV for editing... Please add in each group you would like to pull a report for and save the file. Once complete, close Excel and return here to continue the script."
Start-Sleep -Seconds 3
Start-Process "$env:USERPROFILE\Documents\EntraController\Groups\bulkUserGroupGet.csv"

#set confirmation for breaking the loop if Y is selected
$Confirmed = $false

#user prompt
    while (-not $Confirmed) {
       
        
        try {

            $P = Read-Host "Please add in each group you would like to pull a report for. Type Y when finished (or type Q to quit)"

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


$userGroupGet = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\Groups\bulkUserGroupGet.csv"
$ErrorActionPreference = 'Stop'  # Stop on errors so we can see them during the process

$UserToGroupMappings = @()

foreach ($Group in $userGroupGet) {
    
    # Retrieve group Id of each group
    try {
        
    $groupName = Get-MgGroup -Filter "displayName eq '$($Group.groupName.Trim())'" -ErrorAction Stop
    $groupId = $groupName.Id
    # Set if dynamic group
    $GroupType = $groupName.GroupTypes
    # if on prem group set to true if cloud false 
    $OnPrem = $groupName.OnPremisesSyncEnabled
        if($OnPrem -ne $true){
            $OnPrem = $false }

    #retrieve users in the group
    $groupMembers = Get-MgGroupMemberAsUser -All -GroupId $groupId -ErrorAction Stop
    
    }
    catch {
        Write-Host "An error occurred while processing group '$($Group.groupName)': $_" -ForegroundColor Red
        continue
    }
    # generate report 
        
        foreach ($groupMember in $groupMembers){  

        #grab users companyName
        $CompanyName = Get-MgUser -UserId $groupMember.Id -Property CompanyName | Select-Object CompanyName

        $UserToGroupMappings += [PSCustomObject]@{
                                GroupID = $groupId
                                Group = $groupName.DisplayName
                                UPN = $groupMember.UserPrincipalName
                                DisplayName = $groupMember.DisplayName
                                JobTitle = $groupMember.JobTitle
                                OnPrem = $OnPrem
                                GroupType = foreach ($Type in $GroupType){ $Type -join ","}
                                UserCompanyName = $CompanyName.CompanyName
                            }
        }
    
    
    
   
}

    function Show-UserGroupReport {
    param (
        [Parameter(Mandatory=$true)]
        [array]$UserToGroupMappings
    )

    Write-Host "User to Group Mappings Report:" -ForegroundColor Cyan
    $UserToGroupMappings | Format-Table -AutoSize
    }

    Show-UserGroupReport -UserToGroupMappings $UserToGroupMappings


$ErrorActionPreference = 'Continue'

# ask user if they want to download report 
$Confirmed = $false

    While (-Not $Confirmed){

        try {

            $P = Read-Host "Would you like to download a report? Press Y to continue (or type Q to quit) "

            switch ($P.ToUpper()) {
                "Y" {
                    
                    $csvname = Read-Host "Please enter a name for the CSV file (without extension ie .csv at the end) "

                    try {
                        Write-Host "Downloading Report to $ENV:USERPROFILE\Downloads\$csvname.csv" -ForegroundColor Green
                        $UserToGroupMappings | Export-Csv -Path "$ENV:USERPROFILE\Downloads\$csvname.csv" -NoTypeInformation -ErrorAction Stop
                        $Confirmed = $true
                    }
                    catch {
                        Write-Host "An error occurred while exporting the CSV: $_" -ForegroundColor Red
                    }
                    
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

}