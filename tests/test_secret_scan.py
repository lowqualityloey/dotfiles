#!/usr/bin/env python3
"""Regression tests for secret_scan.py internals.

The two CLI tools are covered by tests/test-secret-leaks.sh; this file pins down
the shared module's own edge cases -- Windows-profile resolution, which cache
directories count as existing, and the WALK_SKIP pruning that both the ripgrep
and Python-fallback code paths depend on.

Runs either way: pytest collects the ``test_*`` functions, and
``python3 tests/test_secret_scan.py`` runs them without a framework. Either way
a failed ``check`` raises, so a mismatch can never pass silently. It
monkeypatches the module's globals, so nothing touches a real Windows profile,
/mnt/c, or the network.
"""
from __future__ import annotations

import contextlib
import os
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parent / "bin"))

import secret_scan as ss  # noqa: E402

TOKEN = "github_pat_" + "11" + "FAKE" * 20  # 93 chars: a real-shaped, fake PAT

PASS = 0
FAIL = 0


def check(description, expected, actual):
    """Assert equality, recording the outcome.

    Raises on a mismatch so both this file's own runner and pytest treat it as a
    failure -- a bare counter would let pytest report "passed" while checks fail.
    """
    global PASS, FAIL
    if expected == actual:
        print(f"  PASS  {description}")
        PASS += 1
        return
    FAIL += 1
    message = f"{description}: expected {expected!r}, got {actual!r}"
    print(f"  FAIL  {message}")
    raise AssertionError(message)


@contextlib.contextmanager
def patched(**attrs):
    """Temporarily replace module globals, then restore them."""
    saved = {name: getattr(ss, name) for name in attrs}
    for name, value in attrs.items():
        setattr(ss, name, value)
    try:
        yield
    finally:
        for name, value in saved.items():
            setattr(ss, name, value)


# --- windows_home ----------------------------------------------------------
def fake_runner(mapping):
    def fake(cmd, timeout=10):
        return mapping.get(tuple(cmd))

    return fake


def test_windows_home():
    with patched(is_wsl=lambda: False):
        check("windows_home: None when not WSL", None, ss.windows_home())

    with tempfile.TemporaryDirectory() as resolved:
        runner = fake_runner({
            ("wslvar", "USERPROFILE"): r"C:\Users\jonel",
            ("wslpath", "-u", r"C:\Users\jonel"): resolved,
        })
        with patched(is_wsl=lambda: True, _run=runner):
            check("windows_home: resolves via wslvar -> wslpath",
                  Path(resolved), ss.windows_home())

    # wslvar points at a profile that does not exist on this filesystem, so the
    # cmd.exe probe must be tried instead of returning the ghost path.
    with tempfile.TemporaryDirectory() as resolved:
        runner = fake_runner({
            ("wslvar", "USERPROFILE"): r"C:\Users\ghost",
            ("wslpath", "-u", r"C:\Users\ghost"): str(Path(resolved) / "ghost"),
            ("cmd.exe", "/c", "echo", "%USERPROFILE%"): r"C:\Users\jonel",
            ("wslpath", "-u", r"C:\Users\jonel"): resolved,
        })
        with patched(is_wsl=lambda: True, _run=runner):
            check("windows_home: skips a ghost profile, then resolves",
                  Path(resolved), ss.windows_home())

    # The last resort scans the hard-coded /mnt/c/Users. Only assert the None
    # outcome where that path genuinely does not exist (i.e. not under WSL).
    if not Path("/mnt/c/Users").is_dir():
        with patched(is_wsl=lambda: True, _run=lambda *a, **k: None):
            check("windows_home: None with no probes and no /mnt/c/Users",
                  None, ss.windows_home())


# --- windows_targets / default_targets -------------------------------------
def test_windows_targets():
    with tempfile.TemporaryDirectory() as tmp:
        home = Path(tmp)
        (home / ".claude").mkdir()
        (home / "AppData" / "Roaming" / "Code" / "User").mkdir(parents=True)
        # Exists, but as a file: only real directories are cache targets.
        (home / ".codex").write_text("not a directory")
        with patched(windows_home=lambda: home):
            check("windows_targets: existing dirs only, in declaration order",
                  [home / ".claude", home / "AppData/Roaming/Code/User"],
                  ss.windows_targets())

    with patched(windows_home=lambda: None):
        check("windows_targets: [] when no Windows home", [], ss.windows_targets())


