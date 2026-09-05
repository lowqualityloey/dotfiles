# 🚀 Terminal & CLI Quick Reference Guide

A complete guide to your optimized **Zsh + Oh My Zsh + Starship (Gruvbox Rainbow)** setup on Ubuntu (WSL2).

**Dotfiles Repository**: [github.com/lowqualityloey/dotfiles](https://github.com/lowqualityloey/dotfiles) *(Private)*

---

## ⚡ Quick Reference Card

### 📁 Navigation & Files
* **`ls`** — Colorized file list with Nerd Font icons (`eza --icons`)
* **`ll`** — Detailed list with permissions, file sizes & Git status (`eza -la --icons --git`)
* **`tree`** — Visual directory hierarchy tree with icons (`eza --tree --icons`)
* **`cat <file>`** — Syntax-highlighted viewer with line numbers (`bat --paging=never`)
* **`z <folder>`** — Smart jump to frequent folder by keyword (e.g. `z shelf`, `z dash`)
* **`zi`** — Interactive fuzzy directory selector menu

### 🔍 Search & Completion
* <kbd>Ctrl</kbd> + <kbd>T</kbd> — Fuzzy file search with **live syntax preview pane** (powered by `fd` + `bat`)
* <kbd>Ctrl</kbd> + <kbd>R</kbd> — Fuzzy command history search with Gruvbox syntax styling
* <kbd>Ctrl</kbd> + <kbd>Space</kbd> — Accept inline auto-suggestion without leaving home row

### 🌿 Git & Multi-Terminal
* **`lg`** — Launch Lazygit (full-featured terminal UI for staging, committing, pushing)
* **`gst`** — Git status shortcut (via OMZ Git plugin)
* **`gp`** / **`gl`** — Git push / Git pull
* **`gco <branch>`** — Git checkout branch
* **`gcb <branch>`** — Git checkout new branch (`git checkout -b`)
* **`grid`** — Open / re-attach a 2×2 quad-terminal layout in 1 window
* <kbd>Ctrl</kbd> + <kbd>b</kbd>, <kbd>z</kbd> — Zoom / unzoom current tmux pane to full screen
* **`dotfiles`** — Manage your dotfiles git repository (`dotfiles status` / `dotfiles push`)

### 🪟 WSL2 & Productivity
* **`pbcopy`** — Copy text/command output directly to Windows clipboard (`cat id_rsa.pub | pbcopy`)
* **`open`** — Open current directory in Windows File Explorer (`open`)
* **`reload`** — Reload shell configuration instantly (`source ~/.zshrc`)
* <kbd>Esc</kbd> <kbd>Esc</kbd> — Automatically prepend `sudo` to current/previous command
* **Leading Space** (` `) — Any command starting with a space is excluded from history
* **`extract <file>`** — Universal archive unpacker (`.zip`, `.tar.gz`, `.tar.xz`, `.7z`)

### 🤖 Antigravity AI
* **`agy-models`** — List available AI models and reasoning tiers
* **`agy-usage`** — Check token limits, model quotas & reset countdowns

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

### 2. `fzf` + `fd` (Fuzzy Finder with Live Preview)
* **File Search with Preview (<kbd>Ctrl</kbd> + <kbd>T</kbd>)**:
  * Automatically respects `.gitignore` (skips `node_modules` and `.git`).
  * As you navigate up/down with arrow keys, a right-hand pane shows the file contents with syntax highlighting (`bat`) or directory contents (`eza`).
  * Hit <kbd>Enter</kbd> to paste the selected path into your terminal.
* **History Search (<kbd>Ctrl</kbd> + <kbd>R</kbd>)**:
  * Fuzzy search through your past commands with Gruvbox highlighting.

---

### 3. `lazygit` (`lg`)
A terminal UI that turns complex Git commands into simple keystrokes:
* Type **`lg`** inside any repository.
* **Key Controls**:
  * <kbd>Space</kbd>: Stage / unstage file or individual code hunk.
  * <kbd>c</kbd>: Commit staged changes (opens prompt for message).
  * <kbd>P</kbd>: Push to remote.
  * <kbd>p</kbd>: Pull from remote.
  * <kbd>b</kbd>: Open branch menu (switch / create / delete).
  * <kbd>q</kbd>: Exit lazygit.

---

### 4. `grid` & `tmux` (Quad 2×2 Multi-Terminal)
Launches 4 independent terminals tiled in a 2×2 grid inside your single window:
* Type **`grid`** to open or re-attach.
* **Key Controls**:
  * **Zoom Active Pane**: Press <kbd>Ctrl</kbd> + <kbd>b</kbd>, then <kbd>z</kbd> to toggle full-screen for that pane.
  * **Detach & Keep Running**: Press <kbd>Ctrl</kbd> + <kbd>b</kbd>, then <kbd>d</kbd>. (Run `grid` later to resume).
  * **Close a Pane**: Type `exit`.
* **Mouse Controls**:
  * Click any pane to focus.
  * Drag the divider borders to resize panes freely.
  * Scroll inside any pane with the mouse wheel.

---

### 5. Secret History Protection
* Any command that starts with a **space** is **never written to history**:
  ```zsh
   export GITHUB_TOKEN="ghp_1234567890"   # Note the leading space!
  ```
  Check your history with `history`—it won't appear.

---

### 6. Universal Archive Extraction (`extract`)
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
| **`~/.zshrc`** | Main shell configuration (symlinked to `~/dotfiles/.zshrc`) |
| **`~/.config/starship.toml`** | Starship prompt layout & colors (symlinked to `~/dotfiles/starship.toml`) |
| **`~/.tmux.conf`** | Tmux settings (symlinked to `~/dotfiles/.tmux.conf`) |
| **`~/.local/bin/`** | User-installed CLI binaries (`fzf`, `zoxide`, `bat`, `eza`, `fd`, `lazygit`, `starship`, `cheatsheet`) |
| **`~/dotfiles/`** | Git repository tracked at [github.com/lowqualityloey/dotfiles](https://github.com/lowqualityloey/dotfiles) |
