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

# 5. Git Pager (delta) - parity with the WSL side
Write-Host "==> Configuring Git pager (delta)..." -ForegroundColor Cyan
if (Get-Command git -ErrorAction SilentlyContinue) {
    if (-not (Get-Command delta -ErrorAction SilentlyContinue)) {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            Write-Host "  [WINGET] Installing delta..." -ForegroundColor Yellow
            winget install --id dandavison.delta --silent --accept-source-agreements --accept-package-agreements 2>$null
            # winget updates PATH for new sessions only; refresh it so the check below sees delta.
            $env:Path = [Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [Environment]::GetEnvironmentVariable("Path", "User")
        }
    }

    if (Get-Command delta -ErrorAction SilentlyContinue) {
        # Same wrapper as install.sh, so the width-aware side-by-side logic is shared.
        # It needs a shell, and a bare `sh` is NOT resolvable inside the shell git
        # uses to run pagers - only Windows PATH entries are, which is why `delta`
        # resolves there but `sh` does not. So invoke Git's bundled sh by absolute
        # path. Falls back to plain delta if that layout ever changes.
        $DotfilesPosix = $DotfilesDir -replace '\\', '/'
        $DeltaCfg = "$DotfilesPosix/git/delta.gitconfig"
        $GitSh = Join-Path (Split-Path -Parent (Split-Path -Parent (Get-Command git).Source)) "usr\bin\sh.exe"
        if (Test-Path $GitSh) {
            $GitShPosix = $GitSh -replace '\\', '/'
            $DeltaPager = "`"$GitShPosix`" `"$DotfilesPosix/bin/delta-pager`""
        } else {
            Write-Host "  [WARN] Git's bundled sh not found; using delta without the width-aware wrapper." -ForegroundColor Yellow
            $DeltaPager = "delta"
        }

        $currentPager = git config --global --get core.pager 2>$null
        if ($currentPager -ne $DeltaPager) {
            git config --global core.pager $DeltaPager
            Write-Host "  [OK] core.pager set (side-by-side at >=100 columns)." -ForegroundColor Green
        } else {
            Write-Host "  [OK] core.pager already set." -ForegroundColor Green
        }

        $includes = @(git config --global --get-all include.path 2>$null)
        if ($includes -notcontains $DeltaCfg) {
            git config --global --add include.path $DeltaCfg
            Write-Host "  [OK] delta config included from $DeltaCfg." -ForegroundColor Green
        } else {
            Write-Host "  [OK] delta config already included." -ForegroundColor Green
        }
    } else {
        Write-Host "  [SKIP] delta not installed; keeping the stock Git pager." -ForegroundColor Yellow
    }
}

Write-Host "==> Windows setup complete! Run 'reload' or restart PowerShell 7." -ForegroundColor Green
