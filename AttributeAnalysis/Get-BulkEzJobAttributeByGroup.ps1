function Get-EzJobAttributeByGroup {

	$ContinueLoop = $true

	while ($ContinueLoop -eq $true) {
		Write-Host "1.) Get attributes for all users in a SINGLE group"
		Write-Host "2.) Get attributes for all users in MULTIPLE groups via a csv input template"
		Write-Host "X.) Return to menu"
		$UserSelection = Read-Host "Select an option (1 or 2)"

		if ($UserSelection -ne "1" -and $UserSelection -ne "2" -and $UserSelection.ToUpper() -ne "X") {
			Write-Host "Invalid selection. Please select either option 1 or option 2." -ForegroundColor Red
			$ContinueLoop = $true
		} if ($UserSelection -eq "X") {
			Write-Host "Returning to menu..." -ForegroundColor Yellow
			return
		}
		else { $ContinueLoop -eq $false }

		$Users = @()

		Switch ($UserSelection) {

			"1" {
				$Group = Read-Host "Please input the name of the group in which you would like to pull user attributes for"

				try {
					$MgGroup = Get-MgGroup -Filter "displayName eq '$Group'" -ErrorAction Stop

					if (-not $MgGroup) {
						Write-Host "Group '$Group' was not found. Please check the name and try again." -ForegroundColor Red
						return
					}

					$MgGroup | ForEach-Object {
						$GroupId = $_.Id
						$GroupMembers = Get-MgGroupMemberAsUser -All -GroupId $GroupId -ErrorAction Stop
						foreach ($Member in $GroupMembers) {
							$Users += [PSCustomObject]@{
								userPrincipalName = $Member.UserPrincipalName
							}
						}
					}
				}
				catch {
					Write-Host "Failed to retrieve group members for '$Group' : " -ForegroundColor Yellow
					Write-Host $_.Exception.Message -ForegroundColor Red
				}

				$Report = @()
				foreach ($User in $Users) {
					$Report += Get-EzJobAttribute -BulkGroup -UserUPN $User.userPrincipalName
					Write-Host "Pulling attributes for $($User.userPrincipalName)" -ForegroundColor Green
				}

				$Report | Format-List

				$PullReport = Read-Host "Would you like to export the report to a csv file? (Y/N)"

				Switch ($PullReport.ToUpper()) {
					"Y" {
						$ReportName = Read-Host "Please provide a name for the report (without file extension like .csv)"
						try {
							$Report | Export-Csv -Path "$env:USERPROFILE\Downloads\$ReportName.csv" -NoTypeInformation -ErrorAction Stop
							Write-Host "Report exported to $env:USERPROFILE\Downloads\$ReportName.csv" -ForegroundColor Green
						}
						catch {
							Write-Host "Failed to export report : " -ForegroundColor Yellow
							Write-Host $_.Exception.Message -ForegroundColor Red
						}
					}
					"N" {
						Write-Host "Report not exported. Ending script." -ForegroundColor Yellow
					}
					default {
						Write-Host "Invalid input. Please type 'Y' to export the report or 'N' to skip exporting." -ForegroundColor Red
					}
				}
			}

			"2" {
				try {
					Start-Process "$ENV:USERPROFILE\Documents\EntraController\AttributeAnalysis\BulkJobAttributesByGroup.csv" -ErrorAction Stop
				}
				catch {
					Write-Host "Failed to open csv template : " -ForegroundColor Yellow
					Write-Host $_.Exception.Message -ForegroundColor Red
				}

				while (-not $Confirmed) {

					try {
						$P = Read-Host "Please input the groups of users into the provided csv template and save it. Once ready, type 'Y' to continue or 'Q' to quit."

						switch ($P.ToUpper()) {
							"Y" {
								$Groups = Import-Csv -Path "$env:USERPROFILE\Documents\EntraController\AttributeAnalysis\BulkJobAttributesByGroup.csv" -ErrorAction Stop
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

				try {
					Foreach ($Group in $Groups.GroupName) {
						$MgGroup = Get-MgGroup -Filter "displayName eq '$Group'" -ErrorAction Stop

						if (-not $MgGroup) {
							Write-Host "Group '$Group' was not found. Skipping." -ForegroundColor Red
							continue
						}

						$MgGroup | ForEach-Object {
							$GroupId = $_.Id
							$GroupMembers = Get-MgGroupMemberAsUser -All -GroupId $GroupId -ErrorAction Stop
							foreach ($Member in $GroupMembers) {
								$Users += [PSCustomObject]@{
									userPrincipalName = $Member.UserPrincipalName
								}
							}
						}
					}
				}
				catch {
					Write-Host "Failed to retrieve group members for '$Group' : " -ForegroundColor Yellow
					Write-Host $_.Exception.Message -ForegroundColor Red
				}

				$Report = @()
				foreach ($User in $Users) {
					$Report += Get-EzJobAttribute -BulkGroup -UserUPN $User.userPrincipalName
					Write-Host "Pulling attributes for $($User.userPrincipalName)" -ForegroundColor Green
				}

				$Report | Format-List

				$PullReport = Read-Host "Would you like to export the report to a csv file? (Y/N)"

				Switch ($PullReport.ToUpper()) {
					"Y" {
						$ReportName = Read-Host "Please provide a name for the report (without file extension like .csv)"
						try {
							$Report | Export-Csv -Path "$env:USERPROFILE\Downloads\$ReportName.csv" -NoTypeInformation -ErrorAction Stop
							Write-Host "Report exported to $env:USERPROFILE\Downloads\$ReportName.csv" -ForegroundColor Green
						}
						catch {
							Write-Host "Failed to export report : " -ForegroundColor Yellow
							Write-Host $_.Exception.Message -ForegroundColor Red
						}
					}
					"N" {
						Write-Host "Report not exported. Ending script." -ForegroundColor Yellow
					}
					default {
						Write-Host "Invalid input. Please type 'Y' to export the report or 'N' to skip exporting." -ForegroundColor Red
					}
				}
			}

			"Q" {
				Write-Host "Returning to menu..." -ForegroundColor Yellow
				return
			}

		}

	}

}