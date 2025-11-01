######Ez Entra Controller
-------------
### Option 1: Install from EXE (Manual Method)
---

````markdown
# 🧭 EzEntraController

A lightweight PowerShell-based controller tool for managing Entra (Azure AD) environments with ease.  
Supports both EXE-based and direct PowerShell installation methods.

---

## ⚙️ Requirements

- **PowerShell 7 or higher**
- **Do not** run the EXE as Administrator
- You may need to **temporarily disable antivirus** during installation (some antivirus tools block unsigned EXEs)

---

## 🚀 Quick Start (Recommended)

### Option 1: Install via EXE
1. Download the latest release EXE from this repository’s **Releases** section.  
2. Run the EXE **(not as Administrator)**.  
3. Once installation completes, launch **PowerShell 7** and run:

   ```powershell
   Import-Module "$env:USERPROFILE\Documents\EntraController\EzEntraTools.psm1" -Force
   Start-EzEntraController
````

---

### Option 2: Install Directly from PowerShell (Manual Method)

If you prefer or cannot use the EXE, you can install directly from GitHub using PowerShell 7:

```powershell
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
```

After installation, run:

```powershell
Import-Module "$env:USERPROFILE\Documents\EntraController\EzEntraTools.psm1" -Force
Start-EzEntraController
```

---

## 🧩 Notes

* The EXE simply runs the same installation script shown above.
* Ensure you’re running **PowerShell 7+** (`pwsh`) — not Windows PowerShell 5.1.
* All module files are installed under:

  ```
  %USERPROFILE%\Documents\EntraController
  ```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

---

## 💬 Support

If you encounter issues or have suggestions, please open an issue on the [GitHub Issues](../../issues) page.

---

```

---

Would you like me to include badges (like PowerShell version, license, or GitHub release badges) and a small logo/banner section at the top for a more “professional GitHub project” look?
```
