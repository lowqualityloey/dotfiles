#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"

echo "==> Setting up dotfiles from $DOTFILES_DIR..."

link_file() {
    local src="$1"
    local dest="$2"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        if [ "$(readlink -f "$dest" 2>/dev/null)" = "$src" ]; then
            echo "  [OK] $dest is already correctly linked."
            return 0
        fi
        mkdir -p "$BACKUP_DIR"
        echo "  [BACKUP] Backing up existing $dest to $BACKUP_DIR"
        mv "$dest" "$BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    echo "  [LINKED] $dest -> $src"
}

link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/TERMINAL_CHEATSHEET.md" "$HOME/TERMINAL_CHEATSHEET.md"

echo "==> Dotfiles setup complete!"
