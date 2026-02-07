# Script to pull all group memberships for users either from a specified Entra (Azure AD) group
# or from a custom CSV list of userPrincipalNames. Prompts the user and optionally exports to CSV.

function Get-EzUserMemberOfGroups {

    Write-Host -ForegroundColor Yellow "Would you like to type in a group of users from entra? or would you like to create a custom list of users to pull groups for?"
    Write-Host "1) Input a group display name to pull all users in that group and their memberships"
    Write-Host "2) create/paste in a custom list of users in a CSV to pull group memberships for"

    $ConfirmReportType = $false

    # Main selection loop: keep asking until a valid selection is processed
    While ($ConfirmReportType -eq $false) {

        $ConfirmReportSelection = Read-Host "Please input 1 or 2 to select your report type, type Q to quit"

        switch ($ConfirmReportSelection) {

            "1" {

                $FinalExport = @()

                # Prompt for the group display name to query
                $GroupToQuery = Read-Host "Please input the name of the group of users you want to pull group memberships for: "

                # Retrieve the group Id for the provided display name (assumes unique displayName)
                try {
                    $GroupObj = Get-MgGroup -Filter "displayName eq '$GroupToQuery'" -ErrorAction Stop
                    if (-not $GroupObj) {
                        Write-Host -ForegroundColor Red "No group found with displayName '$GroupToQuery'. Please try again."
                        break
                    }
                    $GroupId = $GroupObj.Id
                }
                catch {
                    Write-Host -ForegroundColor Red "Failed to retrieve group '$GroupToQuery': $($_.exception)"
                    break
                }

                # Get all users in the group
                try {
                    $Users = Get-MgGroupMemberAsUser -GroupId $GroupId -All -ErrorAction Stop
                }
                catch {
                    Write-Host -ForegroundColor Red "Failed to retrieve members of group '$GroupToQuery': $($_.exception)"
                    break
                }

                $FinalExport = @()

                foreach ($User in $Users) {

                    $Groups = @()
                    $GroupIds = @()

                    # Get the group membership (as groups) for the current user
                    try {
                        $GroupIds = Get-MgUserMemberOfAsGroup -UserId $User.Id -ErrorAction Stop
                    }
                    catch {
                        Write-Host -ForegroundColor Yellow "Warning: Failed to retrieve memberships for user $($User.UserPrincipalName): $($_.exception)"
                        continue
                    }

                    # Resolve each group id to a group object
                    $Groups = $GroupIds | ForEach-Object {
                        try {
                            Get-MgGroup -GroupId $_.Id -ErrorAction Stop
                        }
                        catch {
                            Write-Host -ForegroundColor Yellow "Warning: Failed to resolve group Id $($_.Id): $($_.exception)"
                            $null
                        }
                    } | Where-Object { $_ -ne $null }

                    foreach ($Group in $Groups) {

                        # Normalize OnPremisesSyncEnabled to a boolean False if not True
                        $OnPrem = $Group.OnPremisesSyncEnabled
                        if ($OnPrem -ne $True) {
                            $OnPrem = $False
                        }

                        # Build output object for each user-group pair
                        $FinalExport += [PSCustomObject]@{
                            UserInGroup      = $User.UserPrincipalName
                            GroupDisplayName = $Group.DisplayName
                            GroupTypes       = ($Group.GroupTypes -join ",")
                            Id               = $Group.Id
                            OnPrem           = $OnPrem
                        }

                    }

                }

                # Show results in table format
                Write-Output $FinalExport | Format-Table

                $Confirm = $false

                # Prompt to export results to CSV
                While ($Confirm -eq $false) {

                    $Input = Read-Host "Do you wish to pull a report of this data to a CSV in your Downloads folder? (Y/N)"
                    $Input = $Input.ToUpper()

                    switch ($Input) {

                        "Y" {
                            $FileName = Read-Host "Please type in the name of the file (do not include csv)"
                            try {
                                $FinalExport | Export-Csv -Path "$ENV:USERPROFILE\Downloads\$FileName.csv" -NoTypeInformation -ErrorAction Stop
                                Write-Host -ForegroundColor Green "Exported to $ENV:USERPROFILE\Downloads\$FileName.csv"
                            }
                            catch {
                                Write-Host -ForegroundColor Red "Failed to export CSV: $($_.exception)"
                            }
                            $Confirm = $true
                        }

                        "N" {
                            Write-Host -ForegroundColor Yellow "Exiting script..."
                            $Confirm = $true
                            return
                        }

                        default {
                            Write-Host "Invalid input. Please type Y or N"
                            $Confirm = $false
                        }

                    }

                }

            }

            "2" {

                $FinalExport = @()
                Write-Host "Opening csv..."
                Write-Host -ForegroundColor Yellow "Please input the users into the csv in which you wish to pull group memberships for..."

                try {
                    Start-Process "$ENV:USERPROFILE\Documents\EntraController\Groups\PullUsersGroups.csv" -ErrorAction Stop
                }
                catch {
                    Write-Host -ForegroundColor Red "Failed to open CSV: $($_.exception)"
                    break
                }

                # set confirmation for breaking the loop if Y is selected
                $Confirmed = $false

                # Prompt user to finish editing the CSV and continue (or quit)
                while (-not $Confirmed) {

                    try {

                        $P = Read-Host "Please add in each user you would like to pull group memberships for. Type Y when finished (or type Q to quit)"

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
                        Write-Host "An error occurred: $($_.exception)" -ForegroundColor Red
                    }

                }

                # Import user list from CSV (expects a header like userPrincipalName)
                try {
                    $Users = Import-Csv -Path "$ENV:USERPROFILE\Documents\EntraController\Groups\PullUsersGroups.csv" -ErrorAction Stop
                }
                catch {
                    Write-Host -ForegroundColor Red "Failed to import CSV: $($_.exception)"
                    break
                }

                foreach ($User in $Users) {

                    # Replace the simple CSV row object with the full Mg user object for the given UPN
                    # Note: this overwrites $User for subsequent operations in this loop iteration
                    try {
                        $User = Get-MgUserByUserPrincipalName -UserPrincipalName $User.userPrincipalName -errorAction Stop
                    }
                    catch {
                        Write-Host -ForegroundColor Red "Warning: Failed to find user $($User.userPrincipalName): $($_.exception)"
                        continue
                    }

                    $Groups = @()
                    $GroupIds = @()

                    # Get group membership (as groups) for the current user
                    try {
                        $GroupIds = Get-MgUserMemberOfAsGroup -UserId $User.Id -ErrorAction Stop
                    }
                    catch {
                        Write-Host -ForegroundColor Red "Warning: Failed to retrieve memberships for user $($User.UserPrincipalName): $($_.exception)"
                        continue
                    }

                    # Resolve group ids to group objects
                    $Groups = $GroupIds | ForEach-Object {
                        try {
                            Get-MgGroup -GroupId $_.Id -ErrorAction Stop
                        }
                        catch {
                            Write-Host -ForegroundColor Yellow "Warning: Failed to resolve group Id $($_.Id): $($_.exception)"
                            $null
                        }
                    } 

                    foreach ($Group in $Groups) {

                        # Normalize OnPremisesSyncEnabled to a boolean False if not True
                        $OnPrem = $Group.OnPremisesSyncEnabled
                        if ($OnPrem -ne $True) {
                            $OnPrem = $False
                        }

                        # Build output object for each user-group pair
                        $FinalExport += [PSCustomObject]@{
                            UserInGroup      = $User.UserPrincipalName
                            GroupDisplayName = $Group.DisplayName
                            GroupTypes       = ($Group.GroupTypes -join ",")
                            Id               = $Group.Id
                            OnPrem           = $OnPrem
                        }

                    }

                }

                # Show results in table format
                Write-Output $FinalExport | Format-Table

                $Confirm = $false

                # Prompt to export results to CSV
                While ($Confirm -eq $false) {

                    $Input = Read-Host "Do you wish to pull a report of this data to a CSV in your Downloads folder? (Y/N)"
                    $Input = $Input.ToUpper()

                    switch ($Input) {

                        "Y" {
                            $FileName = Read-Host "Please type in the name of the file (do not include csv)"
                            try {
                                $FinalExport | Export-Csv -Path "$ENV:USERPROFILE\Downloads\$FileName.csv" -NoTypeInformation -ErrorAction Stop
                                Write-Host -ForegroundColor Green "Exported to $ENV:USERPROFILE\Downloads\$FileName.csv"
                            }
                            catch {
                                Write-Host -ForegroundColor Red "Failed to export CSV: $($_.exception)"
                            }
                            $Confirm = $true
                        }

                        "N" {
                            Write-Host -ForegroundColor Yellow "Exiting script..."
                            $Confirm = $true
                            return
                        }

                        default {
                            Write-Host "Invalid input. Please type Y or N"
                            $Confirm = $false
                        }

                    }

                }

            }

            "Q" {
                Write-Host "Exiting script. Goodbye!" -ForegroundColor Yellow
                $ConfirmReportType = $true
            }

            default {
                Write-Host -ForegroundColor Red "Invalid input. Please type 1 or 2 to select your report type. Or Q to quit"
                $ConfirmReportType = $false
            }

        } # end switch

    } # end while

}