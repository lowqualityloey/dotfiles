# 💻 Personal Dotfiles

![Theme](https://img.shields.io/badge/Theme-Gruvbox%20Dark-ebdbb2?color=282828&labelColor=3c3836)
![Shell](https://img.shields.io/badge/Shell-Zsh%20%7C%20PowerShell%207-d79921?color=282828&labelColor=3c3836)
![Prompt](https://img.shields.io/badge/Prompt-Starship%20Rainbow-83a598?color=282828&labelColor=3c3836)
![OS](https://img.shields.io/badge/OS-Ubuntu%2024.04%20(WSL2)%20%2B%20Windows%2011-b8bb26?color=282828&labelColor=3c3836)
![License](https://img.shields.io/badge/License-MIT-fabd2f?color=282828&labelColor=3c3836)

A unified, high-performance, cross-platform terminal environment optimized for developer productivity across **Ubuntu 24.04 (WSL2)** and **Windows 11 (PowerShell 7)**.

---

## 📸 Preview

### 🐧 Ubuntu 24.04 (WSL2) — Zsh + Starship Gruvbox Rainbow
![Ubuntu WSL2 Terminal Demo](assets/ubuntu-wsl2-demo.png)

### 🪟 Windows 11 — PowerShell 7 + Starship Gruvbox Rainbow
![Windows PowerShell 7 Demo](assets/powershell-demo.png)

---

## ✨ Features at a Glance

* **🎨 Unified Visual Design**:
  * **Gruvbox Dark (`#282828`)** palette unified across Windows Terminal, Antigravity IDE, and VS Code.
  * **Typography**: `JetBrainsMono Nerd Font` with full symbol support.
  * **Shared Prompt**: **Starship** with the Gruvbox Rainbow preset and a compact 12-hour AM/PM clock (`5:35pm`) across both Linux and Windows.
* **⚡ Blazing Fast Linux Shell (WSL2 Zsh)**:
  * Startup time cut from **2.68s to ~0.7s (~3.8x faster)**, measured with `zsh -i -c exit`.
  * Lazy-loaded NVM and skipped redundant compaudit security checks.
  * 2×2 quad-terminal layout command (`grid`, `grid reset`) with mouse resize and scroll wheel support.
  * Built-in security guardrails: `HIST_IGNORE_SPACE` prevents commands with a leading space from saving to history, plus automatic sourcing of gitignored `~/.zshrc.local` for machine-specific secrets.
* **🪟 Modern Windows Shell (PowerShell 7)**:
  * **UTF-8 console encoding** enforced to eliminate broken emojis, Git logs, and symbols.
  * **PSReadLine Predictive IntelliSense** with Gruvbox muted gray (`#928374`) inline autocompletion (<kbd>Ctrl</kbd> + <kbd>Spacebar</kbd>).
  * **Microsoft `CompletionPredictor`** for intelligent command line argument predictions.
  * **`Terminal-Icons`** for rich file & directory glyphs in `ls` and `dir`.
  * **Deep Git Tab Completion** via `posh-git`.
  * **Linux/Zsh Parity Bridges**: `which`, `grep`, `touch`, `open`, `pbcopy`/`pbpaste`, `cdwsl`, and git aliases (`gst`, `gp`, `gl`, `gco`, `gcb`, `lg`).
  * **Kiro & Chocolatey Integration**: Sources the Kiro shell integration when `$env:TERM_PROGRAM` is `kiro`, and loads `chocolateyProfile.psm1` when present.
  * **Private Overrides**: Automatically loads gitignored `$HOME/.profile.local.ps1` if present.
* **🔍 Modern Rust CLI Suite**:
  * `fzf` & `fd`: Fuzzy file finding (<kbd>Ctrl</kbd> + <kbd>T</kbd>) and history search (<kbd>Ctrl</kbd> + <kbd>R</kbd>).
  * `zoxide`: Smart directory jumping (`z <folder>`, `zi`).
  * `eza`: Colorized directory listings with Git status and file icons (`ls`, `ll`, `tree`).
  * `bat`: Syntax-highlighted text and code viewer (`cat`).
  * `lazygit`: Full-screen Git terminal UI (`lg`).
* **🔁 Portable by Design**:
  * No hardcoded usernames, WSL distro names, or absolute home paths. Linux uses `$HOME`; on Windows `cdwsl` resolves the default distro and its home at runtime.
  * Optional tools that may be absent (`brew`, `atuin`, GitButler, `oh-my-posh`) are skipped cleanly instead of erroring on a fresh machine.

---

## 📁 Repository Structure

```text
dotfiles/
├── .gitignore                       # Safeguard against committing secrets & temp files
├── LICENSE                          # MIT License
├── .zshrc                           # Optimized Zsh configuration (WSL2)
├── starship.toml                    # Shared Starship Gruvbox Rainbow configuration
├── .tmux.conf                       # Tmux quad-terminal & ergonomics settings
├── install.sh                       # One-click bootstrap installer for Linux / WSL2
├── TERMINAL_CHEATSHEET.md           # Full CLI and shortcut cheatsheet
├── assets/                          # Demo screenshots and visual assets
│   ├── ubuntu-wsl2-demo.png
│   └── powershell-demo.png
├── bin/
│   └── cheatsheet                   # Interactive ANSI terminal reference tool
└── windows/
    ├── Microsoft.PowerShell_profile.ps1 # Complete PowerShell 7 profile
    ├── WindowsPowerShell_profile.ps1    # Aligned Windows PowerShell 5.1 profile
    ├── terminal-settings.json       # Windows Terminal settings (Gruvbox Dark)
    ├── install.ps1                  # One-click bootstrap installer for Windows
    └── my-posh-theme.omp.json       # Oh My Posh theme (fallback when Starship is absent)
```

---

## 📋 Prerequisites

Before running the installers:
* **Font**: Install [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) (or any Nerd Font) and configure it as the font in your terminal emulator (e.g., Windows Terminal) so all powerline glyphs and file icons render properly.
* **Linux / WSL2**: Ensure base tools are available:
  ```bash
  sudo apt update && sudo apt install -y zsh git curl
  ```
  *(The installer automatically installs Oh My Zsh and clones missing custom plugins for you).*

---

## 🚀 Quick Start / Installation

### 1. On Ubuntu 24.04 / WSL2
```bash
git clone https://github.com/lowqualityloey/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
source ~/.zshrc
```

### 2. On Windows 11 (PowerShell 7)
Open **PowerShell 7** as your standard user:
```powershell
git clone https://github.com/lowqualityloey/dotfiles.git "$HOME\dotfiles"
& "$HOME\dotfiles\windows\install.ps1"
reload
```

> **Note on Windows Terminal**: [`windows/terminal-settings.json`](windows/terminal-settings.json) is provided as a complete reference. If you already have existing profiles, you can copy the `Gruvbox Dark` scheme and `defaults` font block into your own settings without overwriting your custom profile GUIDs. The bundled settings pin no distro-specific profile or starting directory, so the `WSL` profile adapts to whichever distro you have installed.

---

## ⌨️ Common Shortcuts & Cheatsheet

| Command / Key | Scope | What It Does |
| :--- | :--- | :--- |
| **`cheatsheet`** | WSL2 | Displays clean interactive CLI quick-reference card (`cheatsheet --full` for manual) |
| **`grid`** / **`grid reset`** | WSL2 | Launches, resumes, or resets a 2×2 quad-terminal layout in 1 window |
| **`z <folder>`** | WSL2 & Win | Smart-jump to frequent folders (`z shelf`, `z doc`) |
| **`zi`** | WSL2 & Win | Interactive fuzzy directory selection menu |
| <kbd>Ctrl</kbd> + <kbd>T</kbd> | WSL2 & Win | Fuzzy-search files in current folder with live syntax preview |
| <kbd>Ctrl</kbd> + <kbd>R</kbd> | WSL2 & Win | Fuzzy-search command history |
| <kbd>Ctrl</kbd> + <kbd>Space</kbd> | WSL2 & Win | Instantly accept inline predictive autocompletion |
| **`lg`** | WSL2 & Win | Launch LazyGit Terminal UI |
| **`gst`**, **`gp`**, **`gl`** | WSL2 & Win | Git status, push, pull |
| **`gco`**, **`gcb`** | WSL2 & Win | Git checkout, checkout new branch |
| **`which <cmd>`** | WSL2 & Win | Find executable location (bridges to `Get-Command` on Windows) |
| **`grep <pat>`** | WSL2 & Win | Text search (bridges to `Select-String` on Windows) |
| **`open`** | WSL2 & Win | Open current directory in Windows File Explorer |
| **`pbcopy`** / **`pbpaste`** | WSL2 & Win | Read/write directly to the Windows system clipboard |
| **`cdwsl`** | Windows | Jump to your default WSL distro's home folder (distro & user resolved at runtime) |
| **`cddoc`** | Windows | Jump directly to Documents folder (supports OneDrive or local Documents) |
| **`reload`** | WSL2 & Win | Re-source shell profile without restarting terminal window |
| **`sysclean`** | Windows | Flush DNS and clean temporary system files |
| **`sysupdate`** | Windows | Upgrade all Windows apps via WinGet and Chocolatey |

*(See [TERMINAL_CHEATSHEET.md](TERMINAL_CHEATSHEET.md) for full documentation).*

---

## 🔒 Private Overrides & Secrets

Keep work credentials, private API keys, and machine-specific configuration out of this public repository. Three mechanisms, in order of preference:

* **Environment variables — Linux / WSL2 (`~/.zshrc.local`)**:
  Automatically sourced by `.zshrc` if present. It sits outside the repo (`~/` is not a Git repository) and is additionally covered by `.gitignore` (`*.local`, `.zshrc.local`):
  ```zsh
  export GITHUB_TOKEN="github_pat_..."
  export OPENAI_API_KEY="sk-..."
  ```
* **Environment variables — Windows (`~/.profile.local.ps1`)**:
  Automatically sourced by both the PowerShell 7 and 5.1 profiles if present:
  ```powershell
  $env:ANTHROPIC_API_KEY = "sk-ant-..."
  ```
* **File references for tool configs (`~/.secrets/`, mode `600`)**:
  Some tools do not substitute environment variables in every field — notably `provider.<name>.options.apiKey` in `opencode.json`, where `{env:...}` is passed through as a literal string. Use `{file:...}` there instead:
  ```jsonc
  "apiKey": "{file:~/.secrets/vercel-api-key}"
  ```
  ```bash
  mkdir -p ~/.secrets && chmod 700 ~/.secrets
  printf '%s' "$KEY" > ~/.secrets/vercel-api-key   # no trailing newline
  chmod 600 ~/.secrets/vercel-api-key
  ```

> ⚠️ **Never put a secret in `.zshrc`.** That file is tracked by Git, so a token there is one `dotfiles add -A && dotfiles commit && dotfiles push` away from being published. Rotating a leaked token does not remove copies already written into editor backups, shell history, or pasted chat transcripts — keep secrets out of tracked files from the start.

---

## 🔄 Daily Workflow & Syncing

An alias `dotfiles` is configured in your shell to track and manage this repo from anywhere:

```zsh
dotfiles status
dotfiles add -A
dotfiles commit -m "Update aliases"
dotfiles push
```

> **Before pushing:** `add -A` stages *everything* in the repo, so a secret accidentally placed in a tracked file (`.zshrc`, a profile, a config) will be committed along with your real changes. Keep secrets in `~/.zshrc.local`, `~/.profile.local.ps1`, or `~/.secrets/` — see [Private Overrides & Secrets](#-private-overrides--secrets).

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE). Feel free to use, fork, and adapt these configurations for your own setup.
