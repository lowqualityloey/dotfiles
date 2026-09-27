# Quiet drop-in for oh-my-zsh's bundled fzf plugin.
#
# The stock plugin initialises fzf with `eval "$(fzf --zsh)"` — with stderr
# attached. The script fzf generates snapshots the whole shell option set and
# restores it at the end, `zle` included, and zsh refuses to set `zle` in a
# non-TTY interactive shell (e.g. `zsh -i -c exit`). That prints two
# "can't change option: zle" lines on every such startup.
#
# This runs the identical integration with stderr suppressed: Ctrl+T, Ctrl+R
# and Alt+C behave exactly as before, without the noise. If fzf is absent the
# whole thing is skipped cleanly.
#
# The redirect has to sit on the `eval`, not on the command substitution: the
# warning is printed while the eval'd code runs, so `eval "$(fzf --zsh 2>/dev/null)"`
# does NOT silence it — only the trailing `2>/dev/null` does.
#
# install.sh links this to $ZSH_CUSTOM/plugins/fzf/fzf.plugin.zsh, which
# shadows the bundled plugin. Shadowing (rather than dropping `fzf` from
# $plugins and sourcing here) matters: fzf must load at its original position
# in the plugin list, because loading it later would steal Tab from
# zsh-autocomplete and Ctrl+R from atuin.

if (( $+commands[fzf] )); then
    eval "$(fzf --zsh 2>/dev/null)" 2>/dev/null
fi
