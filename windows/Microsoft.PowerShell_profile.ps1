# ==============================================================================
# 1. UTF-8 Console Encoding (Fixes broken symbols, emojis & Git logs)
# ==============================================================================
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# ==============================================================================
# 2. Environment PATH Resolution (WinGet & CLI Tools)
# ==============================================================================
$ExtraPaths = @(
    'C:\Program Files\starship\bin',
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\ajeetdsouza.zoxide_Microsoft.Winget.Source_8wekyb3d8bbwe",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\junegunn.fzf_Microsoft.Winget.Source_8wekyb3d8bbwe"
)
foreach ($p in $ExtraPaths) {
    if ((Test-Path $p) -and ($env:PATH -notlike "*$p*")) {
        $env:PATH = "$p;$env:PATH"
    }
}

# ==============================================================================
# 3. PSReadLine & Predictive IntelliSense (Fast Autocompletion)
# ==============================================================================
if ($Host.Name -eq 'ConsoleHost') {
    Import-Module PSReadLine -ErrorAction SilentlyContinue
    Import-Module CompletionPredictor -ErrorAction SilentlyContinue
    try {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction SilentlyContinue
        Set-PSReadLineOption -PredictionViewStyle InlineView -ErrorAction SilentlyContinue
        Set-PSReadLineOption -Colors @{ InlinePrediction = '#928374' } -ErrorAction SilentlyContinue # Gruvbox muted gray
    } catch { }
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete -ErrorAction SilentlyContinue
    Set-PSReadLineKeyHandler -Chord 'Ctrl+Spacebar' -Function AcceptSuggestion -ErrorAction SilentlyContinue
}

# ==============================================================================
# 4. Prompt Initialization (Starship - Gruvbox Rainbow)
# ==============================================================================
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
} elseif (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    oh-my-posh init pwsh --config "$HOME\my-posh-theme.omp.json" | Invoke-Expression
}

# ==============================================================================
# 5. Developer Modules (Terminal-Icons, posh-git, zoxide, PSFzf)
# ==============================================================================
# File & Folder Icons in dir/ls
Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue

# Git tab-completion for branches, remotes & stashes
Import-Module -Name posh-git -ErrorAction SilentlyContinue

# Smart directory jumper (z / zi)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    zoxide init powershell | Out-String | Invoke-Expression
}

# Fuzzy finder (Ctrl+T for files, Ctrl+R for history)
if (Get-Command fzf -ErrorAction SilentlyContinue) {
    Import-Module -Name PSFzf -ErrorAction SilentlyContinue
    Set-PsFzfOption -PSReadlineChordReverseHistory 'Ctrl+r' -PSReadlineChordProvider 'Ctrl+t'
}

# ==============================================================================
# 6. Navigation & Directory Bridges
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
# 7. Git Shortcuts (Parity with Oh My Zsh)
# ==============================================================================
function gst { git status $args }
function gp  { git push $args }
function gl  { git pull $args }
function gco { git checkout $args }
function gcb { git checkout -b $args }
function lg  { lazygit $args }

# ==============================================================================
# 8. Profile & Maintenance Helpers
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
