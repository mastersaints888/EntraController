function New-EzGroups {

#Permissions Check 
 try {
    
    if(-not (Connect-MgGraph -Scope RoleManagement.ReadWrite.Directory)){
        Write-Host -ForegroundColor Red -BackgroundColor Yellow "[WARNING] If you would like to create groups with Roles the caller will need at least Privileged Role Administrator in Entra ID, You dont have this permission currently."
        Write-Host -ForegroundColor Red "[NOTE] If you do not need this permission YOU CAN ONLY CREATE NON ROLE ASSIGNABLE GROUPS!"
    }else{
        Write-Host -ForegroundColor Green "Successfully connected with Role Assignment Privileges"
    }
}
catch{
    Write-Host "An error occured when attempting to connect to microsoft graph..." $_
}
  

Write-Host -ForegroundColor Yellow "Attempting to open bulk group creator csv..."

Start-Process -FilePath "$env:USERPROFILE\Documents\EntraController\Groups\groups.csv"

$Confirmed = $false

while (-not $Confirmed) {
       
        
        try {

            $P = Read-Host "Please build out your security groups, save the csv and exit the csv. type C to dryrun type Y to confirm (or type Q to quit)"

            $csv = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\Groups\groups.csv"

            Write-Host -ForegroundColor Yellow "[CONFIRM] This will create the following groups..."


            switch ($P.ToUpper()) {
                
                "Y" {
                    Write-Host "Proceeding with script..." -ForegroundColor Green
                    $Confirmed = $true
                }
                "Q" {
                    Write-Host "Exiting script. Goodbye!" -ForegroundColor Yellow
                    exit
                }
                "C" {
                        foreach($group in $csv){
                            write-host "[CONFIRM] This will create the group" $group.DisplayName
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




try {

    $csv | ForEach-Object {

    $MailNickName = ($_.DisplayName) + (Get-Random -Minimum 1000 -Maximum 99999)

    $DisplayName = $_.DisplayName.Trim()
    $MailNickName = $MailNickName.Trim()
    $IsAssignableToRole = [System.Convert]::ToBoolean($_.IsAssignableToRole.Trim())
    $MailEnabled = $false

   


    New-MgGroup -DisplayName $DisplayName `
    -MailEnabled:$MailEnabled `
    -MailNickName $MailNickName `
    -SecurityEnabled `
    -IsAssignableToRole:$IsAssignableToRole

    Write-Host -ForeGroundColor Yellow "[CREATE] Creating group:" $_.DisplayName

    }
}
catch {
    Write-Host "An error occured while creating group" $_.DisplayName $_.Exception
}


}



