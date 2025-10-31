
function Update-EzEntraDependencies {
#Module update function for Ez Entra Tools dependencies
$ModuleDependencies = @(
        #"Microsoft.Entra",
        "Az.Resources",
        "Az.Accounts",
        "Az.KeyVault",
        "Microsoft.Graph.Authentication", 
        "Microsoft.Graph.Groups",
        "Microsoft.Graph.Users",
        "ImportExcel",
        "Microsoft.Graph.Applications",
        "Microsoft.Graph.Identity.DirectoryManagement"
    )

#$AvailableModules =  Get-Module -ListAvailable

Foreach ($Module in $ModuleDependencies){

    try {

        Update-Module -Name $Module -Force

        Write-Host "Updating module: $Module" -ForegroundColor Green

            try {
                Import-Module $Module -Force    
                Write-Host "Importing module: $Module" -ForegroundColor Green

            }
            catch {
                Write-Host "An error occurred while importing module: $Module. Error details: $_" -ForegroundColor Red
            }

    }
    catch {
        Write-Host "An error occurred while updating module: $Module. Error details: $_" -ForegroundColor Red
    }

}

Write-Host "All module updates attempted. Please close out of powershell completely, re-import the Ez Entra tools module" -ForegroundColor Cyan
Write-Host "to import the module run the following command in powershell 7: Import-Module $env:USERPROFILE\Documents\EntraController\EzEntraTools.psm1 -Force" -ForegroundColor Green
Write-Host "Then run Start-EzEntraController to begin using the tool." -ForegroundColor Green


}








