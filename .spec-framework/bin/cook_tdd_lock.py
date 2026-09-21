#!/usr/bin/env python3
import json
import os
import stat
import sys
from pathlib import Path


def stop(message, code=1):
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(code)


def lock_primary(base, git_path, change):
    lock_dir = Path(git_path) / "cook-tdd-lock"
    lock_dir.mkdir(parents=True, exist_ok=True)
    manifest = lock_dir / f"{change}.json"
    if manifest.exists():
        stop(f"primary worktree already locked for {change}", 10)
    paths = [base]
    for root, dirs, files in os.walk(base, topdown=True, followlinks=False):
        dirs[:] = [name for name in dirs if name not in {".git", ".worktrees"}]
        files[:] = [name for name in files if name != ".git"]
        paths.extend(Path(root) / name for name in dirs + files)
    if any(path.is_symlink() for path in paths):
        stop("primary worktree contains symlinks; refusing physical lock", 10)
    modes = {str(path): stat.S_IMODE(path.stat().st_mode) for path in paths}
    manifest.write_text(json.dumps(modes, indent=2) + "\n", encoding="utf-8")
    try:
        for path in paths:
            path.chmod(modes[str(path)] & ~(stat.S_IWUSR | stat.S_IWGRP | stat.S_IWOTH))
    except OSError as error:
        for name, mode in modes.items():
            Path(name).chmod(mode)
        manifest.unlink(missing_ok=True)
        stop(f"could not lock primary worktree: {error}", 10)


def unlock_primary(git_path, change):
    manifest = Path(git_path) / "cook-tdd-lock" / f"{change}.json"
    if not manifest.is_file():
        stop(f"no primary worktree lock exists for {change}", 11)
    modes = json.loads(manifest.read_text(encoding="utf-8"))
    for name, mode in modes.items():
        Path(name).chmod(mode)
    manifest.unlink()
