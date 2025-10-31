# Install-EntraController.ps1
# Downloads EntraController from GitHub and installs it to Documents

$ErrorActionPreference = "Stop"

$repoUrl = "https://github.com/mastersaints888/EntraController/archive/refs/heads/main.zip"
$installDir = "$env:USERPROFILE\Documents\EntraController"
$tempZip = Join-Path $env:TEMP "EntraController.zip"

Write-Host "Downloading EntraController..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $repoUrl -OutFile $tempZip

Write-Host "Extracting..." -ForegroundColor Cyan
Expand-Archive -Path $tempZip -DestinationPath $env:TEMP -Force

# Adjust this if your repo unzips with a different folder name
$extracted = Get-ChildItem "$env:TEMP" -Directory | Where-Object { $_.Name -like "*EntraController*" } | Select-Object -First 1

Write-Host "Installing to $installDir" -ForegroundColor Cyan
if (Test-Path $installDir) { Remove-Item -Recurse -Force $installDir }
Move-Item $extracted.FullName $installDir

Remove-Item $tempZip -Force

Write-Host "Installation complete." -ForegroundColor Green

# Optional: launch the tool
Import-Module "$env:USERPROFILE\Documents\EntraController\EzEntraTools.psm1" -Force
#Tell the user how to start the tool
$Version = $PSVersionTable.PSVersion 
$DisplayVersion = $Version.Major, $Version.Minor -join '.'
Write-Host "To start EntraController, make sure your on the right PSVersion YOU MUST BE ON POWERSHELL 7 or higher. Your verion is:" $DisplayVersion -ForegroundColor Yellow
Write-Host "1.) If you are not on powershell 7, please open powershell 7 or download from https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.5" -ForegroundColor Yellow
Write-Host "2.) Then run the following command in powershell 7 to import the tool: Import-Module $env:USERPROFILE\Documents\EntraController\EzEntraTools.psm1 -Force" -ForegroundColor Yellow
Write-Host "3.) Then run the following command to start the tool: Start-EzEntraController" -ForegroundColor Yellow