#!/usr/bin/env python3
"""Validate a technical design and DAG task plan before execution."""

import argparse
import re
import sys
from pathlib import Path


DESIGN_SECTIONS = (
    "## 1. Architectural Impact & Topology",
    "## 2. Invariants & Domain Contracts",
    "## 3. Architecture Decision Records (ADR)",
    "## 4. File Modification Matrix",
    "## 5. Technology Guidance & Reuse Analysis",
)
DESIGN_METADATA = {
    "Change ID": r"^\*\*Change ID:\*\*\s+(CHG-\d{4}-\d{3})\s*$",
    "Status": r"^\*\*Status:\*\*\s+Approved\s*$",
    "Related Specs": r"^\*\*Related Specs:\*\*\s+\S+\s*$",
}
TASK_METADATA = {
    "Change ID": r"^\*\*Change ID:\*\*\s+(CHG-\d{4}-\d{3})\s*$",
    "Execution Topology": r"^\*\*Execution Topology:\*\*\s+.*DAG.*$",
    "Assigned Worktree": r"^\*\*Assigned Worktree:\*\*\s+\.worktrees/CHG-\d{4}-\d{3}\s*$",
}
PLACEHOLDER_PATTERN = re.compile(r"\b(?:TODO|TBD|FIXME|PLACEHOLDER)\b", re.IGNORECASE)
APPROVED_STATUS = re.compile(r"^\*\*Status:\*\*\s+Approved\s*$", re.MULTILINE)
TECHNOLOGY_EVIDENCE = {
    "Context7": re.compile(r"\bContext7\b", re.IGNORECASE),
    "architecture-first-development": re.compile(
        r"\barchitecture-first-development\b", re.IGNORECASE
    ),
    "reuse": re.compile(r"\breuse\b", re.IGNORECASE),
}


def section_body(source, heading):
    match = re.search(
        rf"^{re.escape(heading)}\s*$([\s\S]*?)(?=^##\s|\Z)",
        source,
        re.MULTILINE,
    )
    return match.group(1).strip() if match else ""


def metadata(source, required, label):
    values = {}
    errors = []
    for field, pattern in required.items():
        match = re.search(pattern, source, re.MULTILINE)
        if not match:
            errors.append(f"{label} missing or invalid metadata: {field}")
        else:
            values[field] = match.group(1) if match.groups() else True
    return values, errors


def code_paths(source):
    return re.findall(r"`([^`\n]+)`", source)


