
function New-BulkDynamicGroup {

#Import-Module -Name ImportExcel

#open excel file for user to edit
Start-Process "$env:USERPROFILE\Documents\EntraController\Groups\DynamicGroupDbExcel.xlsx"

Write-Host -ForegroundColor Yellow "Attempting to open up excel Dynamic groups database..."

#set confirmation for breaking the loop if Y is selected
$Confirmed = $false

#user prompt
    while (-not $Confirmed) {
       
        
        try {

            $P = Read-Host "Please build out your dynamic group queries. When done, save the xslx and exit. Type Y when finished (or type Q to quit)"

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


#convert the excel to a csv 
Import-Excel -Path "$env:USERPROFILE\Documents\EntraController\Groups\DynamicGroupDbExcel.xlsx" | `
Export-Csv -Path "$env:USERPROFILE\Documents\EntraController\Groups\DynamicGroupDb.csv" -NoTypeInformation
#import users config

#White Space Trimming 

$CsvData = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\Groups\DynamicGroupDb.csv"

function Trim-CsvContent {
    param (
        [Parameter(Mandatory)]
        [array]$CsvData
    )

    foreach ($row in $CsvData) {
        foreach ($prop in $row.PSObject.Properties) {
            # Force value to string, then trim it
            $stringValue = [string]::Copy($prop.Value)
            $prop.Value = $stringValue.Trim()
        }
    }

    return $CsvData
}


$DGs = Trim-CsvContent -CsvData $CsvData

#Display groups to user
foreach($group in $DGs){

    Write-Host -ForegroundColor Yellow $group.DisplayName "|" $group.GroupQuery
}


#set confirmation for breaking the loop if Y is selected
$Confirmed = $false

#Display the users groups they created for confirmation
while(-not $Confirmed){

    $P = Read-Host "Please confirm the group queries shown before proceeding (Y to confirm Q to quit)"

    try {
        switch($P.ToUpper()) {

            "Y" { 
                write-host -ForegroundColor Green "Proceeding with script..."
                $Confirmed = $true
            }

            "Q" { 

                Write-Host -ForegroundColor Yellow "Exiting script..."
                return 

            }

            else{ 

                write-host "Not a valid option, please input Y(proceed) or Q(quit)"
            }

        }
    }
    catch {
        
        write-host -ForegroundColor Red "An error occured $_"
    }
}



foreach ($group in $DGs) {
    try {

        # Cast string values to boolean
        $mailEnabled = [System.Convert]::ToBoolean($group.MailEnabled)
        
        #$mailEnabled = $group.MailEnabled
        
        $securityEnabled = $true  

        #Clean DisplayName: remove non-alphanumerics and compress spaces
        $baseNickname = ($group.DisplayName -replace '[^a-zA-Z0-9]', '') 
        $mailNickname = "$baseNickname$(Get-Random -Minimum 1000 -Maximum 9999)"

        
        # Grab rule per group for imported object
        $memRule = $group.GroupQuery
        
        #group creation 
        $newGroup = New-MgGroup -DisplayName $group.DisplayName -MailEnabled:$mailEnabled `
            -MailNickname $mailNickname `
            -SecurityEnabled:$securityEnabled `
            -GroupTypes @("DynamicMembership") `
            -MembershipRuleProcessingState "On" `
            -MembershipRule $memRule


            $newGroup.Id


        Write-Host "Created group: $($group.DisplayName) with rule $($memRule)" -ForegroundColor Green
    }

    catch {

        Write-Host "Error creating group '$($group.DisplayName)': $_" -ForegroundColor Red


    }
}

}