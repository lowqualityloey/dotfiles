#!/bin/sh
# Regression tests for git/hooks/commit-msg and bin/install-commit-msg-hook.
#
# Builds throwaway repositories in a temp directory, so no real repo, identity,
# or remote is touched:
#
#     sh tests/test-commit-msg-hook.sh

set -eu

here=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH='' cd -- "$here/.." && pwd)
hook="$repo_root/git/hooks/commit-msg"
installer="$repo_root/bin/install-commit-msg-hook"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

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

# git with a throwaway identity and no user/system config, so a machine without
# a global user.name still runs these.
git_() {
    GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null \
        git -c user.name='Test User' -c user.email='test@example.com' "$@"
}

new_repo() { # new_repo <dir>
    git_ init -q "$1"
}

printf 'commit-msg hook regression tests\n'

# --- The hook on its own -----------------------------------------------------
# Run the message through the hook directly so the assertions are about the
# exact bytes, not about git's cleanup or editor handling.

msg="$tmp/msg"
run_hook() { # run_hook <message>
    printf '%s\n' "$1" >"$msg"
    sh "$hook" "$msg" 2>/dev/null
    cat "$msg"
}

full='feat: add the thing

Body line stays.

🤖 Generated with Codebuff
Co-Authored-By: Codebuff <noreply@codebuff.com>'

check "footer and robot line removed" \
    'feat: add the thing

Body line stays.' \
    "$(run_hook "$full")"

check "human co-author preserved" \
    'fix: resolve race

Co-Authored-By: Jane Doe <jane@example.com>' \
    "$(run_hook 'fix: resolve race

Co-Authored-By: Jane Doe <jane@example.com>')"

check "freebuff variant removed" \
    'chore: tidy' \
    "$(run_hook 'chore: tidy

Generated with Freebuff 🤖')"

# The hook runs under whatever grep and locale Git provides, and GNU grep 2.x
# with a multibyte pattern silently stops matching under a UTF-8 locale -- the
# exact combination Git for Windows uses. Assert both locales explicitly.
for locale in C C.UTF-8; do
    printf '%s\n' 'feat: locale' '' '🤖 Generated with Codebuff' >"$msg"
    LC_ALL="$locale" sh "$hook" "$msg" 2>/dev/null
    check "robot line removed under LC_ALL=$locale" 'feat: locale' "$(cat "$msg")"
done

check "metadata preserved verbatim" \
    'docs: explain the hook

HeyLoey-Milestone: shipped the hook' \
    "$(run_hook 'docs: explain the hook

HeyLoey-Milestone: shipped the hook')"

# A clean message must come through byte-for-byte, including no added blank line.
printf 'subject only\n' >"$msg"
before=$(od -An -c "$msg")
sh "$hook" "$msg" >/dev/null
check "clean message untouched" "$before" "$(od -An -c "$msg")"

# --- The installer ------------------------------------------------------------

existing="$tmp/existing"
new_repo "$existing"
"$installer" "$existing" >"$tmp/install.log" 2>&1
check "installer creates the hook" "yes" "$([ -x "$existing/.git/hooks/commit-msg" ] && echo yes || echo no)"

printf 'feat: via git\n\n🤖 Generated with Codebuff\nCo-Authored-By: Codebuff <noreply@codebuff.com>\n' \
    >"$existing/message.txt"
git_ -C "$existing" commit -q --allow-empty -F message.txt
check "real commit is clean" 'feat: via git' "$(git_ -C "$existing" log -1 --format=%B)"

# Re-running is idempotent: same bytes, no backup piling up.
before=$(cksum <"$existing/.git/hooks/commit-msg")
"$installer" "$existing" >"$tmp/reinstall.log" 2>&1
check "reinstall leaves the hook unchanged" "$before" "$(cksum <"$existing/.git/hooks/commit-msg")"
check "reinstall adds no backup" "no" \
    "$(ls "$existing"/.git/hooks/commit-msg.backup.* >/dev/null 2>&1 && echo yes || echo no)"

guarded="$tmp/guarded"
new_repo "$guarded"
printf '#!/bin/sh\nexit 0\n' >"$guarded/.git/hooks/commit-msg"
chmod +x "$guarded/.git/hooks/commit-msg"
"$installer" "$guarded" >"$tmp/guarded.log" 2>&1
check "foreign hook is skipped" "yes" \
    "$(grep -q '\[SKIP\]' "$tmp/guarded.log" && grep -q 'exit 0' "$guarded/.git/hooks/commit-msg" && echo yes || echo no)"

"$installer" --force "$guarded" >"$tmp/force.log" 2>&1
check "force backs up and replaces" "yes" \
    "$(ls "$guarded"/.git/hooks/commit-msg.backup.* >/dev/null 2>&1 && grep -qF 'Strip AI attribution' "$guarded/.git/hooks/commit-msg" && echo yes || echo no)"

printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
