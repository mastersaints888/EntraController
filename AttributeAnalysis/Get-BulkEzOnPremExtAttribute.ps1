

function Get-BulkEzOnPremExtAttribute {

Start-Process -FilePath "$env:USERPROFILE\Documents\EntraController\AttributeAnalysis\BulkOnPremAttribute.csv"

$Confirmed = $false

while (-not $Confirmed) {
       
        
        try {

            $P = Read-Host "Please paste the name of the group of users you want to analyze ON PREM extension attributes for into the CSV. Press Y to continue (or type Q to quit) "

            switch ($P.ToUpper()) {
                "Y" {
                    
                    $Groups = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\AttributeAnalysis\BulkOnPremAttribute.csv" -ErrorAction Stop
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

$BulkOnPremExtAttribute = @()

foreach($Group in $Groups){

    $Group = $Group.GroupName.Trim()
    try{
        $GroupID = Get-MgGroup -Filter "displayName eq '$($Group)'"
        $GroupMember = Get-MgGroupMemberAsUser -All -GroupId $GroupId.Id -ErrorAction Stop 
    }
    catch{
        Write-Host "An error occurred while retrieving group members: $_" -ForegroundColor Red
        continue
    }

    foreach($User in $GroupMember.userPrincipalName){

    try {

        
        $UserExtensionAttribute = Get-EzOnPremExtAttribute -UserUPN $User -ErrorAction Stop


        $BulkOnPremExtAttribute += [PSCustomObject]@{
            Group = $Group
            userPrincipalName = $User
            extensionAttribute1 = $UserExtensionAttribute.extensionAttribute1
            extensionAttribute2 = $UserExtensionAttribute.extensionAttribute2
            extensionAttribute3 = $UserExtensionAttribute.extensionAttribute3
            extensionAttribute4 = $UserExtensionAttribute.extensionAttribute4
            extensionAttribute5 = $UserExtensionAttribute.extensionAttribute5
            extensionAttribute6 = $UserExtensionAttribute.extensionAttribute6
            extensionAttribute7 = $UserExtensionAttribute.extensionAttribute7
            extensionAttribute8 = $UserExtensionAttribute.extensionAttribute8
            extensionAttribute9 = $UserExtensionAttribute.extensionAttribute9
            extensionAttribute10 = $UserExtensionAttribute.extensionAttribute10
            extensionAttribute11 = $UserExtensionAttribute.extensionAttribute11
            extensionAttribute12 = $UserExtensionAttribute.extensionAttribute12
            extensionAttribute13 = $UserExtensionAttribute.extensionAttribute13
            extensionAttribute14 = $UserExtensionAttribute.extensionAttribute14
            extensionAttribute15 = $UserExtensionAttribute.extensionAttribute15
        }
        Write-Host "Writing $User to file to export"

    }
    catch{
    
        Write-Host "Failed to write $User to file to export" -ForegroundColor Red
    
    }
    

}

}


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
                        $BulkOnPremExtAttribute | Export-Csv -Path "$ENV:USERPROFILE\Downloads\$csvname.csv" -NoTypeInformation -ErrorAction Stop
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