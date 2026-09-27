#!/bin/sh
# Regression tests for install.sh step 9: the ~/.npmrc unknown-key cleanup.
#
#     sh tests/test-install-npmrc.sh
#
# This step rewrites a hand-edited user config, so it has to be provably
# conservative: it must remove the stale keys and nothing else. The cases below
# pin down that, plus the skip branches for a machine without npm or without a
# ~/.npmrc.
#
# Each case runs install.sh inside a throwaway sandbox: a temp HOME, a PATH
# holding symlinks to the tools it needs, a stub `atuin` and `systemctl`, and a
# stub `npm` that reproduces npm's "Unknown user config" warning for a fixed set
# of keys. Nothing outside the sandbox is read or written.

set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH='' cd -- "$here/.." && pwd)
installer="$repo/install.sh"

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

contains() { # contains <haystack> <needle>   (fixed-string: patterns are regexes)
    printf '%s' "$1" | grep -qF -- "$2"
}

file_contains() { # file_contains <file> <needle>
    grep -q -- "$2" "$1"
}

# Byte-exact file comparison, via cmp: command substitution strips trailing
# newlines and would quietly break comparison against a here-document.
same_file() { # same_file <expected-text> <actual-file>
    printf '%s' "$1" >"$work/expected"
    cmp -s "$work/expected" "$2"
}

if ! command -v bash >/dev/null 2>&1; then
    printf 'SKIP: bash not found\n'
    exit 0
fi

# Everything install.sh shells out to, plus what step 9 needs.
SANDBOX_TOOLS='bash sh date mkdir ln readlink chmod rm cp cat head grep sed
               awk mktemp git wc tr uname env dirname basename find touch seq
               printf stty tty sort'

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Keys the stub npm reports as unknown. Everything else it knows about.
STALE_KEYS='ignore-workspace-root-check another-stale-key'

# Builds a sandbox and echoes its path. Arguments:
#   $1 sandbox name   $2 "npm" to provide the stub, "atuin" for the atuin stub,
#      "no-ohmyzsh" to leave oh-my-zsh absent, anything else for neither
make_sandbox() {
    root="$work/$1"
    mkdir -p "$root/home" "$root/bin"
    for tool in $SANDBOX_TOOLS; do
        real=$(command -v "$tool" 2>/dev/null) || continue
        ln -sf "$real" "$root/bin/$tool"
    done
    # Always fails `show-environment`, so the systemd step takes its skip branch
    # and no timer is enabled on the machine running the tests.
    printf '#!/bin/sh\nexit 1\n' >"$root/bin/systemctl"
    chmod +x "$root/bin/systemctl"
    if [ "${2:-}" = npm ]; then
        cat >"$root/bin/npm" <<EOF
#!/bin/sh
# Stands in for npm's config reader. Echoes npm's real warning for the stale
# keys, and nothing at all for any other key.
if [ "\${1:-}" = config ] && [ "\${2:-}" = get ]; then
    for stale in $STALE_KEYS; do
        if [ "\$3" = "\$stale" ]; then
            echo "npm warn Unknown user config \"\$3\". This will stop working in the next major version of npm." >&2
            echo undefined
            exit 0
        fi
    done
    echo "a-value"
    exit 0
fi
exit 0
EOF
        chmod +x "$root/bin/npm"
    fi
    if [ "${2:-}" = atuin ]; then
        printf '#!/bin/sh\nexit 0\n' >"$root/bin/atuin"
        chmod +x "$root/bin/atuin"
    fi
    if [ "${2:-}" != no-ohmyzsh ]; then
        for plugin in zsh-autosuggestions zsh-syntax-highlighting zsh-autocomplete; do
            mkdir -p "$root/home/.oh-my-zsh/custom/plugins/$plugin"
        done
    fi
    printf '%s' "$root"
}

# Runs the installer in a sandbox. run_install <sandbox> [path] -> installer
# stdout. The optional second argument narrows PATH, for the case that needs the
# real system directories to be invisible so that `command -v npm` fails.
run_install() {
    root=$1
    env -i \
        HOME="$root/home" \
        PATH="${2:-$root/bin:/usr/bin:/bin}" \
        ZSH="$root/home/.oh-my-zsh" \
        ZSH_CUSTOM="$root/home/.oh-my-zsh/custom" \
        TERM=dumb \
        bash "$installer" 2>&1 || true
}

# An npmrc mixing a stale key with settings that must survive untouched.
MIXED='loglevel=warn
progress=false
ignore-workspace-root-check=true
registry=https://registry.npmjs.org/
'

printf 'installer npmrc-step regression tests\n'

# --- removes the stale key and keeps everything else -----------------------
root=$(make_sandbox mixed npm)
printf '%s' "$MIXED" >"$root/home/.npmrc"
out=$(run_install "$root")
npmrc="$root/home/.npmrc"