def test_default_targets():
    with tempfile.TemporaryDirectory() as tmp:
        home = Path(tmp)
        base = [home / rel for rel in ss.DEFAULT_TARGETS]
        with patched(HOME=home, windows_home=lambda: None):
            check("default_targets: base caches, no Windows side",
                  base, ss.default_targets(include_windows=False))
        win = [home / ".claude"]
        with patched(HOME=home, windows_targets=lambda: list(win)):
            check("default_targets: appends Windows caches when requested",
                  base + win, ss.default_targets(include_windows=True))


# --- walk ------------------------------------------------------------------
def build_tree(root):
    (root / "keep.txt").write_text("keep")
    (root / "keepdir").mkdir()
    (root / "keepdir" / "nested.txt").write_text("nested")
    for skipped in ("node_modules", "Cache", "GPUCache", "Code Cache",
                    "Service Worker", "component_crx_cache",
                    "antigravity-browser-profile", ".venv"):
        (root / skipped).mkdir()
        (root / skipped / "leak.txt").write_text("leak")
    (root / ".git").mkdir()
    (root / ".git" / "config").write_text("x")
    (root / ".cache").mkdir()
    (root / ".cache" / "blob").write_text("x")
    (root / ".secrets").mkdir()
    (root / ".secrets" / "exempt.txt").write_text("secret")
    os.symlink(root / "keepdir", root / "linkdir")
    os.symlink(root / "keep.txt", root / "link.txt")


def rels(root, targets, include_stores=False):
    return sorted(p.relative_to(root).as_posix()
                  for p in ss.walk(targets, include_stores))


def test_walk():
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        build_tree(root)
        check("walk: prunes WALK_SKIP dirs and symlinks, honors exemptions",
              ["keep.txt", "keepdir/nested.txt"], rels(root, [root]))
        check("walk: include_stores reveals the .secrets store",
              [".secrets/exempt.txt", "keep.txt", "keepdir/nested.txt"],
              rels(root, [root], include_stores=True))
        check("walk: deduplicates repeated targets",
              ["keep.txt", "keepdir/nested.txt"], rels(root, [root, root]))

    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / ".secrets").mkdir()
        exempt = root / ".secrets" / "token.txt"
        exempt.write_text("t")
        plain = root / "notes.txt"
        plain.write_text("n")
        check("walk: explicit file target is yielded, exempt one skipped",
              ["notes.txt"], sorted(p.name for p in ss.walk([exempt, plain])))
        check("walk: include_stores yields the exempt file target",
              ["notes.txt", "token.txt"],
              sorted(p.name for p in ss.walk([exempt, plain], include_stores=True)))


# --- scan fallback ---------------------------------------------------------
def test_scan_fallback():
    """Without ripgrep, scan() walks the tree and must respect WALK_SKIP."""
    with tempfile.TemporaryDirectory() as tmp:
        root = Path(tmp)
        (root / "node_modules").mkdir()
        (root / "node_modules" / "leak.txt").write_text(TOKEN)
        (root / "visible.txt").write_text(TOKEN)
        with patched(_rg_matches=lambda targets: None):
            found = sorted(path.name for path, _kind, _labels in ss.scan([root]))
        check("scan: Python fallback honors WALK_SKIP", ["visible.txt"], found)


def test_pattern_lengths():
    """A real-length fine-grained PAT is flagged; a short lookalike is not.

    GitHub issues 93-character fine-grained PATs (an 11-character prefix plus
    82). Matching that length is what keeps documentation examples and test
    fixtures - which used to fire a daily false alarm in an agent transcript -
    out of the results.
    """
    full = "github_pat_" + "11" + "FAKE" * 20
    short = "github_pat_11FAKE0000FAKE0000FAKE0000"
    check("fixture: the real-shaped token is 93 chars", 93, len(full))
    check("scanner: flags a real-length token", ["GitHub PAT"], ss.labels_in(full))
    check("scanner: ignores a short lookalike", [], ss.labels_in(short))


TESTS = (test_windows_home, test_windows_targets, test_default_targets,
         test_walk, test_scan_fallback, test_pattern_lengths)


def main():
    print("secret_scan.py regression tests")
    broken = 0
    for test in TESTS:
        try:
            test()
        except AssertionError:
            broken += 1
    print(f"\n{PASS} passed, {FAIL} failed")
    return 1 if broken else 0


if __name__ == "__main__":
    raise SystemExit(main())
