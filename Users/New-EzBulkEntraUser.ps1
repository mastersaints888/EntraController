
function New-EzBulkUser {
    [CmdletBinding()]
    param(
        [switch]$DryRun

    )


$Users = import-csv -path "$ENV:USERPROFILE\Documents\EntraController\Users\users.csv"




foreach($User in $Users){

    #Check if acct enabled 
    switch($User.AccountEnabled){
        "TRUE" { $accountEnabled = $true}
        "FALSE" { $accountEnabled = $false}
    }

    try{
        $PasswordProfile = @{
        Password = $User.Password
    }

    #Generate unique mail Nickname
    $mailNickNameBase = ($User.FirstName + $User.LastName).ToLower()
    $uniqueMailNickName = $mailNickNameBase
    $i = 1

    while (Get-MgUser -Filter "mailNickname eq '$uniqueMailNickName'" -ErrorAction SilentlyContinue) {
    $uniqueMailNickName = "$mailNickNameBase$i"
    $i++
    }


    #used like a whatif command
    if($DryRun){
        Write-Host -ForegroundColor Yellow `
        "[DryRun] New User Create - UserPrincipalName:" $User.userPrincipalName "DisplayName:" $User.DisplayName "AccountEnabled:" $User.AccountEnabled
           
    }
    else{

        Write-Host -ForeGroundColor Green "Creating user..." $User.Displayname

        New-MgUser -UserPrincipalName $User.'userPrincipalName' `
                   -DisplayName $User.DisplayName `
                   -PasswordProfile $PasswordProfile `
                   -AccountEnabled:$accountEnabled `
                   -MailNickName $uniqueMailNickName `
                   -GivenName $User.FirstName `
                   -Surname $User.LastName `
                   -JobTitle $User.JobTitle `
                   -CompanyName $User.CompanyName `
                   -Department $User.Department `
                   -UserType $User.UserType `
                   -EmployeeType $User.EmployeeType `
                   -UsageLocation $User.UsageLocation

        }
    }
    catch{
        Write-Host "Error Creating User:" $_.Exception.Message
    }
}

}



