# Windows PowerShell 7 Dotfiles Installer
$ErrorActionPreference = "Stop"

$DotfilesDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$WindowsDir = Join-Path $DotfilesDir "windows"
$Timestamp = Get-Date -Format "yyyyMMddHHmmss"

Write-Host "==> Bootstrapping Windows PowerShell 7 Dotfiles from $DotfilesDir..." -ForegroundColor Cyan

# 1. Profile Setup
$ProfileDir = Split-Path -Parent $PROFILE
if (-not (Test-Path $ProfileDir)) {
    New-Item -ItemType Directory -Path $ProfileDir -Force | Out-Null
}

$ProfileSrc = Join-Path $WindowsDir "Microsoft.PowerShell_profile.ps1"
if (Test-Path $PROFILE) {
    $BackupProfile = "$PROFILE.backup.$Timestamp"
    Write-Host "  [BACKUP] Existing profile backed up to $BackupProfile" -ForegroundColor Yellow
    Copy-Item $PROFILE $BackupProfile -Force
}
Copy-Item $ProfileSrc $PROFILE -Force
Write-Host "  [LINKED] $PROFILE updated (PowerShell 7)." -ForegroundColor Green

# 1b. Windows PowerShell 5.1 Profile Setup
$WinPSDir = Join-Path (Split-Path -Parent $ProfileDir) "WindowsPowerShell"
if (Test-Path $WinPSDir) {
    $WinPSProfile = Join-Path $WinPSDir "Microsoft.PowerShell_profile.ps1"
    $WinPSSrc = Join-Path $WindowsDir "WindowsPowerShell_profile.ps1"
    if (Test-Path $WinPSProfile) {
        Copy-Item $WinPSProfile "$WinPSProfile.backup.$Timestamp" -Force
    }
    Copy-Item $WinPSSrc $WinPSProfile -Force
    Write-Host "  [LINKED] $WinPSProfile updated (Windows PowerShell 5.1)." -ForegroundColor Green
}

# 2. Starship Config Setup
$ConfigDir = Join-Path $HOME ".config"
if (-not (Test-Path $ConfigDir)) {
    New-Item -ItemType Directory -Path $ConfigDir -Force | Out-Null
}
$StarshipSrc = Join-Path $DotfilesDir "starship.toml"
$StarshipDest = Join-Path $ConfigDir "starship.toml"
Copy-Item $StarshipSrc $StarshipDest -Force
Write-Host "  [LINKED] $StarshipDest updated." -ForegroundColor Green

# 3. Install Required PowerShell Modules
Write-Host "==> Checking & Installing PowerShell Modules..." -ForegroundColor Cyan
Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted -ErrorAction SilentlyContinue
$Modules = @("Terminal-Icons", "posh-git", "CompletionPredictor", "PSFzf")
foreach ($mod in $Modules) {
    if (-not (Get-Module -ListAvailable -Name $mod)) {
        Write-Host "  [INSTALL] Installing module $mod..." -ForegroundColor Yellow
        Install-Module -Name $mod -Scope CurrentUser -Force -SkipPublisherCheck
    } else {
        Write-Host "  [OK] Module $mod is already installed." -ForegroundColor Green
    }
}

# 4. Optional CLI Tools via WinGet
Write-Host "==> Checking CLI Tools (Starship, Zoxide, FZF)..." -ForegroundColor Cyan
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $Tools = @("Starship.Starship", "ajeetdsouza.zoxide", "junegunn.fzf")
    foreach ($tool in $Tools) {
        Write-Host "  [WINGET] Ensuring $tool is installed..." -ForegroundColor Yellow
        winget install --id $tool --silent --accept-source-agreements --accept-package-agreements 2>$null
    }
}

Write-Host "==> Windows setup complete! Run 'reload' or restart PowerShell 7." -ForegroundColor Green
