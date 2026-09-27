"""Shared detection logic for credential-shaped strings in local stores.

Imported by ``scrub-secrets`` (redact) and ``check-secret-leaks`` (report).
Keep the key shapes here in one place so the two tools never drift apart.

Under WSL the same agent tools that run in Linux also keep caches on the
Windows side, reachable at ``/mnt/c/Users/<you>``. Those are included too, with
the Windows profile resolved at runtime (``wslvar``/``cmd.exe``, then a scan of
``/mnt/c/Users/*``) so nothing hardcodes a username or drive letter.
"""
from __future__ import annotations

import json
import os
import platform
import re
import shutil
import subprocess
from pathlib import Path

HOME = Path.home()

# (compiled pattern, replacement used when scrubbing, human label)
#
# GitHub fine-grained PATs are 93 characters: the 11-character "github_pat_"
# prefix plus 82 of [A-Za-z0-9_]. Matching that real length matters - a loose
# "{20,}" also matches documentation examples and test fixtures, which showed
# up as a daily false alarm in an agent transcript. Re-check this if GitHub
# ever changes the format.
PATTERNS = [
    (re.compile(r"github_pat_[A-Za-z0-9_]{82}"), "github_pat_REDACTED", "GitHub PAT"),
    (re.compile(r"sk-proj-[A-Za-z0-9_-]{30,}"), "sk-proj-REDACTED", "OpenAI key"),
    (re.compile(r"sk-or-v1-[A-Za-z0-9]{40,}"), "sk-or-v1-REDACTED", "OpenRouter key"),
    (re.compile(r"vck_[A-Za-z0-9]{40,}"), "vck_REDACTED", "Vercel key"),
]

# Known places where agent tools persist transcripts, history and caches.
DEFAULT_TARGETS = [
    ".config/manicode", ".config/opencode", ".cline", ".gemini", ".codex",
    ".claude", ".dsh", ".local/share/opencode", ".local/share/kilo",
    ".local/share/kiro-cli", ".local/share/atuin",
    ".vscode-server/data/User/History",
    ".vscode-server/data/User/globalStorage/github.copilot-chat",
    ".antigravity-ide-server/data/User/History",
    ".zsh_history",
]

# Windows-side equivalents, relative to the resolved Windows user profile.
WINDOWS_CACHE_RELPATHS = [
    ".claude", ".codex", ".continue", ".gemini", ".dsh", ".cursor",
    ".windsurf", ".aider",
    "AppData/Roaming/Code/User",
    "AppData/Roaming/Antigravity/User",
    "AppData/Roaming/Antigravity IDE/User",
    "AppData/Roaming/Kiro",
    "AppData/Roaming/gemini",
    "AppData/Local/OpenAI",
    "AppData/Local/kimi-code",
    "AppData/Local/cloud-code",
    "AppData/Local/antigravity",
]

# Paths that legitimately hold a real secret. Matched by suffix so they are
# exempt on both the Linux and the Windows side. Skipped unless --include-stores.
EXEMPT_SUFFIXES = (
    "/.zshrc.local",
    "/.dsh/.credentials.yaml",
    "/kilo/auth.json",
    # Live tool configs that may legitimately hold a key; scrub explicitly or
    # with --include-stores if you no longer use the key there.
    "/.claude/settings.json",
    "/.cline/data/settings/providers.json",
)
EXEMPT_DIR_SUFFIXES = ("/.secrets", "/.ssh", "/.config/gh", "/.copilot")

