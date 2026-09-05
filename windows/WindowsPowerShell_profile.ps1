# ==============================================================================
# Windows PowerShell 5.1 Profile (Aligned with PowerShell 7 & WSL2)
# ==============================================================================

# 1. UTF-8 Console Encoding (Fixes broken symbols, emojis & Git logs)
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8

# 2. PATH Resolution for CLI Tools
if (-not (Get-Command starship -ErrorAction SilentlyContinue)) {
    if (Test-Path 'C:\Program Files\starship\bin') {
        $env:PATH = "C:\Program Files\starship\bin;$env:PATH"
    }
}

# 3. Prompt Initialization (Starship - Gruvbox Rainbow)
$env:STARSHIP_LOG = 'error'
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}

# 4. Navigation & Directory Bridges
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

# 5. Git Shortcuts (Parity with Oh My Zsh)
function gst { git status $args }
function gp  { git push $args }
function gl  { git pull $args }
function gco { git checkout $args }
function gcb { git checkout -b $args }
function lg  { lazygit $args }

# 6. Integrations (Chocolatey & Kiro)
if ($env:TERM_PROGRAM -eq "kiro") { 
    if (Get-Command kiro -ErrorAction SilentlyContinue) {
        . "$(kiro --locate-shell-integration-path pwsh)"
    }
}

$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile" -ErrorAction SilentlyContinue
}

# 7. Profile Helpers
function Reload-Profile {
    . $PROFILE
    Write-Host "Windows PowerShell 5.1 profile reloaded!" -ForegroundColor Green
}
Set-Alias -Name reload -Value Reload-Profile

function Edit-Profile {
    if (Get-Command code -ErrorAction SilentlyContinue) { code $PROFILE } else { notepad $PROFILE }
}
Set-Alias -Name config -Value Edit-Profile
