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
link_file "$DOTFILES_DIR/bin/scrub-secrets" "$HOME/.local/bin/scrub-secrets"
link_file "$DOTFILES_DIR/bin/check-secret-leaks" "$HOME/.local/bin/check-secret-leaks"
link_file "$DOTFILES_DIR/bin/delta-pager" "$HOME/.local/bin/delta-pager"
chmod +x "$DOTFILES_DIR"/bin/cheatsheet "$DOTFILES_DIR"/bin/scrub-secrets "$DOTFILES_DIR"/bin/check-secret-leaks "$DOTFILES_DIR"/bin/delta-pager 2>/dev/null || true
# secret_scan.py is imported next to the real script, so the symlinks above work.

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

# Quiet fzf plugin: shadows oh-my-zsh's own so fzf's integration does not print a
# harmless "can't change option: zle" warning on non-TTY interactive startup.
# See the file header for why it must shadow rather than be sourced directly.
mkdir -p "$ZSH_CUSTOM/plugins/fzf"
ln -sf "$DOTFILES_DIR/zsh/plugins/fzf/fzf.plugin.zsh" "$ZSH_CUSTOM/plugins/fzf/fzf.plugin.zsh"
echo "  [OK] Installed quiet fzf plugin."

# 5. Summary check of CLI tools
echo "--> Checking CLI suite..."
for tool in starship zoxide fzf eza bat lazygit tmux; do
    if command -v "$tool" >/dev/null 2>&1 || command -v "${tool}cat" >/dev/null 2>&1; then
        echo "  [OK] $tool is installed."
    else
        echo "  [OPTIONAL] $tool is not installed yet (install for the full experience)."
    fi
done

# 6. systemd user timer for the periodic credential-leak check
echo "--> Installing credential-leak check timer..."
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
    UNIT_DIR="$HOME/.config/systemd/user"
    mkdir -p "$UNIT_DIR"
    cp "$DOTFILES_DIR/systemd/user/secret-leak-check.service" "$UNIT_DIR/"
    cp "$DOTFILES_DIR/systemd/user/secret-leak-check.timer" "$UNIT_DIR/"
    systemctl --user daemon-reload
    systemctl --user enable --now secret-leak-check.timer \
        && echo "  [OK] Timer enabled. Inspect with: systemctl --user list-timers secret-leak-check.timer" \
        || echo "  [WARN] Could not enable the timer; run 'systemctl --user enable --now secret-leak-check.timer' manually."
else
    echo "  [SKIP] No systemd user session; run 'check-secret-leaks' manually or add a cron entry."
fi

# 7. Git pager: pull in the tracked delta config (only if delta is installed,
#    so Git never breaks on a machine without it). Idempotent.
echo "--> Configuring Git pager..."
DELTA_CFG="$DOTFILES_DIR/git/delta.gitconfig"
# Same literal value on both platforms: git runs the pager through `sh`, so
# $HOME expands to the local home on Linux and to Git for Windows' bash home
# on Windows. Relies on the documented $HOME/dotfiles clone location.
DELTA_PAGER='sh $HOME/dotfiles/bin/delta-pager'
if command -v git >/dev/null 2>&1; then
    if command -v delta >/dev/null 2>&1; then
        if git config --global --get-all include.path 2>/dev/null | grep -qxF "$DELTA_CFG"; then
            echo "  [OK] delta config already included."
        else
            git config --global --add include.path "$DELTA_CFG"
            echo "  [OK] delta config included from $DELTA_CFG."
        fi

        # Width-aware wrapper, so side-by-side only appears on wide terminals.
        if [ "$(git config --global --get core.pager 2>/dev/null)" = "$DELTA_PAGER" ]; then
            echo "  [OK] delta Git pager already set."
        else
            git config --global core.pager "$DELTA_PAGER"
            echo "  [OK] delta Git pager set (side-by-side at >=100 columns)."
        fi
    else
        echo "  [SKIP] delta not installed; keeping the stock Git pager."
    fi
fi

echo "==> Dotfiles setup complete! Run 'source ~/.zshrc' to apply."
