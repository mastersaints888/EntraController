# add users to ap by admin assingment


function New-EzAPUserAdminAssignment {

# add users to ap by admin assingment

Start-Process "$env:USERPROFILE\Documents\EntraController\AccessPackages\New-EzAPUserAssignmentAdminAdd.csv"

while (-not $Confirmed) {

	try {
		$P = Read-Host "Please input the access package assignments into the provided csv template and save it. Once ready, type 'Y' to continue or 'Q' to quit."

		switch ($P.ToUpper()) {
			"Y" {
				$APassignments = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\AccessPackages\New-EzAPUserAssignmentAdminAdd.csv" -ErrorAction Stop
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

$policyfilter = @()

#Get AP ID
foreach ($AP in $APassignments) {
	try {
		$accessPackage = Get-MgEntitlementManagementAccessPackage -Filter "displayName eq '$($AP.AccessPackageName.trim())'" -ErrorAction Stop
		$accessPackageId = $accessPackage.Id
	} catch {
		Write-Host "An error occurred while retrieving access package information for '$($AP.AccessPackageName)': $_" -ForegroundColor Red
		continue
	}

	#Get Policy Assignment
	# Replace with your access package ID
	$accessPackageId = $accessPackageId

	try {
		$policies = Invoke-MgGraphRequest -Method GET -Uri "https://graph.microsoft.com/v1.0/identityGovernance/entitlementManagement/assignmentPolicies?`$filter=accessPackage/id eq '$accessPackageId'"

		$policyfilter += $policies.value | Select-Object id, displayName

		$policyfilter | add-member NoteProperty -Name "AccessPackageName" -Value $AP.AccessPackageName -ErrorAction Ignore
	} catch {
		Write-Host "An error occurred while retrieving policies for access package '$($AP.AccessPackageName)': $_" -ForegroundColor Red
		continue
	}
}

#run this for each user to add them to the access package via admin assignment
foreach ($user in $APassignments) {
	try {
		$UObject = Get-MgUserByUserPrincipalName -UserPrincipalName $user.userPrincipalName.trim() -ErrorAction Stop
		$accessPackage = Get-MgEntitlementManagementAccessPackage -Filter "displayName eq '$($user.AccessPackageName.trim())'" -ErrorAction Stop
		$accessPackageId = $accessPackage.Id
	} catch {
		Write-Host "An error occurred while retrieving user or access package information for '$($user.userPrincipalName)' and access package '$($user.AccessPackageName)': $_" -ForegroundColor Red
		continue
	}

	#filter for policy ID
	$AccessPackagePolicyId = $null
	$AccessPackagePolicyId = $policyfilter | Where-Object { $_.displayName -eq $user.AccessPackagePolicyName.trim() } | select-object -ExpandProperty id -First 1

	$params = @{
		requestType = "adminAdd"
		assignment = @{
			targetId = "$($UObject.Id)"
			assignmentPolicyId = "$AccessPackagePolicyId"
			accessPackageId = "$accessPackageId"
		}
	}

	Write-Host "Assigning $($user.userPrincipalName) to $($user.AccessPackageName) with policy $($user.AccessPackagePolicyName)"
	try {
		New-MgEntitlementManagementAssignmentRequest -BodyParameter $params -ErrorAction Stop
	} catch {
		Write-Host "An error occurred while assigning $($user.userPrincipalName) to $($user.AccessPackageName): "$_.Exception -ForegroundColor Red
	}

}

}