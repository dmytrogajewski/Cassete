#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Dead code checker for Vala: reports symbols defined in production code that
are not used in production (unused in the app). This includes symbols used
only in tests or unused anywhere.

Usage: python3 deadcode_checker.py <project_root>
Exit: 0 if no dead code, 1 if any unused symbol is found.
"""

import os
import re
import sys
from pathlib import Path


# Paths under these dirs are "production" (app + in-tree libs)
PRODUCTION_ROOTS = ["src", "subprojects/libtape/lib", "subprojects/libapi-base/lib"]

# Path segments that mean "test code" (references here don't count as production use)
TEST_PATH_SEGMENTS = ["/tests/", os.sep + "tests" + os.sep]
# Path prefixes that mean "test code" (e.g. top-level tests/ directory)
TEST_PATH_PREFIXES = ("tests/", "tests" + os.sep)

# Vala files to exclude from both definition scan and production (match on path)
EXCLUDE_VALA_PATTERNS = [
    "test-shader",
    "vibe-canvas",
    "in-style.vala",
]

# Regex to extract type symbols: class [Namespace.]Name, interface ..., struct ..., enum ...
# Capture the full type name (with optional namespace); we use the short name (last identifier)
CLASS_RE = re.compile(
    r"^\s*(?:public\s+|internal\s+)?(?:abstract\s+)?class\s+([A-Za-z_][A-Za-z0-9_.]*)",
    re.MULTILINE,
)
INTERFACE_RE = re.compile(
    r"^\s*(?:public\s+)?interface\s+([A-Za-z_][A-Za-z0-9_.]*)",
    re.MULTILINE,
)
STRUCT_RE = re.compile(
    r"^\s*(?:public\s+)?struct\s+([A-Za-z_][A-Za-z0-9_.]*)",
    re.MULTILINE,
)
ENUM_RE = re.compile(
    r"^\s*(?:public\s+)?enum\s+([A-Za-z_][A-Za-z0-9_.]*)",
    re.MULTILINE,
)
DELEGATE_RE = re.compile(
    r"^\s*(?:public\s+)?delegate\s+[^;]+?\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(",
    re.MULTILINE,
)


def is_excluded_path(path: str) -> bool:
    for pat in EXCLUDE_VALA_PATTERNS:
        if pat in path:
            return True
    return False


def is_under_tests(path: str) -> bool:
    norm = path.replace("\\", "/")
    if norm.startswith(TEST_PATH_PREFIXES):
        return True
    for seg in TEST_PATH_SEGMENTS:
        if seg in norm:
            return True
    return False


def collect_vala_files(root: Path, production_roots: list[str], only_production: bool):
    """List .vala files under root. If only_production, exclude paths under tests."""
    out = []
    for base in production_roots:
        base_path = root / base
        if not base_path.is_dir():
            continue
        for f in base_path.rglob("*.vala"):
            rel = f.relative_to(root)
            rel_str = str(rel).replace("\\", "/")
            if is_excluded_path(rel_str):
                continue
            if only_production and is_under_tests(rel_str):
                continue
            out.append((rel_str, f))
    return out


def collect_ui_files(root: Path) -> list[tuple[str, Path]]:
    """List .blp and .ui files under data/ for template/type references."""
    out = []
    for base in ["data"]:
        base_path = root / base
        if not base_path.is_dir():
            continue
        for ext in ("*.blp", "*.ui"):
            for f in base_path.rglob(ext):
                rel = f.relative_to(root)
                rel_str = str(rel).replace("\\", "/")
                out.append((rel_str, f))
    return out


def collect_test_vala_files(root: Path):
    """List .vala files that are in test directories."""
    out = []
    for base in ["tests", "src"]:
        base_path = root / base
        if not base_path.is_dir():
            continue
        for f in base_path.rglob("*.vala"):
            rel = f.relative_to(root)
            rel_str = str(rel).replace("\\", "/")
            if is_excluded_path(rel_str):
                continue
            if not is_under_tests(rel_str):
                continue
            out.append((rel_str, f))
    return out


def short_name(full_name: str) -> str:
    """Tape.YaMAPI.Job -> Job; Job -> Job."""
    if "." in full_name:
        return full_name.split(".")[-1]
    return full_name


def extract_symbols_from_file(filepath: Path) -> list[tuple[str, str]]:
    """Returns list of (short_name, full_name) defined in the file."""
    try:
        text = filepath.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return []
    symbols = []
    for regex in (CLASS_RE, INTERFACE_RE, STRUCT_RE, ENUM_RE, DELEGATE_RE):
        for m in regex.finditer(text):
            full = m.group(1).strip()
            if full:
                symbols.append((short_name(full), full))
    return symbols


def has_reference_in_file(filepath: Path, symbol_short: str) -> bool:
    """True if symbol (word-boundary) appears in file (as type/name)."""
    try:
        text = filepath.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return False
    # Word boundary: symbol as whole word (avoid Job matching JobDoneStatus by requiring
    # non-identifier after; but Job.Done would still match Job). Simple: \bSymbol\b
    pattern = r"\b" + re.escape(symbol_short) + r"\b"
    return bool(re.search(pattern, text))


def count_references_in_file(filepath: Path, symbol_short: str) -> int:
    """Count occurrences of symbol in file (word-boundary for .vala, substring for .blp/.ui)."""
    try:
        text = filepath.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return 0
    suffix = filepath.suffix.lower()
    if suffix in (".blp", ".ui"):
        # Blueprint/UI use names like CassetteAccountInfoDialog
        return text.count(symbol_short)
    pattern = r"\b" + re.escape(symbol_short) + r"\b"
    return len(re.findall(pattern, text))


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: deadcode_checker.py <project_root>", file=sys.stderr)
        return 2
    root = Path(sys.argv[1]).resolve()
    if not root.is_dir():
        print(f"Not a directory: {root}", file=sys.stderr)
        return 2

    production_files = collect_vala_files(root, PRODUCTION_ROOTS, only_production=True)
    ui_files = collect_ui_files(root)
    # All files where production references can appear (vala + blp/ui templates)
    all_ref_files = [(r, p) for r, p in production_files] + ui_files

    dead = []
    for rel, path in production_files:
        for short, full in extract_symbols_from_file(path):
            # Skip GLib/Gtk/etc-style short names that are too generic
            if short in ("Object", "ObjectClass", "InitiallyUnowned", "Widget"):
                continue
            # Symbol is used if it appears 2+ times total (definition + at least one use)
            total_refs = sum(
                count_references_in_file(p, short) for _, p in all_ref_files
            )
            if total_refs < 2:
                dead.append((rel, short, full))

    if not dead:
        print("Dead code check: no unused symbols.")
        return 0

    print("Dead code (not used in production):", file=sys.stderr)
    for rel, short, full in sorted(dead):
        print(f"  {rel}: {full} (short: {short})", file=sys.stderr)
    print(f"\nTotal: {len(dead)} unused symbol(s).", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
