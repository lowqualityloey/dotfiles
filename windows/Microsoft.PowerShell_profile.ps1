# ==============================================================================
# 1. UTF-8 Console Encoding (Fixes broken symbols, emojis & Git logs)
# ==============================================================================
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# ==============================================================================
# 2. PSReadLine & Predictive IntelliSense (Fast Autocompletion)
# ==============================================================================
if ($Host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineOption -Colors @{ InlinePrediction = '#928374' } # Gruvbox muted gray
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Space' -Function Complete
}

# ==============================================================================
# 3. Prompt Initialization (Oh My Posh - Clean & Fast)
# ==============================================================================
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $ThemePath = "$HOME\my-posh-theme.omp.json"
    if (Test-Path $ThemePath) {
        oh-my-posh init pwsh --config $ThemePath | Invoke-Expression
    } else {
        oh-my-posh init pwsh | Invoke-Expression
    }
}

# File & Folder Icons in dir/ls (if module is installed)
Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue

# ==============================================================================
# 4. Navigation & Directory Bridges
# ==============================================================================
function ..    { Set-Location .. }
function ...   { Set-Location ..\.. }
function ....  { Set-Location ..\..\.. }
function cdwsl { Set-Location "\\wsl$\Ubuntu\home\heyloey" }
function cddoc { Set-Location "$HOME\OneDrive\Documents" }

# Linux bridges
Set-Alias -Name which   -Value Get-Command -Option AllScope
Set-Alias -Name grep    -Value Select-String -Option AllScope
Set-Alias -Name pbcopy  -Value Set-Clipboard -Option AllScope
Set-Alias -Name pbpaste -Value Get-Clipboard -Option AllScope
function touch($path) { New-Item -ItemType File -Path $path -Force }
function open($path = ".") { explorer.exe $path }

# ==============================================================================
# 5. Git Shortcuts (Parity with Oh My Zsh)
# ==============================================================================
function gst { git status $args }
function gp  { git push $args }
function gl  { git pull $args }
function gco { git checkout $args }
function gcb { git checkout -b $args }
function lg  { lazygit $args }

# ==============================================================================
# 6. Profile & Maintenance Helpers
# ==============================================================================
function Edit-Profile {
    if (Get-Command code -ErrorAction SilentlyContinue) { code $PROFILE } else { notepad $PROFILE }
}
Set-Alias -Name config -Value Edit-Profile

function Reload-Profile {
    . $PROFILE
    Write-Host "PowerShell profile reloaded!" -ForegroundColor Green
}
Set-Alias -Name reload -Value Reload-Profile

# System Maintenance (Clean + Update)
function Optimize-System {
    Write-Host "🧹 Flushing DNS..." -ForegroundColor Yellow
    ipconfig /flushdns
    Write-Host "🧹 Cleaning Temp files..." -ForegroundColor Yellow
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "✅ System cleanup complete!" -ForegroundColor Green
}
Set-Alias -Name sysclean -Value Optimize-System

function Update-AllPackages {
    Write-Host "📦 Updating Windows apps via WinGet..." -ForegroundColor Cyan
    winget upgrade --all --include-unknown
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "🍫 Updating Chocolatey packages..." -ForegroundColor Yellow
        choco upgrade all -y
    }
}
Set-Alias -Name sysupdate -Value Update-AllPackages
