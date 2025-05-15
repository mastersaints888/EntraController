function Import-EzModuleDependencies {

    $ModuleDependencies = @(
        #"Microsoft.Entra",
        "Az.Resources",
        "Az.Accounts",
        "Az.KeyVault",
        "Microsoft.Graph.Authentication", 
        "Microsoft.Graph.Groups",
        "Microsoft.Graph.Users",
        "ImportExcel"
    )

    foreach ($Module in $ModuleDependencies) {
        try {
            $installed = Get-InstalledModule -Name $Module -ErrorAction SilentlyContinue

            if (-not $installed) {
                Write-Host "Installing missing module: $Module" -ForegroundColor Yellow
                Install-Module -Name $Module -Force -AllowClobber -ErrorAction Stop
            }
                Write-Host "Importing module: $Module" -ForegroundColor Green
                Import-Module $Module -ErrorAction Stop
        }
        catch {
            Write-Warning "An error occurred with module '$Module': $_"
        }
    }

    try {
        Write-Host "Connecting to Graph, and Az..." -ForegroundColor Green
        #Connect-Entra -Scopes 'User.Read.All', 'Group.ReadWrite.All'
        Connect-MgGraph -Scope 'User.ReadWrite.All', 'Directory.Read.All', 'Group.ReadWrite.All'
        Connect-AzAccount 
    }
    catch {
        Write-Warning "Error during service connections: $_"
    }

}



# Set base path
$BasePath = "$env:USERPROFILE\Documents\EntraController"

# Dot-source function scripts from each folder

# AttributeAnalysis
. "$BasePath\AttributeAnalysis\Get-EzAttributeBulk.ps1"
. "$BasePath\AttributeAnalysis\Get-EzContactInfo.ps1"
. "$BasePath\AttributeAnalysis\Get-EzIdentityAttribute.ps1"
. "$BasePath\AttributeAnalysis\Get-EzJobAttribute.ps1"
. "$BasePath\AttributeAnalysis\Get-EzOnPremAttribute.ps1"
. "$BasePath\AttributeAnalysis\Get-EzOnPremExtAttribute.ps1"

# Licenses
. "$BasePath\Licenses\Get-EzLicense.ps1"

# SubsAndRBAC
. "$BasePath\SubsAndRBAC\Get-EzRbac.ps1"

# KeyVault
. "$BasePath\KeyVault\Set-EzKeyVaultSecret.ps1"

# Groups
. "$BasePath\Groups\New-BulkDynamicGroup.ps1"
. "$BasePath\Groups\New-DynamicGroup.ps1"

# Users
. "$BasePath\Users\New-EzBulkEntraUser.ps1"

Import-EzModuleDependencies