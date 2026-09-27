#!/bin/sh
# Regression tests for the credential-leak scanner: bin/check-secret-leaks
# (report) and bin/scrub-secrets (redact), which share bin/secret_scan.py.
#
# Both tools accept explicit paths, so every case runs inside a throwaway temp
# directory holding token-shaped *fakes*. No real home directory, real secret,
# network, or Windows-side cache is read or written:
#
#     sh tests/test-secret-leaks.sh

set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
checker="$here/../bin/check-secret-leaks"
scrubber="$here/../bin/scrub-secrets"
python=${PYTHON:-python3}

if ! command -v "$python" >/dev/null 2>&1; then
    printf 'SKIP: %s not found\n' "$python"
    exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

leaks="$tmp/leaks"
clean="$tmp/clean"
mkdir -p "$leaks/.secrets" "$clean"

# 93 characters - the real shape of a GitHub fine-grained PAT (11-char prefix
# plus 82) - and obviously not a real credential. Built rather than typed so
# the length cannot drift away from what the scanner matches.
token="github_pat_11$(printf 'FAKE%.0s' $(seq 20))"

# One file of each kind the scanner has to handle, plus one under an exempt
# credential-store directory and one genuinely clean file.
printf 'session transcript\napi=%s\n' "$token" > "$leaks/text.log"
printf '\000\001runtime bytes\nkey=%s\000\n' "$token" > "$leaks/binary.bin"
printf 'stored: %s\n' "$token" > "$leaks/.secrets/exempt.txt"
printf 'nothing to see here\n' > "$clean/notes.txt"

"$python" - "$leaks/store.db" "$token" <<'PY'
import sqlite3
import sys

path, token = sys.argv[1], sys.argv[2]
conn = sqlite3.connect(path)
conn.execute("create table sessions (id integer primary key, note text, blob blob)")
conn.execute("insert into sessions (note, blob) values (?, ?)",
             (f"api={token}", f"key={token}".encode()))
conn.commit()
conn.close()
PY

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

# Runs a tool, capturing stdout+stderr in $out and exit status in $rc.
run() {
    out=$("$@" 2>&1) && rc=0 || rc=$?
}

# yes_no <0-if-true-command> -> "yes"/"no" without tripping `set -e`.
yes_no() {
    if "$@"; then printf yes; else printf no; fi
}

contains() { # contains <haystack> <needle>
    printf '%s' "$1" | grep -q -- "$2"
}

file_contains() { # file_contains <file> <needle>
    grep -aq -- "$2" "$1"
}

size() { # size <file>
    wc -c < "$1" | tr -d ' '
}

printf 'credential-leak scanner regression tests\n'

# --- reporting -------------------------------------------------------------
run "$python" "$checker" "$clean"
check "clean dir: exit 0" "0" "$rc"
check "clean dir: reports nothing found" "yes" \
      "$(yes_no contains "$out" 'No credential-shaped strings found.')"

run "$python" "$checker" "$leaks"
check "leaky dir: exit 1" "1" "$rc"
for needle in 'text.log' '(text)' 'binary.bin' '(binary)' 'store.db' '(sqlite)' \
              'GitHub PAT' '3 file(s) affected'; do
    check "leaky dir: reports $needle" "yes" \
          "$(yes_no contains "$out" "$needle")"
done
check "exempt store: skipped by default" "no" \
      "$(yes_no contains "$out" 'exempt.txt')"

run "$python" "$checker" --include-stores "$leaks"
check "--include-stores: exit 1" "1" "$rc"
check "--include-stores: reports exempt store" "yes" \
      "$(yes_no contains "$out" 'exempt.txt')"
check "--include-stores: counts 4 files" "yes" \
      "$(yes_no contains "$out" '4 file(s) affected')"

run "$python" "$checker" --quiet "$clean"
check "--quiet clean: exit 0" "0" "$rc"
check "--quiet clean: prints nothing" "" "$out"

# --- dry run ---------------------------------------------------------------
before_text=$(size "$leaks/text.log")
before_binary=$(size "$leaks/binary.bin")

run "$python" "$scrubber" "$leaks"
check "dry run: exit 0" "0" "$rc"
check "dry run: reports per-kind counts" "yes" \
      "$(yes_no contains "$out" 'would redact: 1 text, 1 binary (in-place, length-preserving), 1 sqlite')"
check "dry run: leaves text file byte-identical" "$before_text" "$(size "$leaks/text.log")"
check "dry run: leaves binary file byte-identical" "$before_binary" "$(size "$leaks/binary.bin")"
run "$python" "$checker" "$leaks"
check "dry run: nothing was actually redacted" "1" "$rc"

# --- apply -----------------------------------------------------------------
before_binary_size=$(size "$leaks/binary.bin")

run "$python" "$scrubber" --apply "$leaks"
check "apply: exit 0" "0" "$rc"
check "apply: reports per-kind counts" "yes" \
      "$(yes_no contains "$out" 'redacting: 1 text, 1 binary (in-place, length-preserving), 1 sqlite')"
check "apply: token gone from text file" "no" \
      "$(yes_no file_contains "$leaks/text.log" "$token")"
check "apply: token gone from binary file" "no" \
      "$(yes_no file_contains "$leaks/binary.bin" "$token")"
check "apply: binary file stays the same length" "$before_binary_size" "$(size "$leaks/binary.bin")"

run "$python" "$checker" "$leaks"
check "after apply: re-check is clean" "0" "$rc"
check "after apply: reports nothing found" "yes" \
      "$(yes_no contains "$out" 'No credential-shaped strings found.')"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
