# 💻 Personal Dotfiles

My personalized, high-performance terminal configuration for **Zsh**, **Oh My Zsh**, **Starship**, and **tmux** on Ubuntu (WSL2).

---

## ⚡ Quick Start (On a New Machine)

Clone this repository and run the installer:

```bash
git clone https://github.com/lowqualityloey/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
source ~/.zshrc
```

---

## 📁 Included Configurations

* **`.zshrc`**: Optimized Zsh startup (~0.59s), lazy-loaded NVM, modern CLI aliases, history privacy, and `grid` quad-terminal function.
* **`starship.toml`**: Custom Starship prompt layout with Gruvbox Rainbow preset.
* **`.tmux.conf`**: Ergonomic tmux settings (mouse support, true color, 1-indexed panes, intuitive splits).
* **`TERMINAL_CHEATSHEET.md`**: Complete cheatsheet of shortcuts and installed CLI tools.

---

## 🔄 Syncing Changes

To push updates from your terminal:
```zsh
dotfiles add -A
dotfiles commit -m "Update configuration"
dotfiles push
```
