#!/usr/bin/env bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d%H%M%S)"

echo "==> Setting up dotfiles from $DOTFILES_DIR..."

# 1. Ensure ~/.local/bin exists
mkdir -p "$HOME/.local/bin"

# 2. Link configuration files
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

echo "--> Linking dotfiles..."
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
link_file "$DOTFILES_DIR/TERMINAL_CHEATSHEET.md" "$HOME/TERMINAL_CHEATSHEET.md"
link_file "$DOTFILES_DIR/bin/cheatsheet" "$HOME/.local/bin/cheatsheet"
chmod +x "$DOTFILES_DIR/bin/cheatsheet" 2>/dev/null || true

# 3. Check Oh My Zsh
ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
if [ ! -d "$ZSH_DIR" ]; then
    echo "--> Oh My Zsh not found. Installing Oh My Zsh..."
    git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR" || echo "  [WARN] Could not clone Oh My Zsh automatically."
else
    echo "  [OK] Oh My Zsh is present at $ZSH_DIR."
fi

# 4. Auto-clone custom Oh My Zsh plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"
clone_plugin() {
    local repo_url="$1"
    local plugin_name="$2"
    local target_dir="$ZSH_CUSTOM/plugins/$plugin_name"

    if [ ! -d "$target_dir" ]; then
        echo "  [INSTALL] Cloning OMZ plugin '$plugin_name'..."
        mkdir -p "$(dirname "$target_dir")"
        git clone --depth=1 "$repo_url" "$target_dir" || echo "  [WARN] Failed to clone $plugin_name."
    else
        echo "  [OK] Plugin '$plugin_name' is already installed."
    fi
}

echo "--> Verifying custom Zsh plugins..."
clone_plugin "https://github.com/zsh-users/zsh-autosuggestions.git" "zsh-autosuggestions"
clone_plugin "https://github.com/zsh-users/zsh-syntax-highlighting.git" "zsh-syntax-highlighting"
clone_plugin "https://github.com/marlonrichert/zsh-autocomplete.git" "zsh-autocomplete"

# 5. Summary check of CLI tools
echo "--> Checking CLI suite..."
for tool in starship zoxide fzf eza bat lazygit tmux; do
    if command -v "$tool" >/dev/null 2>&1 || command -v "${tool}cat" >/dev/null 2>&1; then
        echo "  [OK] $tool is installed."
    else
        echo "  [OPTIONAL] $tool is not installed yet (install for the full experience)."
    fi
done

echo "==> Dotfiles setup complete! Run 'source ~/.zshrc' to apply."
