# 🚀 Terminal & CLI Quick Reference Guide

A complete guide to your optimized **Zsh + Oh My Zsh + Starship (Gruvbox Rainbow)** setup on Ubuntu (WSL2).

---

## ⚡ Quick Cheatsheet

| Command / Shortcut | What It Does | Example |
| :--- | :--- | :--- |
| **`ls`** | Colorized file list with icons (via `eza`) | `ls` |
| **`ll`** | Detailed list + file permissions + Git status | `ll` |
| **`tree`** | Visual directory tree with icons | `tree` or `tree -L 2` |
| **`cat <file>`** | View file with syntax highlighting & line numbers (via `bat`) | `cat package.json` |
| **`z <folder>`** | Smart jump to any frecent directory (via `zoxide`) | `z shelf` |
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
| **`cheatsheet`** | Open this reference guide in your terminal | `cheatsheet` |

---

## 🛠️ Tool-by-Tool Guide

### 1. `zoxide` (Smarter `cd`)
Instead of typing long paths like `cd ~/personal/shelf/frontend`:
* **`z <keyword>`**: Jump directly based on frecency (frequency + recency).
  ```zsh
  z shelf      # Jumps to ~/personal/shelf
  z dash       # Jumps to ~/personal/weather-dashboard
  ```
* **`zi`**: Opens an interactive fuzzy menu with search preview so you can pick the directory.

---

### 2. `fzf` (Fuzzy Finder with Live Preview)
* **File Search with Preview (<kbd>Ctrl</kbd> + <kbd>T</kbd>)**:
  * Press <kbd>Ctrl</kbd> + <kbd>T</kbd> to search files.
  * As you navigate up/down with arrow keys, a right-hand pane shows the file contents with syntax highlighting (`bat`) or directory contents (`eza`).
  * Hit <kbd>Enter</kbd> to paste the selected path into your terminal.
* **History Search (<kbd>Ctrl</kbd> + <kbd>R</kbd>)**:
  * Fuzzy search through your past commands with Gruvbox highlighting.

---

### 3. `lazygit` (`lg`)
A terminal UI that turns complex Git commands into simple keystrokes:
* Type **`lg`** inside any repository.
* **Key Controls**:
  * <kbd>Space</kbd>: Stage / unstage file or hunk.
  * <kbd>c</kbd>: Commit staged changes (opens prompt for message).
  * <kbd>P</kbd>: Push to remote.
  * <kbd>p</kbd>: Pull from remote.
  * <kbd>b</kbd>: Open branch menu (switch / create / delete).
  * <kbd>q</kbd>: Exit lazygit.

---

### 4. `grid` (Quad 2×2 Multi-Terminal)
Launches 4 independent terminals tiled in a 2×2 grid inside your single window:
* Type **`grid`** to open or re-attach.
* **Mouse Controls**:
  * Click any pane to focus.
  * Drag the divider borders to resize panes.
  * Scroll inside any pane with the mouse wheel.
* **Detach & Keep Running**: Press <kbd>Ctrl</kbd> + <kbd>b</kbd>, then <kbd>d</kbd>. (Run `grid` later to resume).
* **Close a Pane**: Type `exit`.

---

### 5. Secret History Protection
* Any command that starts with a **space** is **never written to history**:
  ```zsh
   export GITHUB_TOKEN="ghp_1234567890"   # Note the leading space!
  ```
  Check your history with `history`—it won't appear.

---

### 6. Archive Extraction (`extract`)
Never memorize `tar -xzvf` or `unzip` flags again. Just type:
```zsh
extract archive.tar.gz
extract file.zip
extract package.tar.xz
extract compressed.7z
```

---

## 🎨 Theme & Appearance Reference

* **Prompt Theme**: Starship with **Gruvbox Rainbow** preset (`~/.config/starship.toml`).
* **Terminal Background**: Gruvbox Dark (`#282828`) configured in Windows Terminal and VS Code / Antigravity IDE.
* **Font**: `JetBrainsMono Nerd Font` (provides git branch ``, node ``, and OS icons `󰕈`).

---

## 📁 Key File Locations & Backups

| File | Purpose |
| :--- | :--- |
| **`~/.zshrc`** | Main shell configuration (plugins, aliases, paths) |
| **`~/.config/starship.toml`** | Starship prompt layout & colors |
| **`~/.tmux.conf`** | Tmux settings (mouse support, splits, 256 colors) |
| **`~/.local/bin/`** | User-installed CLI binaries (`fzf`, `zoxide`, `bat`, `eza`, `fd`, `lazygit`, `starship`) |
| **`~/.zshrc.backup.*`** | Timestamped safety backups of original `.zshrc` |
