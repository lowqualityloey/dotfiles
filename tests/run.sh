#!/bin/sh
# Run every test in this directory, then lint the shell scripts, and fail if
# anything is wrong.
#
#     sh tests/run.sh            # full output
#     sh tests/run.sh --quiet    # only failures and the summary
#
# Tests are discovered as tests/test-*.sh (run with sh) and tests/test_*.py (run
# with pytest when available, otherwise plain python3), so a new test only has to
# be dropped in the directory -- nothing to register here. Each test still exits
# non-zero on its own, so it can also be run alone. shellcheck is skipped with a
# note when it is not installed.

set -u

usage() {
    cat <<'EOF'
Usage: sh tests/run.sh [--quiet]

  -q, --quiet   print only failures and the summary
  -h, --help    show this help
EOF
}

quiet=0
for arg in "$@"; do
    case $arg in
        -q|--quiet) quiet=1 ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'run.sh: unknown option: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
    esac
done

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo=$(CDPATH='' cd -- "$here/.." && pwd)
python=${PYTHON:-python3}

# Prefer pytest for the Python tests when it is importable; otherwise run them as
# plain scripts (they are written to work either way).
if pytest_version=$("$python" -m pytest --version 2>/dev/null); then
    have_pytest=1
    pytest_version=$(printf '%s\n' "$pytest_version" | head -n 1)
else
    have_pytest=0
    pytest_version=''
fi

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

total=0
failed=0

run_one() { # run_one <label> <command...>
    label=$1
    shift
    total=$((total + 1))

    # Quiet mode: swallow a passing check, replay a failing one.
    if [ "$quiet" -eq 1 ] && "$@" >"$work/out" 2>&1; then
        return 0
    fi
    if [ "$quiet" -eq 1 ]; then
        printf 'FAILED: %s\n' "$label"
        cat "$work/out"
        failed=$((failed + 1))
        return 0
    fi

    printf '\n== %s ==\n' "$label"
    if "$@"; then
        printf 'ok: %s\n' "$label"
    else
        printf 'FAILED: %s\n' "$label"
        failed=$((failed + 1))
    fi
}

# Every shell script in the repo: install.sh, any bin/ script whose shebang is
# sh/bash (the python tools are skipped), and the tests themselves.
run_shellcheck() {
    if ! command -v shellcheck >/dev/null 2>&1; then
        printf 'shellcheck not installed; skipping lint\n'
        return 0
    fi
    set -- "$repo/install.sh"
    for candidate in "$repo"/bin/* "$repo"/tests/*.sh; do
        [ -f "$candidate" ] || continue
        head -n 1 "$candidate" | grep -Eq '^#!.*(/| )(bash|sh)([[:space:]]|$)' || continue
        set -- "$@" "$candidate"
    done
    shellcheck "$@"
}

for test in "$here"/test-*.sh; do
    [ -e "$test" ] || continue
    run_one "$(basename -- "$test")" sh "$test"
done

if [ "$have_pytest" -eq 1 ] && [ "$quiet" -eq 0 ]; then
    printf '\nPython tests: %s\n' "$pytest_version"
fi

for test in "$here"/test_*.py; do
    [ -e "$test" ] || continue
    if [ "$have_pytest" -eq 1 ]; then
        # -p no:cacheprovider keeps pytest from littering .pytest_cache.
        run_one "$(basename -- "$test") [pytest]" \
            "$python" -m pytest -q -p no:cacheprovider "$test"
    else
        run_one "$(basename -- "$test")" "$python" "$test"
    fi
done

run_one shellcheck run_shellcheck

printf '\n%s check(s) run, %s failed\n' "$total" "$failed"
[ "$failed" -eq 0 ]
