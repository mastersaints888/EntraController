
$GroupToQuery = Read-Host "Please input the name of the group of users you want to pull group memberships for: "

$GroupId = (Get-MgGroup -Filter "displayName eq '$GroupToQuery'").Id

$Users = Get-MgGroupMemberAsUser -GroupId $GroupId -All

$FinalExport = @()

foreach($User in $Users){

$Groups = @()
$GroupIds = @()

$GroupIds = Get-MgUserMemberOfAsGroup -UserId $User.Id 

$Groups = $GroupIds | ForEach-Object { Get-MgGroup -GroupId $_.Id }




foreach ($Group in $Groups){

    

    $FinalExport += [PSCustomObject]@{
        UserInGroup = $User.UserPrincipalName
        GroupDisplayName = $Group.DisplayName
        GroupTypes = foreach ($Type in $Group.GroupTypes){ $Type -join ","}
        Id = $Group.Id
        OnPrem = $Group.OnPremisesSyncEnabled 
    }

}


}

$FinalExport | Export-Csv -Path "$ENV:USERPROFILE/Downloads/E2CGroupMembers.csv"

$OUTPUT = @()

$StringCommands | Foreach-Object {

    $OUTPUT += [PSCustomObject]@{
        Name = $_
    }
}