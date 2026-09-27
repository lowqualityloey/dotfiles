#!/bin/sh
# Regression tests for bin/delta-pager.
#
# The wrapper's entire job is deciding whether to pass --side-by-side, so this
# stubs `delta` (and `tput`) on PATH and asserts the arguments delta would
# receive. No real delta and no terminal are required, so it runs anywhere:
#
#     sh tests/test-delta-pager.sh

set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
pager="$here/../bin/delta-pager"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mkdir -p "$tmp/bin"

# Records the arguments the wrapper decided to pass.
cat > "$tmp/bin/delta" <<'STUB'
#!/bin/sh
printf '%s\n' "$*"
STUB

# Deterministic width detection: only reports a width when FAKE_COLS is set,
# so results never depend on the terminal the tests happen to run in.
cat > "$tmp/bin/tput" <<'STUB'
#!/bin/sh
[ -n "${FAKE_COLS:-}" ] || exit 1
printf '%s\n' "$FAKE_COLS"
STUB

chmod +x "$tmp/bin/delta" "$tmp/bin/tput"

pass=0
fail=0

# run <COLUMNS> <FAKE_COLS> <MIN_COLS override> [extra wrapper args...]
run() {
    columns=$1
    fake_cols=$2
    min_cols=$3
    shift 3
    COLUMNS="$columns" FAKE_COLS="$fake_cols" DELTA_SIDE_BY_SIDE_MIN_COLS="$min_cols" \
        PATH="$tmp/bin:$PATH" sh "$pager" "$@" </dev/null
}

check() { # check <description> <expected> <actual>
    if [ "$3" = "$2" ]; then
        printf '  PASS  %s\n' "$1"
        pass=$((pass + 1))
    else
        printf '  FAIL  %s\n        expected: [%s]\n        actual:   [%s]\n' "$1" "$2" "$3"
        fail=$((fail + 1))
    fi
}

printf 'delta-pager regression tests\n'

check "120 columns -> side-by-side"        "--side-by-side" "$(run 120 "" "")"
check "exactly 100 -> side-by-side"        "--side-by-side" "$(run 100 "" "")"
check "99 columns -> unified"              ""               "$(run 99 "" "")"
check "no COLUMNS, no tty -> unified"      ""               "$(run "" "" "")"
check "garbage COLUMNS -> unified"         ""               "$(run "abc" "" "")"
check "tput width 120 -> side-by-side"     "--side-by-side" "$(run "" 120 "")"
check "tput width 80 -> unified"           ""               "$(run "" 80 "")"
check "override lowers threshold"          "--side-by-side" "$(run 60 "" 60)"
check "override raises threshold"          ""               "$(run 120 "" 140)"
check "extra args are forwarded"           "--side-by-side foo.patch" "$(run 120 "" "" foo.patch)"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
