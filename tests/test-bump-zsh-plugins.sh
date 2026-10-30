#!/bin/sh
# Regression tests for bin/bump-zsh-plugins.
#
# A fake git on PATH serves deterministic upstream HEADs and records fetch
# success or failure, so these tests never touch the network or the real lock
# file:
#
#     sh tests/test-bump-zsh-plugins.sh

set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
tool="$here/../bin/bump-zsh-plugins"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

pass=0
fail=0

check() { # check <description> <expected> <actual>
    if [ "$3" = "$2" ]; then
        printf '  PASS  %s\n' "$1"
        pass=$((pass + 1))
    else
        printf '  FAIL  %s\n        expected: [%s]\n        actual:   [%s]\n' \
            "$1" "$2" "$3"
        fail=$((fail + 1))
    fi
}

check_contains() { # check_contains <description> <text>
    if grep -Fq "$2" "$tmp/out"; then
        printf '  PASS  %s\n' "$1"
        pass=$((pass + 1))
    else
        printf '  FAIL  %s\n        not found: [%s]\n' "$1" "$2"
        fail=$((fail + 1))
    fi
}

check_file_contains() { # check_file_contains <description> <file> <text>
    if grep -Fq "$3" "$2"; then
        printf '  PASS  %s\n' "$1"
        pass=$((pass + 1))
    else
        printf '  FAIL  %s\n        not found in %s: [%s]\n' "$1" "$2" "$3"
        fail=$((fail + 1))
    fi
}

check_file_not_contains() { # check_file_not_contains <description> <file> <text>
    if grep -Fq "$3" "$2"; then
        printf '  FAIL  %s\n        unexpectedly found in %s: [%s]\n' "$1" "$2" "$3"
        fail=$((fail + 1))
    else
        printf '  PASS  %s\n' "$1"
        pass=$((pass + 1))
    fi
}

file_state() { # file_state <a> <b>
    if cmp -s "$1" "$2"; then
        printf 'unchanged'
    else
        printf 'changed'
    fi
}

repeat() { # repeat <character> <count>
    printf '%*s' "$2" '' | tr ' ' "$1"
}

old_omz=$(repeat 1 40)
old_auto=$(repeat 2 40)
old_syntax=$(repeat 3 40)
old_fzf=$(repeat 4 40)
new_omz=$(repeat a 40)
new_auto=$(repeat b 40)
new_syntax=$(repeat c 40)
new_fzf=$(repeat d 40)
today=$(date +%Y-%m-%d)

mkdir -p "$tmp/bin"
export FAKE_HEADS="$tmp/heads"

cat > "$tmp/bin/git" <<'STUB'
#!/bin/sh
set -eu

case ${1:-} in
    init)
        exit 0
        ;;
    ls-remote)
        url=
        for arg in "$@"; do
            case $arg in
                https://*) url=$arg ;;
            esac
        done
        if [ -n "${FAKE_FAIL_LSREMOTE:-}" ] && [ "$url" = "$FAKE_FAIL_LSREMOTE" ]; then
            exit 128
        fi
        sha=$(awk -v u="$url" '$1 == u { print $2; exit }' "$FAKE_HEADS")
        [ -n "$sha" ] || exit 128
        printf '%s\tHEAD\n' "$sha"
        ;;
    -C)
        shift 2
        [ "${1:-}" = fetch ] || exit 1
        url=
        sha=
        for arg in "$@"; do
            case $arg in
                https://*) url=$arg ;;
            esac
            sha=$arg
        done
        if [ -n "${FAKE_FAIL_FETCH:-}" ] \
            && { [ "$url" = "$FAKE_FAIL_FETCH" ] || [ "$sha" = "$FAKE_FAIL_FETCH" ]; }; then
            exit 1
        fi
        ;;
    *)
        exit 1
        ;;
esac
STUB
chmod +x "$tmp/bin/git"

write_lock() {
    cat > "$tmp/lock" <<EOF
# Pinned zsh dependencies for the CI zsh startup test.
#
# Format: <github repo> <path under \$HOME> <full commit SHA>
# Pinned 2020-01-01.
ohmyzsh/ohmyzsh .oh-my-zsh $old_omz
zsh-users/zsh-autosuggestions .oh-my-zsh/custom/plugins/zsh-autosuggestions $old_auto
zsh-users/zsh-syntax-highlighting .oh-my-zsh/custom/plugins/zsh-syntax-highlighting $old_syntax
Aloxaf/fzf-tab .oh-my-zsh/custom/plugins/fzf-tab $old_fzf
EOF
}

write_heads() { # write_heads <omz> <auto> <syntax> <fzf>
    cat > "$tmp/heads" <<EOF
https://github.com/ohmyzsh/ohmyzsh.git $1
https://github.com/zsh-users/zsh-autosuggestions.git $2
https://github.com/zsh-users/zsh-syntax-highlighting.git $3
https://github.com/Aloxaf/fzf-tab.git $4
EOF
}

