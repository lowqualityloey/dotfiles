#!/bin/sh
# Regression test for .zshrc: an interactive shell must start cleanly.
#
#     sh tests/test-zsh-startup.sh
#
# Why this exists: zsh aborts the remainder of a sourced file at the first
# parse error, and it does so *silently* -- "zsh -i -c exit" still returns 0 and
# the messages only appear on stderr. A single bad line can therefore disable
# everything below it and leave a working-looking shell. The bug that motivated
# this test was defining `gst() { ... }` when oh-my-zsh's git plugin had already
# defined a `gst` alias: zsh refuses to define a function over an alias, and the
# parse error killed the rest of the config.
#
# Two layers:
#   1. `zsh -n` parses the real .zshrc without running it. Cheap, needs no
#      oh-my-zsh, so it runs everywhere including CI.
#   2. A real interactive startup, using a *copy* of the config in a temporary
#      ZDOTDIR so the live ~/.zshrc is never touched. Needs oh-my-zsh and the
#      installed plugins, so it is skipped when they are absent.
#
# The detector itself is verified against synthetic fixtures first. Without that,
# this test would pass forever if the check quietly stopped working -- which is
# exactly how a regression test becomes a decoration.

set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH='' cd -- "$here/.." && pwd)
zshrc="$repo/.zshrc"

pass=0
fail=0

check() { # check <description> <expected> <actual>
    if [ "$3" = "$2" ]; then
        printf '  PASS  %s\n' "$1"
        pass=$((pass + 1))
    else
        printf '  FAIL  %s\n        expected: [%s]\n        actual:   [%s]\n' "$1" "$2" "$3"
        fail=$((fail + 1))
    fi
}

yes_no() {
    if "$@"; then printf yes; else printf no; fi
}

grep_any() { # grep_any <file> <extended-regex>
    grep -Eq -- "$2" "$1"
}

printf 'zsh startup regression tests\n'

if ! command -v zsh >/dev/null 2>&1; then
    printf 'SKIP: zsh not installed\n'
    exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Runs an interactive zsh against a config file and reports what went wrong.
#   startup <config-file> <prefix-tag>
# Sets: <prefix-tag>.err   stderr of the interactive shell
#       <prefix-tag>.ran   lines the config printed before it was torn down
startup() {
    _dir="$work/$2"
    mkdir -p "$_dir"
    cp "$1" "$_dir/.zshrc"
    ZDOTDIR="$_dir" zsh -i -c exit >"$work/$2.ran" 2>"$work/$2.err" || true
}

# True when the interactive shell reported a parse error or a refused function
# definition. Both mean the rest of .zshrc was skipped.
has_parse_error() { # has_parse_error <err-file>
    grep_any "$1" 'parse error|defining function based on alias|unmatched|condition expected'
}

# --- the detector works, before trusting it on the real config --------------
# Fixture 1 reproduces the original bug: a function defined over an alias.
cat > "$work/broken-alias.zsh" <<'EOF'
echo MARKER_BEFORE
alias gst="git status"
gst() { git status; }
echo MARKER_AFTER
EOF
startup "$work/broken-alias.zsh" fix1
check "control: alias/function clash is detected" "yes" \
      "$(yes_no has_parse_error "$work/fix1.err")"
# The important half: the rest of the file really was abandoned.
check "control: clash aborts the rest of the config" "no" \
      "$(yes_no grep -q MARKER_AFTER "$work/fix1.ran")"

# Fixture 2 is a plain unmatched brace, the other common way to break a config.
cat > "$work/broken-syntax.zsh" <<'EOF'
echo MARKER_BEFORE
if true; then
echo MARKER_AFTER
EOF
startup "$work/broken-syntax.zsh" fix2
check "control: unbalanced construct is detected" "yes" \
      "$(yes_no has_parse_error "$work/fix2.err")"
check "control: unbalanced construct aborts the rest" "no" \
      "$(yes_no grep -q MARKER_AFTER "$work/fix2.ran")"

# Fixture 3 is clean, so a detector that flags everything is caught.
cat > "$work/clean.zsh" <<'EOF'
alias gst="git status"
grid() { echo quad; }
echo MARKER_AFTER
EOF
startup "$work/clean.zsh" fix3
check "control: clean config reports no error" "no" \
      "$(yes_no has_parse_error "$work/fix3.err")"
check "control: clean config runs to completion" "yes" \
      "$(yes_no grep -q MARKER_AFTER "$work/fix3.ran")"

# --- layer 1: static parse of the real .zshrc ------------------------------
# `zsh -n` catches gross syntax damage without executing anything. It does NOT
# catch the alias/function clash above (verified), which is why layer 2 exists.
zsh -n "$zshrc" 2>"$work/parse.err" && parse_rc=0 || parse_rc=$?
check ".zshrc parses (zsh -n)" "0" "$parse_rc"
check ".zshrc static parse is silent" "no" \
      "$(yes_no has_parse_error "$work/parse.err")"

# --- layer 2: real interactive startup -------------------------------------
# Needs oh-my-zsh, which the plugins and the git aliases come from.
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    printf 'SKIP: interactive startup (oh-my-zsh not installed)\n'
else
    # A trailing marker proves the whole file ran. Without it a mid-file parse
    # error looks identical to a clean start, because the shell still exits 0.
    cp "$zshrc" "$work/live.zsh"
    printf '\nprintf "%%s\\n" MARKER_END_OF_ZSHRC\n' >> "$work/live.zsh"
    startup "$work/live.zsh" live

    check "interactive startup reports no parse error" "no" \
          "$(yes_no has_parse_error "$work/live.err")"
    check "interactive startup reaches the end of .zshrc" "yes" \
          "$(yes_no grep -q MARKER_END_OF_ZSHRC "$work/live.ran")"

    # Whatever is on stderr should not be an error message either.
    check "interactive startup stderr is empty" "0" \
          "$(wc -c < "$work/live.err" | tr -d ' ')"

    # A few things defined late in the file, so a truncated config is caught
    # even if the parse error itself is ever swallowed.
    probe='(( $+functions[grid] )) && print -r -- "grid:function" || print -r -- "grid:missing"
           alias dotfiles >/dev/null 2>&1 && print -r -- "dotfiles:alias" || print -r -- "dotfiles:missing"
           alias reload >/dev/null 2>&1 && print -r -- "reload:alias" || print -r -- "reload:missing"'
    ZDOTDIR="$work/live" zsh -i -c "$probe" 2>/dev/null > "$work/probe.out" || true
    for pair in grid:function dotfiles:alias reload:alias; do
        check "defined after startup: $pair" "yes" \
              "$(yes_no grep -qx "$pair" "$work/probe.out")"
    done
fi

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