check "mixed: reports the cleanup" "yes" \
      "$(yes_no contains "$out" 'Cleaning npm config of unknown keys')"
check "mixed: names the key it removed" "yes" \
      "$(yes_no contains "$out" 'ignore-workspace-root-check')"
check "mixed: drops the stale key" "no" \
      "$(yes_no file_contains "$npmrc" 'ignore-workspace-root-check')"
check "mixed: keeps loglevel" "yes" \
      "$(yes_no file_contains "$npmrc" '^loglevel=warn$')"
check "mixed: keeps progress" "yes" \
      "$(yes_no file_contains "$npmrc" '^progress=false$')"
check "mixed: keeps a value containing a slash and a colon" "yes" \
      "$(yes_no file_contains "$npmrc" '^registry=https://registry.npmjs.org/$')"
check "mixed: leaves no blank line where the key was" "yes" \
      "$(yes_no same_file 'loglevel=warn
progress=false
registry=https://registry.npmjs.org/
' "$npmrc")"

# --- several stale keys go in one pass, reported together -------------------
root2=$(make_sandbox multi npm)
printf 'loglevel=warn\nignore-workspace-root-check=true\nanother-stale-key = 1\n' \
    >"$root2/home/.npmrc"
out=$(run_install "$root2")
check "several: removes both" "yes" \
      "$(yes_no same_file 'loglevel=warn
' "$root2/home/.npmrc")"
check "several: reports the count" "yes" \
      "$(yes_no contains "$out" 'Removed 2 unknown key(s)')"

# --- is idempotent ---------------------------------------------------------
cp "$npmrc" "$work/before-recheck.npmrc"
out=$(run_install "$root")
check "re-run: says there is nothing to clean" "yes" \
      "$(yes_no contains "$out" 'No unknown keys in')"
check "re-run: leaves the file byte-identical" "yes" \
      "$(yes_no cmp -s "$work/before-recheck.npmrc" "$npmrc")"
backups=$(find "$root/home" -maxdepth 2 -name npmrc | wc -l | tr -d ' ')
check "re-run: no second backup of an unchanged file" "1" "$backups"

# --- backs up the file it is about to change --------------------------------
root3=$(make_sandbox backup npm)
printf '%s' "$MIXED" >"$root3/home/.npmrc"
run_install "$root3" >/dev/null
backup=$(find "$root3/home" -maxdepth 2 -path '*/.dotfiles_backup_*/npmrc' | head -n 1)
check "backup: a copy was kept" "yes" "$(yes_no test -n "$backup")"
check "backup: it is the pre-change content" "yes" \
      "$(yes_no same_file "$MIXED" "$backup")"

# --- comments and blank lines are not keys ----------------------------------
root4=$(make_sandbox comments npm)
printf '# keep me: ignore-workspace-root-check=true\n\nloglevel=warn\n  ignore-workspace-root-check=true\n' \
    >"$root4/home/.npmrc"
run_install "$root4" >/dev/null
check "comments: an indented stale key is still removed" "yes" \
      "$(yes_no same_file '# keep me: ignore-workspace-root-check=true

loglevel=warn
' "$root4/home/.npmrc")"

# --- skips when npm is not installed ----------------------------------------
root5=$(make_sandbox no-npm none)
printf '%s' "$MIXED" >"$root5/home/.npmrc"
# PATH is the sandbox bin alone, so the host's npm stays out of reach.
out=$(run_install "$root5" "$root5/bin")
check "no npm: skips with an explanation" "yes" \
      "$(yes_no contains "$out" 'npm not installed; nothing to clean')"
check "no npm: config left untouched" "yes" \
      "$(yes_no same_file "$MIXED" "$root5/home/.npmrc")"

# --- skips when there is no npmrc yet ---------------------------------------
root6=$(make_sandbox no-npmrc npm)
out=$(run_install "$root6")
check "no npmrc: skips with an explanation" "yes" \
      "$(yes_no contains "$out" 'No ~/.npmrc yet; nothing to clean')"
check "no npmrc: creates no npmrc" "no" \
      "$(yes_no test -e "$root6/home/.npmrc")"

# --- a clean npmrc is reported clean, not rewritten ------------------------
root7=$(make_sandbox clean npm)
printf 'loglevel=warn\nprogress=false\n' >"$root7/home/.npmrc"
out=$(run_install "$root7")
check "clean: reported as already clean" "yes" \
      "$(yes_no contains "$out" 'No unknown keys in')"
check "clean: no backup for a file it did not change" "0" \
      "$(find "$root7/home" -maxdepth 1 -name 'dotfiles_backup_*' | wc -l | tr -d ' ')"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
