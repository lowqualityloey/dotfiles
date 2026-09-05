
# Kiro CLI pre block. Keep at the top of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/zshrc.pre.zsh" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/zshrc.pre.zsh"

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- set to "" for Starship prompt
# (To switch back to bira, uncomment ZSH_THEME="bira" and comment out Starship at the bottom)
# ZSH_THEME="bira"
ZSH_THEME=""

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git zoxide sudo extract docker fzf history colored-man-pages zsh-autocomplete zsh-autosuggestions zsh-syntax-highlighting)

# Performance: Skip compaudit security verification on every shell launch (saves ~280ms)
ZSH_DISABLE_COMPFIX="true"

# Keep PATH entries unique automatically
typeset -U path PATH

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
if [[ "$PWD" == "/" ]]; then
    cd ~
fi

# Lazy-load NVM and expose installed Node binaries directly to PATH for instant shell startup
export NVM_DIR="$HOME/.nvm"
for _node_dir in "$NVM_DIR"/versions/node/v*(N/n[-1]); do
    export PATH="$_node_dir/bin:$PATH"
done
unset _node_dir

_load_nvm() {
    unset -f nvm _load_nvm
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}
nvm() {
    _load_nvm
    nvm "$@"
}

export PATH="$PATH:$HOME/.spicetify"


# Added by Antigravity CLI installer
export PATH="$HOME/.local/bin:$PATH"
alias agy-ide='antigravity-ide'
alias agy-models='agy models'
alias agy-usage="agy -i '/usage'"

# WSL2 Quality-of-Life Integrations
alias pbcopy="clip.exe"
alias open="explorer.exe ."

# Modern CLI Tool Replacements (eza, bat, lazygit)
alias ls="eza --icons"
alias ll="eza -la --icons --git"
alias tree="eza --tree --icons"
alias cat="bat --paging=never"
alias lg="lazygit"
alias dotfiles="git -C ~/dotfiles"
alias reload="source ~/.zshrc && echo 'Config reloaded!'"

# Quad-Terminal 2x2 Grid via tmux
grid() {
    # If already inside tmux, switch to quad instead of failing to nest
    if [ -n "$TMUX" ]; then
        if tmux has-session -t quad 2>/dev/null; then
            tmux switch-client -t quad
        else
            echo "Inside tmux: detach or exit first to create a new grid."
        fi
        return 0
    fi

    # Quick reset option: `grid reset` or `grid -r`
    if [ "$1" = "reset" ] || [ "$1" = "-r" ]; then
        tmux kill-session -t quad 2>/dev/null && echo "Session 'quad' reset."
    fi

    if tmux has-session -t quad 2>/dev/null; then
        # -d detaches stale/minimized clients so the window resizes to full terminal
        tmux attach-session -d -t quad
    else
        tmux new-session -d -s quad
        tmux split-window -h -t quad
        tmux split-window -v -t quad
        tmux select-pane -t quad -L
        tmux split-window -v -t quad
        tmux select-layout -t quad tiled
        tmux select-pane -t quad -t 1
        tmux attach-session -d -t quad
    fi
}

# History Privacy & Optimization
setopt HIST_IGNORE_SPACE      # Don't save commands starting with space (for secrets/API keys)
setopt HIST_REDUCE_BLANKS     # Remove extra whitespace from history
setopt HIST_EXPIRE_DUPS_FIRST # Expire oldest duplicates first when trimming
setopt HIST_FIND_NO_DUPS      # Don't display duplicates when cycling history

# Autosuggestions Ergonomics (Ctrl+Space to accept, Gruvbox muted color)
bindkey '^ ' autosuggest-accept
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#928374"

# FZF Gruvbox Theme, Fast fd search & Interactive File Previews (Ctrl+T)
export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_DEFAULT_OPTS="
  --color=bg+:#3c3836,bg:#282828,spinner:#b8bb26,hl:#fabd2f
  --color=fg:#ebdbb2,header:#928374,info:#fabd2f,pointer:#d3869b
  --color=marker:#b8bb26,fg+:#fbf1c7,prompt:#83a598,hl+:#fabd2f
  --height 45% --layout=reverse --border"

export FZF_CTRL_T_OPTS="--preview 'bat --style=numbers --color=always --line-range :300 {} 2>/dev/null || eza --tree --level=2 --color=always {}'"

# Starship Prompt Initialization
eval "$(starship init zsh)"

# Machine-specific / private overrides (gitignored)
[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"

# Kiro CLI post block. Keep at the bottom of this file.
[[ -f "${HOME}/.local/share/kiro-cli/shell/zshrc.post.zsh" ]] && builtin source "${HOME}/.local/share/kiro-cli/shell/zshrc.post.zsh"
