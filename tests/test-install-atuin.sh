#!/bin/sh
# Regression tests for install.sh step 8: the atuin history_filter writer.
#
#     sh tests/test-install-atuin.sh
#
# This is the only installer step that rewrites a key inside a hand-edited user
# config, so it is the one most able to do damage: drop a line, mangle the TOML,
# or silently write a filter that drifts from what bin/secret_scan.py matches.
# It is also the step least covered, since running the real installer touches
# oh-my-zsh, systemd and global git config.
#
# Each case runs install.sh inside a throwaway sandbox: a temp HOME, a PATH
# holding symlinks to the tools it needs plus stub `atuin` and `systemctl`, and
# a pre-made oh-my-zsh so nothing is cloned and no timer is enabled. Nothing
# outside the sandbox is read or written. The repository is only ever *read*
# (install.sh links its own files into the sandbox home).

set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH='' cd -- "$here/.." && pwd)
installer="$repo/install.sh"
python=${PYTHON:-python3}

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

# Byte-exact file comparison. Done with cmp rather than `$(cat ...) == ...`
# because command substitution strips trailing newlines, which quietly breaks
# any comparison against a multi-line here-document.
same_file() { # same_file <expected-text> <actual-file>
    printf '%s' "$1" > "$work/expected"
    cmp -s "$work/expected" "$2"
}

# Everything install.sh shells out to. Symlinked so the sandbox PATH is short
# and predictable, and so `command -v` sees exactly these plus the stubs.
SANDBOX_TOOLS='bash sh date mkdir ln readlink chmod rm cp cat head grep sed
               awk mktemp git wc tr uname env dirname basename find touch seq
               printf stty tty'

if ! command -v bash >/dev/null 2>&1; then
    printf 'SKIP: bash not found\n'
    exit 0
fi
if ! "$python" -c 'import tomllib' 2>/dev/null; then
    printf 'SKIP: %s without tomllib (3.11+)\n' "$python"
    exit 0
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Builds a sandbox and echoes its path. Arguments:
#   $1 sandbox name   $2 "atuin" to provide the stub, anything else to omit it
make_sandbox() {
    root="$work/$1"
    mkdir -p "$root/home" "$root/bin"
    for tool in $SANDBOX_TOOLS; do
        real=$(command -v "$tool" 2>/dev/null) || continue
        ln -sf "$real" "$root/bin/$tool"
    done
    if [ "$2" = atuin ]; then
        printf '#!/bin/sh\nexit 0\n' > "$root/bin/atuin"
        chmod +x "$root/bin/atuin"
    fi
    # Always fails `show-environment`, so the systemd step takes its skip branch
    # and no timer is enabled on the machine running the tests.
    printf '#!/bin/sh\nexit 1\n' > "$root/bin/systemctl"
    chmod +x "$root/bin/systemctl"
    printf '%s' "$root"
}

# Runs the installer in a sandbox. run_install <sandbox> -> installer stdout
run_install() {
    root=$1
    env -i \
        HOME="$root/home" \
        PATH="$root/bin:/usr/bin:/bin" \
        ZSH="$root/home/.oh-my-zsh" \
        ZSH_CUSTOM="$root/home/.oh-my-zsh/custom" \
        TERM=dumb \
        bash "$installer" 2>&1 || true
}

# Creates a sandbox already holding an oh-my-zsh and an atuin config.
# prep <sandbox> [config-body]
prep() {
    root=$1
    mkdir -p "$root/home/.oh-my-zsh/custom/plugins/zsh-autosuggestions" \
             "$root/home/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" \
             "$root/home/.oh-my-zsh/custom/plugins/zsh-autocomplete" \
             "$root/home/.config/atuin"
    printf '%s' "${2:-# atuin config
max_history_size = 1000
}" > "$root/home/.config/atuin/config.toml"
}

# The block install.sh should have written, straight from the scanner.
expected_block() {
    "$python" - "$repo/bin" <<'PY'
import sys
sys.path.insert(0, sys.argv[1])
from secret_scan import PATTERNS
for pattern, _repl, label in PATTERNS:
    print(f'  "{pattern.pattern}",  # {label}')
PY
}

printf 'installer atuin-step regression tests\n'

# The contract, straight from bin/secret_scan.py: the filter atuin gets must be
# the same set of patterns the leak scanner uses, or the two silently disagree.
# Expected first, so a drift here fails before any installer output is trusted.
block=$(expected_block)
while IFS= read -r line; do
    check "scanner pattern reaches the filter: $line" "yes" \
          "$(yes_no contains "$block" "$line")"
done <<EOF
$block
EOF

# --- writes the key when the config has none -------------------------------
root=$(make_sandbox fresh atuin)
prep "$root"
out=$(run_install "$root")
cfg="$root/home/.config/atuin/config.toml"

check "no filter yet: reports it configured" "yes" \
      "$(yes_no contains "$out" 'history_filter configured in')"
check "no filter yet: adds the key" "yes" \
      "$(yes_no file_contains "$cfg" '^history_filter = \[')"
