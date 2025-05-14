function Import-EzModules {

    $ModuleDependencies = @(
        #"Microsoft.Entra",
        "Az.Resources",
        "Az.Accounts",
        "Microsoft.Graph.Authentication", 
        "Microsoft.Graph.Groups"
    )

    foreach ($Module in $ModuleDependencies) {
        try {
            $installed = Get-InstalledModule -Name $Module -ErrorAction SilentlyContinue

            if (-not $installed) {
                Write-Host "Installing missing module: $Module" -ForegroundColor Yellow
                Install-Module -Name $Module -Force -AllowClobber -ErrorAction Stop
            }
            else {
                # Check if update is available
                $latest = Find-Module -Name $Module
                if ($installed.Version -lt $latest.Version) {
                    Write-Host "Updating module: $Module ($($installed.Version) → $($latest.Version))" -ForegroundColor Cyan
                    Update-Module -Name $Module -Force -ErrorAction Stop
                }
                else {
                    Write-Host "Module $Module is up-to-date ($($installed.Version))" -ForegroundColor Green
                }
            }

            Write-Host "Importing module: $Module" -ForegroundColor Green
            Import-Module $Module -ErrorAction Stop
        }
        catch {
            Write-Warning "An error occurred with module '$Module': $_"
        }
    }

    try {
        Write-Host "Connecting to Entra ID, Graph, and Az..." -ForegroundColor Green
        #Connect-Entra -Scopes 'User.Read.All', 'Group.ReadWrite.All'
        Connect-MgGraph -Scope 'User.ReadWrite.All', 'Directory.Read.All', 'Group.ReadWrite.All'
        Connect-AzAccount -UseDeviceAuthentication
    }
    catch {
        Write-Warning "Error during service connections: $_"
    }
}


Import-EzModules 


