$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/mastersaints888/EntraController/archive/refs/heads/main.zip"
$installDir = "$env:USERPROFILE\Documents\EntraController"
$tempZip = Join-Path $env:TEMP "EntraController.zip"

Write-Host "Downloading EntraController..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip -UseBasicParsing

Write-Host "Extracting..." -ForegroundColor Cyan
Expand-Archive -Path $tempZip -DestinationPath $env:TEMP -Force

# Adjust this if your repo unzips with a different folder name
$extracted = Get-ChildItem "$env:TEMP" -Directory | Where-Object { $_.Name -like "*EntraController*" } | Select-Object -First 1

Write-Host "Installing to $installDir" -ForegroundColor Cyan
if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
Move-Item $extracted.FullName $installDir

Remove-Item $tempZip -Force

Write-Host "Installation complete!" -ForegroundColor Green

# Import the module so it’s ready
#Import-Module "$env:USERPROFILE\Documents\EntraController\EzEntraTools.psm1" -Force

# Display usage info
$Version = $PSVersionTable.PSVersion 
$DisplayVersion = $Version.Major, $Version.Minor -join '.'
Write-Host ""
Write-Host "To start EntraController:" -ForegroundColor Yellow
Write-Host "------------------------------------------------------------"
Write-Host "• PowerShell version detected: $DisplayVersion"
Write-Host "• You must use PowerShell 7 or higher."
Write-Host ""

# --- PowerShell 7 Check ---
$pwsh = Get-Command "pwsh.exe" -ErrorAction SilentlyContinue
if ($pwsh) {
    Write-Host "PowerShell 7 is installed on this system." -ForegroundColor Green
    Write-Host "You can launch it by typing in Y" -ForegroundColor Cyan
} else {
    Write-Host "PowerShell 7 is NOT installed." -ForegroundColor Red
    Write-Host "Please install it from the following link:" -ForegroundColor Yellow
    Write-Host "https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows" -ForegroundColor Cyan
    Write-Host "Then type Y into the console" -ForegroundColor Yellow
}
Write-Host ""
# ------------------------------------------------------------

Write-Host "1.) In PowerShell 7, run this command:" -ForegroundColor Yellow
Write-Host "    Import-Module `$env:USERPROFILE\Documents\EntraController\EzEntraTools.psm1 -Force" -ForegroundColor Cyan
Write-Host ""
Write-Host "2.) Start the tool run:" -ForegroundColor Yellow
Write-Host "    Start-EzEntraController" -ForegroundColor Cyan
Write-Host ""
Write-Host "------------------------------------------------------------"
Write-Host ""


$userInput = $false

while  ($userInput -eq $false){

    $userInput = Read-Host "Do you want to launch PowerShell 7 now? (Y/N)"


    switch ( $userInput ) {
        "Y" { 
            
            $InstallCheck = Test-Path "C:\Program Files\PowerShell\7\pwsh.exe"

            if (-not $InstallCheck){

                Write-Host "PowerShell 7 is NOT installed." -ForegroundColor Red
                Write-Host "Please install it from the following link:" -ForegroundColor Yellow
                Write-Host "https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows" -ForegroundColor Cyan
                Write-Host "Then press Y " -ForegroundColor Yellow
                $userInput = $false
                continue

            }else{ 
                
                Write-Host -ForegroundColor Green "Starting Powershell 7..."
                Start-Process "C:\Program Files\PowerShell\7\pwsh.exe" 
                $userInput = $true
            
            }


            

            $userInput = $true; exit}

        "N" { Write-Host -ForegroundColor Yellow "Exiting script, please import module and run Start-EzEntraController in powershell 7"; break}
        
        Default { Write-Host "Please Type Y or N" 
        $userInput = $false }
    }
}