check "no filter yet: keeps unrelated settings" "yes" \
      "$(yes_no file_contains "$cfg" 'max_history_size = 1000')"
check "no filter yet: keeps the original comment" "yes" \
      "$(yes_no file_contains "$cfg" '# atuin config')"

# The result has to be valid TOML that parses to the scanner's patterns, not
# merely text that looks right.
parsed=$("$python" - "$cfg" <<'PY'
import sys, tomllib
with open(sys.argv[1], "rb") as fh:
    print(len(tomllib.load(fh).get("history_filter", [])))
PY
)
check "no filter yet: result parses as TOML with 4 filters" "4" "$parsed"

# --- is idempotent ----------------------------------------------------------
cp "$cfg" "$work/before-recheck.cfg"
out=$(run_install "$root")
check "re-run: reports already configured" "yes" \
      "$(yes_no contains "$out" 'history_filter already configured')"
check "re-run: leaves the file byte-identical" "yes" \
      "$(yes_no cmp -s "$work/before-recheck.cfg" "$cfg")"
# One backup per real change, not one per run.
backups=$(find "$root/home" -maxdepth 2 -name 'atuin-config.toml' | wc -l | tr -d ' ')
check "re-run: no second backup of an unchanged file" "1" "$backups"

# --- backs up the file it is about to change --------------------------------
orig='# atuin config
max_history_size = 1000
'
root2=$(make_sandbox backup atuin)
prep "$root2" "$orig"
run_install "$root2" >/dev/null
backup=$(find "$root2/home" -maxdepth 2 -name 'atuin-config.toml' | head -n 1)
check "backup: a copy was kept" "yes" "$(yes_no test -n "$backup")"
check "backup: it is the pre-change content" "yes" \
      "$(yes_no same_file "$orig" "$backup")"

# --- replaces a stale filter in place, keeping everything else ---------------
stale='# atuin config
max_history_size = 1000

history_filter = [
  "^secret-cmd",
]

[ui]
enable_transitions = true
'
root3=$(make_sandbox stale atuin)
prep "$root3" "$stale"
out=$(run_install "$root3")
cfg3="$root3/home/.config/atuin/config.toml"

check "stale filter: reports it configured" "yes" \
      "$(yes_no contains "$out" 'history_filter configured in')"
check "stale filter: drops the old entries" "no" \
      "$(yes_no file_contains "$cfg3" 'secret-cmd')"
check "stale filter: keeps the section below it" "yes" \
      "$(yes_no file_contains "$cfg3" '\[ui\]')"
check "stale filter: leaves exactly one history_filter key" "1" \
      "$(grep -c '^history_filter' "$cfg3" | tr -d ' ')"
check "stale filter: still valid TOML" "yes" \
      "$(yes_no "$python" -c 'import sys,tomllib;tomllib.load(open(sys.argv[1],"rb"))' "$cfg3")"

# --- a commented-out example is not a real key ------------------------------
commented='# atuin config
max_history_size = 1000

# history_filter = [
#   "^secret-cmd",
# ]
'
root4=$(make_sandbox commented atuin)
prep "$root4" "$commented"
run_install "$root4" >/dev/null
cfg4="$root4/home/.config/atuin/config.toml"
check "commented example: leaves the comments alone" "yes" \
      "$(yes_no file_contains "$cfg4" '#   "\^secret-cmd"')"
check "commented example: adds a real key" "1" \
      "$(grep -c '^history_filter' "$cfg4" | tr -d ' ')"

# --- skips when atuin is not installed --------------------------------------
root5=$(make_sandbox no-atuin other)
prep "$root5"
out=$(run_install "$root5")
check "no atuin: skips with an explanation" "yes" \
      "$(yes_no contains "$out" 'atuin not installed; nothing to configure')"
check "no atuin: config left untouched" "yes" \
      "$(yes_no same_file '# atuin config
max_history_size = 1000
' "$root5/home/.config/atuin/config.toml")"

# --- skips when there is no config yet --------------------------------------
root6=$(make_sandbox no-config atuin)
mkdir -p "$root6/home/.oh-my-zsh/custom"
out=$(run_install "$root6")
check "no config: skips and says how to fix it" "yes" \
      "$(yes_no contains "$out" "run 'atuin' once")"
check "no config: creates no config" "no" \
      "$(yes_no test -e "$root6/home/.config/atuin/config.toml")"

# --- the filters the installer writes are ones the scanner would match -------
# A pattern that is not a valid regex would make atuin fail to load its config
# at all, so each is compiled here exactly as atuin would.
compiled=$("$python" - "$cfg" <<'PY'
import re, sys, tomllib
with open(sys.argv[1], "rb") as fh:
    filters = tomllib.load(fh)["history_filter"]
for pattern in filters:
    try:
        re.compile(pattern)
    except re.error:
        print("BAD:" + pattern)
print("OK")
PY
)
check "written filters all compile as regexes" "OK" "$compiled"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