run() {
    set +e
    PATH="$tmp/bin:$PATH" ZSH_PLUGINS_LOCK="$tmp/lock" sh "$tool" "$@" >"$tmp/out" 2>&1
    rc=$?
    set -e
}

printf 'bump-zsh-plugins regression tests\n'

run --help
check 'help exits 0' 0 "$rc"
check_contains 'help prints usage' 'Usage: bin/bump-zsh-plugins'

run --nope
check 'unknown option exits 2' 2 "$rc"
check_contains 'unknown option is named' 'unknown option: --nope'

write_lock
write_heads "$new_omz" "$new_auto" "$new_syntax" "$new_fzf"
run --check
check 'valid pins exit 0' 0 "$rc"
check_contains 'valid pins are counted' 'All 4 pin(s) are valid.'

cp "$tmp/lock" "$tmp/before"
export FAKE_FAIL_FETCH='https://github.com/zsh-users/zsh-syntax-highlighting.git'
run --check
unset FAKE_FAIL_FETCH
check 'unfetchable pin exits nonzero' 1 "$rc"
check_contains 'unfetchable pin is explained' 'cannot fetch'
check 'unfetchable pin leaves lock unchanged' unchanged \
    "$(file_state "$tmp/lock" "$tmp/before")"

write_lock
sed "s/$old_omz/1234/" "$tmp/lock" > "$tmp/lock.new"
mv "$tmp/lock.new" "$tmp/lock"
run --check
check 'short SHA exits nonzero' 1 "$rc"
check_contains 'short SHA is explained' 'expected a full lowercase 40-character SHA'

write_lock
sed 's# \.oh-my-zsh/custom/plugins/fzf-tab # ../outside #' "$tmp/lock" > "$tmp/lock.new"
mv "$tmp/lock.new" "$tmp/lock"
run --check
check 'path traversal exits nonzero' 1 "$rc"
check_contains 'path traversal is explained' "destination must not contain '..'"

write_lock
printf '%s\n' "Aloxaf/fzf-tab .oh-my-zsh/custom/plugins/fzf-tab $new_fzf" >> "$tmp/lock"
run
check 'duplicate destination exits nonzero' 1 "$rc"
check_contains 'duplicate destination is explained' 'duplicate destination'

write_lock
write_heads "$new_omz" "$new_auto" "$new_syntax" "$new_fzf"
cp "$tmp/lock" "$tmp/before"
run
check 'plan exits 0' 0 "$rc"
check_contains 'plan shows the first update' \
    "ohmyzsh/ohmyzsh: $old_omz -> $new_omz"
check_contains 'plan shows the last update' \
    "Aloxaf/fzf-tab: $old_fzf -> $new_fzf"
check 'plan leaves lock unchanged' unchanged \
    "$(file_state "$tmp/lock" "$tmp/before")"

write_lock
cp "$tmp/lock" "$tmp/before"
export FAKE_FAIL_LSREMOTE='https://github.com/zsh-users/zsh-autosuggestions.git'
run --write
unset FAKE_FAIL_LSREMOTE
check 'failed resolution exits nonzero' 1 "$rc"
check_contains 'failed resolution is explained' 'could not resolve upstream HEAD'
check 'failed resolution leaves lock unchanged' unchanged \
    "$(file_state "$tmp/lock" "$tmp/before")"

write_lock
cp "$tmp/lock" "$tmp/before"
write_heads "$old_omz" "$old_auto" "$old_syntax" "$old_fzf"
run --write
check 'no-change write exits 0' 0 "$rc"
check_contains 'no-change write reports up to date' 'Lock is already up to date.'
check 'no-change write leaves lock unchanged' unchanged \
    "$(file_state "$tmp/lock" "$tmp/before")"

write_lock
write_heads "$new_omz" "$new_auto" "$new_syntax" "$new_fzf"
run --write
check 'write exits 0' 0 "$rc"
check_file_contains 'write updates the first pin' "$tmp/lock" \
    "ohmyzsh/ohmyzsh .oh-my-zsh $new_omz"
check_file_contains 'write updates the last pin' "$tmp/lock" \
    "Aloxaf/fzf-tab .oh-my-zsh/custom/plugins/fzf-tab $new_fzf"
check_file_contains 'write keeps the header' "$tmp/lock" \
    '# Pinned zsh dependencies for the CI zsh startup test.'
check_file_contains 'write refreshes the pinned date' "$tmp/lock" \
    "# Pinned $today."
check_file_not_contains 'write drops the old pinned date' "$tmp/lock" \
    '# Pinned 2020-01-01.'
check_file_not_contains 'write removes the old first pin' "$tmp/lock" "$old_omz"
check_file_not_contains 'write removes the old last pin' "$tmp/lock" "$old_fzf"
check 'write keeps four rows' 4 "$(grep -vc '^#' "$tmp/lock")"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
