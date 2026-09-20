#!/usr/bin/env python3
"""Small stateful helpers for the provider-neutral SDD execution gate."""

import json
import os
import re
import stat
import sys
import time
from pathlib import Path


TASK_LINE = re.compile(r"^- \[([ xX])\] \*\*Task\s+[^:]+:\s*(.*?)\*\*")
TASK_ID = re.compile(r"\*\*ID:\*\*\s*(T-\d{3})")
DEPS = re.compile(r"\*\*Deps:\*\*\s*\[([^]]*)\]")


def stop(message, code=1):
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(code)


def change_dir(base, change):
    path = base / "changes" / change
    if not path.is_dir():
        stop(f"change package not found: {path}")
    return path


def approved(root, change):
    package = change_dir(root, change)
    marker = f"approve-plan changes/{change}"
    approval = package / "approval.md"
    if not approval.is_file() or marker not in approval.read_text(encoding="utf-8").splitlines():
        stop(f"missing exact approval marker: {marker}", 2)
    return package / "tasks.md"


def tasks(path):
    if not path.is_file():
        stop(f"tasks file not found: {path}")
    entries = []
    current = None
    for line in path.read_text(encoding="utf-8").splitlines():
        match = TASK_LINE.match(line)
        if match:
            if current:
                entries.append(current)
            current = {"done": match.group(1).lower() == "x", "title": match.group(2), "id": None, "deps": []}
            continue
        if current and current["id"] is None:
            match = TASK_ID.search(line)
            if match:
                current["id"] = match.group(1)
        if current:
            match = DEPS.search(line)
            if match:
                current["deps"] = re.findall(r"T-\d{3}", match.group(1))
    if current:
        entries.append(current)
    if any(entry["id"] is None for entry in entries):
        stop("every task must declare an ID", 3)
    return entries


def select_task(root, change):
    entries = tasks(approved(root, change))
    complete = {entry["id"] for entry in entries if entry["done"]}
    for entry in entries:
        if not entry["done"] and all(dep in complete for dep in entry["deps"]):
            print(f"READY:{entry['id']}:{entry['title']}")
            return entry["id"]
    stop("no pending task has all dependencies complete", 4)


def assert_task(root, change, task_id):
    selected = select_task(root, change)
    if selected != task_id:
        stop(f"{task_id} is not the first ready task; expected {selected}", 5)


def evidence_path(git_path, change, task):
    return Path(git_path) / change / f"{task}.json"


def record_quality(git_path, change, task, static_command, mutation_command, review_path):
    if not static_command:
        stop("static analysis command is required", 8)
    if not mutation_command:
        stop("mutation testing command is required", 8)
    review = Path(review_path)
    if not review.is_file() or "PASS" not in review.read_text(encoding="utf-8").splitlines():
        stop("independent review receipt must contain an exact PASS line", 8)
    target = evidence_path(git_path, change, task)
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(json.dumps({
        "task": task,
        "static": "PASS",
        "mutation": "PASS",
        "review": "PASS",
        "status": "PASS",
        "recorded_at": int(time.time()),
    }, indent=2) + "\n", encoding="utf-8")


def require_quality(git_path, change, task):
    target = evidence_path(git_path, change, task)
    if not target.is_file():
        stop(f"quality evidence missing for {task}; run verify-quality first", 9)
    try:
        evidence = json.loads(target.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        stop(f"invalid quality evidence for {task}", 9)
    if evidence.get("status") != "PASS":
        stop(f"quality evidence is not passing for {task}", 9)


def lock_primary(base, git_path, change):
    lock_dir = Path(git_path) / "sdd-tdd-lock"
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
    manifest = Path(git_path) / "sdd-tdd-lock" / f"{change}.json"
    if not manifest.is_file():
        stop(f"no primary worktree lock exists for {change}", 11)
    modes = json.loads(manifest.read_text(encoding="utf-8"))
    for name, mode in modes.items():
        Path(name).chmod(mode)
    manifest.unlink()


def mark_complete(worktree, change, task):
    path = worktree / "changes" / change / "tasks.md"
    lines = path.read_text(encoding="utf-8").splitlines(keepends=True)
    for index, line in enumerate(lines):
        if not TASK_LINE.match(line) or "[x]" in line.lower():
            continue
        end = next((i for i in range(index + 1, len(lines)) if TASK_LINE.match(lines[i])), len(lines))
        if any(TASK_ID.search(candidate) and TASK_ID.search(candidate).group(1) == task for candidate in lines[index:end]):
            lines[index] = line.replace("- [ ]", "- [x]", 1)
            path.write_text("".join(lines), encoding="utf-8")
            return
    stop(f"unchecked task not found in worktree tasks.md: {task}", 12)


def main(argv):
    if len(argv) < 4:
        stop("usage: sdd_tdd.py ACTION BASE WORKTREE CHANGE [TASK...]" )
    action, base, worktree, change = argv[:4]
    base, worktree = Path(base), Path(worktree)
    def argument(index, message):
        if len(argv) <= index or not argv[index]:
            stop(message)
        return argv[index]

    if action == "select-task":
        select_task(worktree, change)
    elif action == "assert-task":
        assert_task(worktree, change, argument(4, "task id is required"))
    elif action == "record-quality":
        record_quality(argument(4, "evidence path is required"), change, argument(5, "task id is required"), argument(6, "static command is required"), argument(7, "mutation command is required"), argument(8, "review receipt is required"))
    elif action == "require-quality":
        require_quality(argument(4, "evidence path is required"), change, argument(5, "task id is required"))
    elif action == "lock":
        lock_primary(base, argument(4, "Git directory is required"), change)
    elif action == "unlock":
        unlock_primary(argument(4, "Git directory is required"), change)
    elif action == "complete":
        mark_complete(worktree, change, argument(4, "task id is required"))
    else:
        stop(f"unsupported helper action: {action}")


if __name__ == "__main__":
    main(sys.argv[1:])
