function Start-EzAPReprocessing {

	Start-Process "$env:USERPROFILE\Documents\EntraController\AccessPackages\Start-EzAPReprocessing.csv"

	while (-not $Confirmed) {

		try {
			$P = Read-Host "Please input the access package NAME into the provided csv template and save it. Once ready, type 'Y' to continue or 'Q' to quit."

			switch ($P.ToUpper()) {
				"Y" {
					$aps = Import-Csv "$env:USERPROFILE\Documents\EntraController\AccessPackages\Start-EzAPReprocessing.csv" -ErrorAction Stop
					$Confirmed = $true
					continue
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

	foreach ($ap in $aps.AccessPackageName) {

        $ap = $ap.Trim() # Remove any leading/trailing whitespace
		Write-Host "Processing access package: $ap" -ForegroundColor Cyan
		$accessPackage = Get-MgEntitlementManagementAccessPackage `
		  -Filter "displayName eq '$ap'"

		# Get all assignments for the access package
		$assignments = Get-MgEntitlementManagementAssignment -AccessPackageId $($accessPackage.Id)

		Write-Host "Reprocessing $($assignments.Count) user assignments for access package: $ap" -ForegroundColor Green

		# Reprocess every assignment
		foreach ($a in $assignments) {

			$uri = "https://graph.microsoft.com/v1.0/identityGovernance/entitlementManagement/assignments/$($a.Id)/reprocess"
            
			Invoke-MgGraphRequest -Method POST -Uri $uri -ErrorAction Stop
            
			Write-Host "Reprocessed assignment: $($a.Id)" -ForegroundColor Cyan

		}
	}
}