function Get-EzAccessReviewStatus {

$uri = "https://graph.microsoft.com/v1.0/identityGovernance/accessReviews/definitions"
$definitions = Invoke-MgGraphRequest -Method "GET" -Uri $uri

# View the results
$PolicyDefs = $definitions.value

$Output = @()
$SortedPolicyDefs = $PolicyDefs | Select-Object id, displayName, descriptionForAdmins, status

    foreach ($def in $SortedPolicyDefs) {
        
        $Output += [PSCustomObject]@{
            "Status" = $def.status
            "Access Review Name" = $def.displayName
            "Description" = $def.descriptionForAdmins     
        }
    }
    Start-Sleep -Seconds 1
    return $Output
    
}