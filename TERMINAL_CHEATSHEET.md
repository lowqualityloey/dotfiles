# 🚀 Terminal & CLI Cheatsheet Guide

A complete reference for your customized **Zsh + Oh My Zsh + Starship (Gruvbox Rainbow)** setup on Ubuntu (WSL2).

---

## ⚡ Quick Command Reference

| Command / Shortcut | What It Does | Example Usage |
| :--- | :--- | :--- |
| **`ls`** | Colorized file list with Nerd Font icons (via `eza`) | `ls` |
| **`ll`** | Detailed list + permissions + Git status | `ll` |
| **`tree`** | Visual directory tree with file icons | `tree` or `tree -L 2` |
| **`cat <file>`** | Syntax-highlighted viewer with line numbers (via `bat`) | `cat package.json` |
| **`z <folder>`** | Smart-jump to any frequent directory (via `zoxide`) | `z shelf` |
| **`zi`** | Interactive fuzzy directory selector | `zi` |
| **`lg`** | Launch full Git Terminal UI (via `lazygit`) | `lg` |
| **`grid`** | Open / re-attach a 2×2 quad-terminal layout in 1 window | `grid` |
| <kbd>Ctrl</kbd> + <kbd>T</kbd> | Fuzzy-find file with **live syntax preview window** | Press inside any folder |
| <kbd>Ctrl</kbd> + <kbd>R</kbd> | Fuzzy-search command history | Press and start typing |
| <kbd>Ctrl</kbd> + <kbd>Space</kbd> | Accept inline auto-suggestion without leaving home row | Type partial command, hit shortcut |
| <kbd>Esc</kbd> <kbd>Esc</kbd> | Automatically prepend `sudo` to current/previous command | Double-tap Escape |
| **`pbcopy`** | Copy text/command output directly to Windows clipboard | `cat id_rsa.pub \| pbcopy` |
| **`open`** | Open current directory in Windows File Explorer | `open` |
| **`agy-models`** | List available AI models & reasoning tiers | `agy-models` |
| **`agy-usage`** | Check token limits and model quotas | `agy-usage` |
| **`cheatsheet`** | Open this guide directly in your terminal | `cheatsheet` |

---

## 🛠️ Detailed Tool Usage

### 1. `zoxide` (`z` / `zi`)
A smart replacement for `cd` that tracks which directories you visit most often:
* **`z <partial-name>`**: Jump directly without typing full paths.
  * `z shelf` → jumps to `~/personal/shelf`
  * `z dash` → jumps to `~/personal/weather-dashboard`
* **`zi`**: Interactive menu to search and select recent directories.

---

### 2. `fzf` (Fuzzy Search + Syntax Preview)
* **File Finder (<kbd>Ctrl</kbd> + <kbd>T</kbd>)**:
  * Opens a search box. As you scroll through files, the side preview pane shows the code highlighted with `bat`.
  * Hit <kbd>Enter</kbd> to paste the selected file path onto your command line.
* **History Search (<kbd>Ctrl</kbd> + <kbd>R</kbd>)**:
  * Fuzzy-search any command you’ve ever run with Gruvbox syntax styling.

---

### 3. `lazygit` (`lg`)
A full Git management interface inside your terminal:
* Type **`lg`** in any Git project.
* Key shortcuts:
  * <kbd>Space</kbd>: Stage / unstage files or specific code lines.
  * <kbd>c</kbd>: Commit changes.
  * <kbd>P</kbd>: Push to GitHub/remote.
  * <kbd>p</kbd>: Pull from remote.
  * <kbd>b</kbd>: Branch switching & management.
  * <kbd>q</kbd>: Exit.

---

### 4. `grid` (Quad 2×2 Multi-Terminal)
Splits your single terminal window into a 2×2 grid:
* Type **`grid`** to create or resume the session.
* **Mouse Controls**: Click any pane to type; drag border dividers to resize; scroll with mouse wheel.
* **Detach**: Press <kbd>Ctrl</kbd> + <kbd>b</kbd>, then <kbd>d</kbd> (keeps tasks running; type `grid` to re-enter).
* **Close Pane**: Type `exit`.

---

### 5. Secret History Protection
* Any command beginning with a **space** is excluded from history:
  ```zsh
   export API_KEY="sk-..."    # Note leading space: never saved to ~/.zsh_history!
  ```

---

### 6. Universal Archive Unpacker (`extract`)
Automatically chooses the right decompression tool:
```zsh
extract file.zip
extract archive.tar.gz
extract bundle.tar.xz
extract package.7z
```

---

## 🪟 Windows PowerShell 7 Quick Reference

If you drop into PowerShell 7 (`pwsh`), your environment matches your Zsh workflow:

| Command / Shortcut | What It Does |
| :--- | :--- |
| **`gst`**, **`gp`**, **`gl`** | Git status, push, pull |
| **`gco`**, **`gcb`** | Git checkout, checkout branch |
| **`lg`** | Launch LazyGit |
| **`cdwsl`** | Jump straight to your Ubuntu WSL2 home folder (`\\wsl$\Ubuntu\home\heyloey`) |
| **`cddoc`** | Jump straight to your OneDrive Documents folder |
| **`..`**, **`...`**, **`....`** | Quick directory navigation |
| **`which <cmd>`** | PowerShell alias for `Get-Command` |
| **`grep <pattern>`** | PowerShell alias for `Select-String` |
| **`touch <file>`** | Create empty file |
| **`open <path>`** | Open directory in File Explorer |
| **`sysclean`** | Flush DNS & clean Windows Temp files |
| **`sysupdate`** | Upgrade all Windows apps via WinGet and Chocolatey |
| **`config`** | Edit PowerShell profile in VS Code |
| **`reload`** | Reload `$PROFILE` without restarting terminal |
| <kbd>Ctrl</kbd> + <kbd>Space</kbd> / <kbd>Tab</kbd> | Accept Predictive IntelliSense / Open Tab completion menu |

---

## 🎨 Theme & Configuration Files

* **Prompt**: Starship with Gruvbox Rainbow (`~/.config/starship.toml`)
* **Windows Prompt**: Oh My Posh (`~/my-posh-theme.omp.json`)
* **Terminal Background**: Gruvbox Dark `#282828`
* **Font**: `JetBrainsMono Nerd Font`
* **Main Shell Config**: `~/.zshrc`
* **PowerShell 7 Config**: `C:\Users\jonel\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`
* **Tmux Config**: `~/.tmux.conf`
* **Dotfiles Git Repo**: `~/dotfiles` (Synced to `lowqualityloey/dotfiles`)
* **Safety Backups**: `~/.zshrc.backup.*` and `~/.config/starship.toml.backup.*`
