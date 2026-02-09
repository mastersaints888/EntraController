function New-EzAccessPackages {

$Confirm = $False


While($Confirm -eq $False){

    Write-Host "Please select if you would like to create a single Access Package or many access packages in bulk. type Q to quit"
    Write-Host "1.) Create a single AP"
    Write-Host "2.) Create many APs in bulk using a CSV file"
    $Selection = Read-Host "Please select and option"

    switch($Selection){
        
        #single action 
        "1"{
            #Grabbing the Catalog ID
            $catalogFilter = Read-Host "Please enter the name of the catalog that this access package should be created in"
            try {
                #Grab catalog from MS Graph, if it doesn't exist throw an error
                $catalog = Get-MgEntitlementManagementCatalog -DisplayNameEq $catalogFilter -All -expandProperty resources,accessPackages -ErrorAction Stop
                $catalogId = $catalog.Id
            }
            catch {
                Write-Host -ForegroundColor Red "An error occurred while retrieving the catalog: $($_.Exception)"
            }
            

            #access package name / description variables 
            $accessPackageName = Read-Host "Please enter the name of the access package you want to create"
            $accessPackageDescription = Read-Host "Please enter a description for the access package you want to create"
            $accessPackageHidden = $false

            $accessPackageParams = @{
                displayName = $accessPackageName
                description = $accessPackageDescription
                isHidden = $accessPackageHidden
                catalog = @{
                    id = $catalog.id
                }
            }

            #creating the access package 
            try {
                $createErr = $null
                $accessPackage = New-MgEntitlementManagementAccessPackage -BodyParameter $accessPackageParams -ErrorVariable createErr -ErrorAction Stop
                
                if ($createErr.Count -eq 0) {
                    Write-Host -ForegroundColor Green "Successfuly created access package $($accessPackage.displayName)"
                    $accessPackageId = $accessPackage.Id
                } else {
                    Write-Error ("Failed to create access package: {0}" -f ($createErr[0].Exception.Message))
                }
            }
            catch {
                Write-Host -ForegroundColor Red "An error occured while creating the AP" $_.Exception
            }
        }
        # Bulk action
        "2"{
            #open csv for edits
            Start-Process -Path "$ENV:USERPROFILE\Documents\EntraController\AccessPackages\New-EZAccessPackage.csv"
            
                #Confirm if user wants to proceed loop
                $AccessPackageCreateConfirmation = $false

                While($AccessPackageCreateConfirmation -eq $false){

                    $Selection2 = Read-Host "Please type Y to [confirm] C to [DryRun] or Q to quit"

                        switch ($Selection2) {
                            "Y" {
                                Write-Host -ForegroundColor Yellow "Proceeding with Access Package Creation"

                                #Import CSV of APs user wishes to create and loop through and create them 
                                $AccessPackages = Import-Csv -Path "$ENV:USERPROFILE\Documents\EntraController\AccessPackages\New-EZAccessPackage.csv"

                                    foreach ($AP in $AccessPackages){
                                        #Grabbing the Catalog ID
                                        $catalogFilter = $AP.catalogName.trim()

                                        try {
                                            $catalog = Get-MgEntitlementManagementCatalog -DisplayNameEq $catalogFilter -All -expandProperty resources,accessPackages -ErrorAction Stop
                                            $catalogId = $catalog.Id
                                        }
                                        catch {
                                            Write-Host -ForegroundColor Red "An error occurred while retrieving the catalog: $($_.Exception)"
                                        }
                                        

                                        #access package name / description variables 
                                        $accessPackageName = $AP.accessPackageName.trim()
                                        $accessPackageDescription = $AP.accessPackageDescription
                                        $accessPackageHidden = $false

                                        $accessPackageParams = @{
                                            displayName = $accessPackageName
                                            description = $accessPackageDescription
                                            isHidden = $accessPackageHidden
                                            catalog = @{
                                                id = $catalog.id
                                            }
                                        }

                                        #creating the access package 
                                        try {
                                            $createErr = $null
                                            $accessPackage = New-MgEntitlementManagementAccessPackage -BodyParameter $accessPackageParams -ErrorVariable createErr -ErrorAction Stop
                                            
                                            if ($createErr.Count -eq 0) {
                                                Write-Host -ForegroundColor Green "Successfully created access package $($accessPackage.displayName)"
                                                $accessPackageId = $accessPackage.Id
                                            } else {
                                                Write-Error ("Failed to create access package: {0}" -f ($createErr[0].Exception.Message))
                                            }
                                        }
                                        catch {
                                            Write-Host -ForegroundColor Red "An error occurred while creating the AP: $($_.Exception)"
                                        }
                                    }
                                
                                $AccessPackageCreateConfirmation = $true
                            } 
                            
                            "C" {
                                Write-Host -ForegroundColor Yellow "Performing DryRun, will NOT apply"
                                $APDryRun = Import-Csv -Path "$ENV:USERPROFILE\Documents\EntraController\AccessPackages\New-EZAccessPackage.csv"

                                    #Run through the csv to show user what will be created
                                    $outputtable = @()
                                    $APDryRun | ForEach-Object {
                                        $outputtable += [PSCustomObject]@{
                                            catalog = $_.catalogName
                                            accessPackageName = $_.accessPackageName
                                            Description = $_.accessPackageDescription
                                            DryRun = $true
                                        }
                                    }

                                $outputtable | Format-Table


                            }
                            
                            "Q" { 
                                Write-Host -ForegroundColor Yellow "Exiting script...."
                                $AccessPackageCreateConfirmation = $true
                                
                            }
                            default {
                                Write-Host -ForegroundColor Red "Invalid selection, please try again"
                            }
                        }
                        
                        
                    }
            }
        "Q"{
            Write-Host -ForegroundColor Yellow "Exiting script...."
            $Confirm = $true
        }
         default {
            Write-Host -ForegroundColor Red "Invalid selection, please try again"
        }
    }
}      
 
}