def validate(change_dir):
    errors = []
    change_dir = Path(change_dir)
    design_path = change_dir / "design.md"
    tasks_path = change_dir / "tasks.md"
    delta_path = change_dir / "delta-spec.md"

    for path in (delta_path, design_path, tasks_path):
        if not path.is_file():
            errors.append(f"missing required artifact: {path.name}")
    if errors:
        return errors

    delta = delta_path.read_text(encoding="utf-8")
    design = design_path.read_text(encoding="utf-8")
    tasks = tasks_path.read_text(encoding="utf-8")

    spec_ids = set(re.findall(r"\bAC-\d{3}\b", delta))
    if not spec_ids:
        errors.append("delta-spec has no AC-NNN acceptance criteria")
    if not APPROVED_STATUS.search(delta):
        errors.append("delta-spec Status must be Approved")

    design_values, design_errors = metadata(design, DESIGN_METADATA, "design.md")
    task_values, task_errors = metadata(tasks, TASK_METADATA, "tasks.md")
    errors.extend(design_errors)
    errors.extend(task_errors)

    change_id = change_dir.name
    for label, values in (("design.md", design_values), ("tasks.md", task_values)):
        if values.get("Change ID") and values["Change ID"] != change_id:
            errors.append(f"{label} Change ID does not match directory {change_id}")

    for heading in DESIGN_SECTIONS:
        if not re.search(rf"^{re.escape(heading)}\s*$", design, re.MULTILINE):
            errors.append(f"design.md missing required section: {heading}")

    matrix = section_body(design, DESIGN_SECTIONS[3])
    matrix_paths = set(code_paths(matrix))
    if not matrix_paths:
        errors.append("design.md file modification matrix has no file paths")
    if not re.search(r"\bADR-\d+\b", section_body(design, DESIGN_SECTIONS[2])):
        errors.append("design.md must record at least one ADR")

    technology_guidance = section_body(design, DESIGN_SECTIONS[4])
    for label, pattern in TECHNOLOGY_EVIDENCE.items():
        if not pattern.search(technology_guidance):
            errors.append(f"technology guidance missing {label} evidence")

    if PLACEHOLDER_PATTERN.search(design) or PLACEHOLDER_PATTERN.search(tasks):
        errors.append("design.md or tasks.md contains a placeholder")

    task_blocks = re.findall(
        r"^[-*]\s+\[[ x]\]\s+\*\*Task\s+(\d+):.*?(?=^[-*]\s+\[[ x]\]\s+\*\*Task\s+\d+:|\Z)",
        tasks,
        re.MULTILINE | re.DOTALL,
    )
    if not task_blocks:
        errors.append("tasks.md contains no task blocks")
        return errors

    task_sections = re.findall(
        r"^[-*]\s+\[[ x]\]\s+\*\*Task\s+\d+:.*?(?=^[-*]\s+\[[ x]\]\s+\*\*Task\s+\d+:|\Z)",
        tasks,
        re.MULTILINE | re.DOTALL,
    )
    task_ids = {}
    dependencies = {}
    phases = {}
    covered_ids = set()

    for task in task_sections:
        id_match = re.search(r"\*\*ID:\*\*\s*(T-\d{3})", task)
        if not id_match:
            errors.append("task is missing an ID")
            continue
        task_id = id_match.group(1)
        if task_id in task_ids:
            errors.append(f"duplicate task ID: {task_id}")
        task_ids[task_id] = task

        phase = re.search(r"\*\*DAG Phase:\*\*\s*([0-3])\b", task)
        if not phase:
            errors.append(f"{task_id} must declare DAG Phase 0, 1, 2, or 3")
        else:
            phases[task_id] = int(phase.group(1))

        deps_match = re.search(r"\*\*Deps:\*\*\s*\[([^\]]*)\]", task)
        if not deps_match:
            errors.append(f"{task_id} is missing dependencies")
            dependencies[task_id] = []
        else:
            dependencies[task_id] = re.findall(r"T-\d{3}", deps_match.group(1))

        coverage_match = re.search(r"\*\*AC Coverage:\*\*\s*([^\n]+)", task)
        if not coverage_match:
            errors.append(f"{task_id} is missing AC Coverage")
        else:
            task_ac_ids = set(re.findall(r"\bAC-\d{3}\b", coverage_match.group(1)))
            if not task_ac_ids:
                errors.append(f"{task_id} AC Coverage must include at least one AC-NNN")
            covered_ids.update(task_ac_ids)
            unknown = task_ac_ids - spec_ids
            for ac_id in sorted(unknown):
                errors.append(f"{task_id} references unknown acceptance criterion {ac_id}")

        allowed_match = re.search(
            r"\*\*Allowed Paths:\*\*(.*?)(?=\n\s*[-*]\s+\*\*Forbidden Paths:\*\*)",
            task,
            re.DOTALL,
        )
        forbidden_match = re.search(
            r"\*\*Forbidden Paths:\*\*(.*?)(?=\n\s*[-*]\s+\*\*(?:TDD Protocol|Definition of Done):)",
            task,
            re.DOTALL,
        )
        allowed = set(code_paths(allowed_match.group(1))) if allowed_match else set()
        forbidden = set(code_paths(forbidden_match.group(1))) if forbidden_match else set()
        if not allowed:
            errors.append(f"{task_id} must declare Allowed Paths")
        forbidden_text = forbidden_match.group(1).strip() if forbidden_match else ""
        if not forbidden and not re.match(r"^(?:none|nessuno)\b", forbidden_text, re.IGNORECASE):
            errors.append(f"{task_id} must declare Forbidden Paths")
        if len(allowed) > 2:
            errors.append(f"{task_id} has more than two Allowed Paths")
        overlap = allowed & forbidden
        if overlap:
            errors.append(f"{task_id} paths are both allowed and forbidden: {sorted(overlap)}")
        for path in allowed:
            if path not in matrix_paths:
                errors.append(f"{task_id} Allowed Path is absent from the file matrix: {path}")

        for label in ("TDD Protocol", "Definition of Done"):
            match = re.search(
                rf"\*\*{re.escape(label)}:\*\*\s*([^\n]+)",
                task,
            )
            if not match or not match.group(1).strip():
                errors.append(f"{task_id} is missing {label}")

    for task_id, deps in dependencies.items():
        for dependency in deps:
            if dependency not in task_ids:
                errors.append(f"{task_id} depends on unknown task {dependency}")
            elif task_id in phases and dependency in phases and phases[dependency] > phases[task_id]:
                errors.append(f"{task_id} depends on later DAG phase task {dependency}")

    visiting = set()
    visited = set()

    def visit(task_id):
        if task_id in visiting:
            return True
        if task_id in visited:
            return False
        visiting.add(task_id)
        has_cycle = any(dependency in dependencies and visit(dependency) for dependency in dependencies[task_id])
        visiting.remove(task_id)
        visited.add(task_id)
        return has_cycle

    if any(visit(task_id) for task_id in dependencies):
        errors.append("task dependency graph contains a cycle")

    missing_coverage = spec_ids - covered_ids
    for ac_id in sorted(missing_coverage):
        errors.append(f"acceptance criterion {ac_id} is not covered by any task")

    return errors


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("change_dir", type=Path)
    args = parser.parse_args(argv)

    try:
        errors = validate(args.change_dir)
    except OSError as error:
        print(f"ERROR: cannot read plan artifacts: {error}", file=sys.stderr)
        return 2

    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"OK: validated plan {args.change_dir}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