WALK_SKIP = {
    "node_modules", ".git", ".next", "dist", "build", "target", "site-packages",
    ".venv", "venv", ".cache", ".nvm", ".bun", ".cargo", ".rustup", ".npm",
    # Windows-side noise that never holds transcripts. Browser profiles are the
    # big one: a single .gemini/antigravity-browser-profile is several GB and is
    # pure cache, so skipping it roughly halves a /mnt/c sweep.
    "Cache", "CachedData", "CachedExtensionVSIXs", "GPUCache", "Code Cache",
    "Service Worker", "CachedProfilesData", "component_crx_cache",
    "antigravity-browser-profile",
}
# ripgrep never sees WALK_SKIP, so exclude the same dirs explicitly.
RG_EXCLUDES = [
    "!**/node_modules/**", "!**/.git/**", "!**/.cache/**", "!**/Cache/**",
    "!**/CachedData/**", "!**/CachedExtensionVSIXs/**", "!**/GPUCache/**",
    "!**/Code Cache/**", "!**/Service Worker/**",
    "!**/*browser-profile*/**", "!**/component_crx_cache/**",
]
MAX_BYTES = 1_100_000_000


# Byte-compiled twins: a str pattern cannot be applied to a bytes object, and
# SQLite blob columns and binary files need to be matched as raw bytes.
BYTE_PATTERNS = [(re.compile(pattern.pattern.encode()), replacement.encode())
                 for pattern, replacement, _ in PATTERNS]


def redact_text(text: str) -> str:
    for pattern, replacement, _ in PATTERNS:
        text = pattern.sub(replacement, text)
    return text


def redact_bytes(blob: bytes) -> bytes:
    for pattern, replacement in BYTE_PATTERNS:
        blob = pattern.sub(replacement, blob)
    return blob


def redact_bytes_samelen(blob: bytes) -> bytes:
    """Mask key shapes in place without changing the file length.

    Binary files (vendored CLIs, .exe runtimes) must not shift bytes, or
    offsets/signatures break. The filler is ``*``, which is outside every
    pattern's character class, so the masked text cannot re-match itself.
    """
    for pattern, replacement in BYTE_PATTERNS:
        def mask(match, _replacement=replacement):
            width = len(match.group(0))
            return (_replacement + b"*" * width)[:width]
        blob = pattern.sub(mask, blob)
    return blob


def labels_in(text: str) -> list[str]:
    """Human labels for every key shape present in ``text``."""
    return [label for pattern, _, label in PATTERNS if pattern.search(text)]


def matches(blob: bytes) -> bool:
    return bool(labels_in(blob.decode("utf-8", "replace")))


def is_exempt(path: Path, include_stores: bool = False) -> bool:
    if include_stores:
        return False
    text = str(path)
    if any(text.endswith(suffix) for suffix in EXEMPT_SUFFIXES):
        return True
    for part in (path, *path.parents):
        if any(str(part).endswith(suffix) for suffix in EXEMPT_DIR_SUFFIXES):
            return True
    return False


def _run(cmd: list[str], timeout: int = 10) -> str | None:
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        return None
    return proc.stdout.strip() or None


def is_wsl() -> bool:
    return "WSL_DISTRO_NAME" in os.environ or "microsoft" in platform.release().lower()


def windows_home() -> Path | None:
    """Resolve the Windows user profile as a WSL path, or None if unavailable."""
    if not is_wsl():
        return None
    for probe in (["wslvar", "USERPROFILE"],
                  ["cmd.exe", "/c", "echo", "%USERPROFILE%"]):
        profile = _run(probe)
        if not profile:
            continue
        converted = _run(["wslpath", "-u", profile])
        if converted:
            path = Path(converted)
            if path.is_dir():
                return path
    # Fallback: whichever profile under /mnt/c/Users looks like a real account.
    users = Path("/mnt/c/Users")
    if users.is_dir():
        for candidate in sorted(users.iterdir()):
            if candidate.name.startswith("Default") or candidate.name in {
                    "All Users", "Public", "WsiAccount"}:
                continue
            if (candidate / "AppData/Roaming").is_dir():
                return candidate
    return None


def windows_targets() -> list[Path]:
    """Existing Windows-side cache directories, or [] when not applicable."""
    home = windows_home()
    if not home:
        return []
    return [home / rel for rel in WINDOWS_CACHE_RELPATHS if (home / rel).is_dir()]


