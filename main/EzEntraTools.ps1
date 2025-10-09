function Import-EzModuleDependencies {

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
        Connect-MgGraph -Scope 'User.ReadWrite.All', 'Directory.ReadWrite.All', 'Group.ReadWrite.All', 'Application.ReadWrite.All'
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
. "$BasePath\Groups\New-EzGroups.ps1"

# Users
. "$BasePath\Users\New-EzBulkEntraUser.ps1"

#Service Principals
. "$BasePath\ServicePrincipals\Set-EzGroupSp.ps1"


Import-EzModuleDependencies




function Start-EzEntraController {

    #Rbac module selection
    function Start-EzRbac {

        $UserConfirm = $false

        while($UserConfirm -eq $false){
            
            Write-Host "1) Pull Rbac Report"
            Write-Host "2) Design Bulk Rbac Infrastructure"
            $UserSelection = Read-Host "Select an Option, press X to return to the main menu"
            switch($UserSelection){
                "1" {Get-EzRbacReport}
                "2" {Set-EzBulkRbac}
                "X" {$UserConfirm = $true}
            }
            
        }

    }

        #Attribute module selection
    function Start-EzAttributes {

        $UserConfirm = $false

        while($UserConfirm -eq $false){
            
            Write-Host "1) Get Entra Job Attributes - (JobTile, CompanyName etc...)"
            Write-Host "2) Get Entra Identity Attributes - (UPN, PasswordLastset, UserType etc...)"
            Write-Host "3) Get Entra Contact Info Attributes - (Address, PhoneNumber etc...)"
            Write-Host "4) Get OnPrem Attributes - (SyncStatus, Immutable Ids etc...)"
            Write-Host "5) Get OnPrem Extension Attributes - (ExtensionAttribute 1, 2, 3 etc...)"
            $UserSelection = Read-Host "Select an Option, press X to return to the main menu"
            switch($UserSelection){
                "1" { Get-EzJobAttribute }
                "2" { Get-EzIdentityAttribute }
                "3" { Get-EzContactInfo }
                "4" { Get-EzOnPremAttribute }
                "5" { Get-EzOnPremExtAttribute }
                "X" {$UserConfirm = $true}
            }
            
        }

    }


       #Groups module selection
    function Start-EzGroups {

        $UserConfirm = $false

        while($UserConfirm -eq $false){
            
            Write-Host "1) Create a dynamic group with logic"
            Write-Host "2) Design out bulk dynamic group infrastructure"
            Write-Host "3) Create Bulk Basic Security Groups (Can be role assignable)"
            $UserSelection = Read-Host "Select an Option, press X to return to the main menu"
            switch($UserSelection){
                "1" { New-EzDynamicGroup }
                "2" { New-BulkDynamicGroup }
                "3" { New-EzGroups }
                "X" {$UserConfirm = $true}
            }
            
        }

    }



     #Groups module selection
    function Start-EzUsers {

        $UserConfirm = $false

        while($UserConfirm -eq $false){
            
            Write-Host "1) Create bulk users"
            $UserSelection = Read-Host "Select an Option, press X to return to the main menu"
            switch($UserSelection){
                "1" { New-EzBulkUser }
                "X" {$UserConfirm = $true}
            }
            
        }

    }



    
    function Start-EzLicenses {

        $UserConfirm = $false

        while($UserConfirm -eq $false){
            
            Write-Host "1) Get your Tenants License Information"
            Write-Host "2) Design out Enterprise License Groups"
            $UserSelection = Read-Host "Select an Option, press X to return to the main menu"
            switch($UserSelection){
                "1" { Get-EzLicense }
                "2" { Set-EzLicenseGroup }
                "X" {$UserConfirm = $true}
            }
            
        }

    }




    
     
    function Start-EzKeyVaults {

        $UserConfirm = $false

        while($UserConfirm -eq $false){
            
            Write-Host "1) Create, Manage and Update KeyVault Keys"
            $UserSelection = Read-Host "Select an Option, press X to return to the main menu"
            switch($UserSelection){
                "1" { Set-EzKeyVaultSecret }
                "X" {$UserConfirm = $true}
            }
            
        }

    }



    function Start-EzGraphContext {

        $UserConfirm = $false

        while($UserConfirm -eq $false){
            
            Write-Host "1) Show Azure Sub (Az) Context"
            Write-Host "2) Change Azure Sub (Az) Context - Change Subscription"
            Write-Host "3) Show Microsoft Graph Context"
            Write-Host "4) Change Microsoft Graph Context - Change Tenant"
            $UserSelection = Read-Host "Select an Option, press X to return to the main menu"
            switch($UserSelection){
                "1" { swc -show }
                "2" { swc }
                "3" { con -mgc }
                "4" { con -mgs }
                "X" {$UserConfirm = $true}
            }
            
        }

    }



    function Start-EzServicePrincipals {

        $UserConfirm = $false

        while($UserConfirm -eq $false){
            
            Write-Host "1) Add Groups to Enterprise applications"
            $UserSelection = Read-Host "Select an Option, press X to return to the main menu"
            switch($UserSelection){
                "1" { Set-EzGroupSp }
                "X" {$UserConfirm = $true}
            }
            
        }

    }

    

while ($true) {
    Clear-Host
    Write-Host "===== Entra Controller ====="
    Write-Host "1) User Attributes"
    Write-Host "2) Users"
    Write-Host "3) Groups"
    Write-Host "4) Licenses"
    Write-Host "5) Key Vault Management"
    Write-Host "6) RBAC Management"
    Write-Host "7) Check Azure and Graph Contexts"
    Write-Host "8) Service Principals and Apps"
    Write-Host "X) Exit"
    $choice = Read-Host "Select an option"

    switch ($choice) {
        "1" { Start-EzAttributes }
        "2" { Start-EzUsers }
        "3" { Start-EzGroups }
        "4" { Start-EzLicenses }
        "5" { Start-EzKeyVaults }
        "6" { Start-EzRbac }
        "7" { Start-EzGraphContext }
        "8" { Start-EzServicePrincipals }
        "X" { return }
        default { Write-Host "Invalid option, try again." }
    }
    Pause
}




}