def default_targets(include_windows: bool = True) -> list[Path]:
    targets = [HOME / t for t in DEFAULT_TARGETS]
    if include_windows:
        targets += windows_targets()
    return targets


def walk(targets, include_stores: bool = False):
    """Yield candidate files under ``targets`` (deduplicated)."""
    seen: set[Path] = set()
    for target in targets:
        if target.is_file():
            if not is_exempt(target, include_stores):
                yield target
            continue
        if not target.is_dir():
            continue
        for root, dirs, files in os.walk(target):
            dirs[:] = [d for d in dirs if d not in WALK_SKIP
                       and not os.path.islink(os.path.join(root, d))]
            for name in files:
                path = Path(root) / name
                if path.is_symlink() or path in seen or is_exempt(path, include_stores):
                    continue
                seen.add(path)
                yield path


def _rg_matches(targets) -> dict[Path, list[str]] | None:
    """Fast path: let ripgrep report matching files *and* which shapes matched.

    ``-a`` treats binaries as text so SQLite stores are covered too, and ripgrep
    is roughly two orders of magnitude faster than reading every file in Python
    (it memory-maps and skips nothing it is told to consider). ``--json`` lets us
    take the labels straight from ripgrep, so large binaries are never read back
    into Python. Returns None when ripgrep is unavailable or fails.
    """
    rg = shutil.which("rg")
    if not rg:
        return None
    args = [rg, "-a", "--json", "--max-count", "50",
            "--hidden", "--no-ignore", "--no-messages"]
    for glob in RG_EXCLUDES:
        args += ["-g", glob]
    for pattern, _, _ in PATTERNS:
        args += ["-e", pattern.pattern]
    args += [str(t) for t in targets]
    try:
        proc = subprocess.run(args, capture_output=True, text=True, timeout=900)
    except (OSError, subprocess.TimeoutExpired):
        return None
    if proc.returncode not in (0, 1):  # 1 just means "no matches"
        return None
    found: dict[Path, list[str]] = {}
    for line in proc.stdout.splitlines():
        try:
            event = json.loads(line)
        except ValueError:
            continue
        if event.get("type") != "match":
            continue
        data = event["data"]
        path = Path(data["path"]["text"])
        matched = "".join(sub["match"]["text"] for sub in data.get("submatches", []))
        labels = found.setdefault(path, [])
        for pattern, _, label in PATTERNS:
            if label not in labels and pattern.search(matched):
                labels.append(label)
    return found


def _kind(path: Path) -> str:
    """Classify a file as 'sqlite', 'binary' or 'text' from a small header read.

    A NUL byte in the first block is ripgrep's own binary heuristic; files with
    one are masked in place rather than re-encoded, so nothing gets corrupted.
    """
    try:
        with open(path, "rb") as handle:
            head = handle.read(8192)
    except OSError:
        return "text"
    if head.startswith(b"SQLite format 3\x00"):
        return "sqlite"
    return "binary" if b"\x00" in head else "text"


def scan(targets, include_stores: bool = False):
    """Return (path, kind, labels) for each file containing key shapes.

    ``kind`` is "sqlite" for SQLite databases, else "text". Uses ripgrep to
    shortlist candidates when available, otherwise walks the tree in Python.
    """
    matches = _rg_matches(targets)
    if matches is not None:
        return [(path, _kind(path), labels)
                for path, labels in matches.items()
                if labels and not is_exempt(path, include_stores)]

    found = []
    for path in walk(targets, include_stores):
        if not _within_size(path):
            continue
        try:
            blob = path.read_bytes()
        except OSError:
            continue
        labels = labels_in(blob.decode("utf-8", "replace"))
        if labels:
            found.append((path, _kind(path), labels))
    return found


def _within_size(path: Path) -> bool:
    try:
        return path.stat().st_size <= MAX_BYTES
    except OSError:
        return False
