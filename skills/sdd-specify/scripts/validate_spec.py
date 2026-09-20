#!/usr/bin/env python3
"""Validate the deterministic structure of an SDD delta specification."""

import argparse
import json
import re
import sys
from pathlib import Path


REQUIRED_SECTIONS = (
    "## 1. Context & Business Intent",
    "## 2. Acceptance Criteria (EARS Notation)",
    "## 3. Interface Contracts & Invariants",
    "## 4. Examples",
    "## 5. Out of Scope",
)
REQUIRED_METADATA = {
    "Change ID": r"^\*\*Change ID:\*\*\s+CHG-\d{4}-\d{3}\s*$",
    "Status": r"^\*\*Status:\*\*\s+\S.+$",
    "Target Domain": r"^\*\*Target Domain:\*\*\s+specs/\S+$",
}
EARS_PATTERNS = {
    "Ubiquitous": r"the system shall\s+.+",
    "Event-driven": r"WHEN\s+.+?,\s+the system shall\s+.+",
    "State-driven": r"WHILE\s+.+?,\s+the system shall\s+.+",
    "Unwanted Event": r"IF\s+.+?,\s+THEN the system shall\s+.+",
    "Optional Feature": r"WHERE\s+.+?,\s+the system shall\s+.+",
}
ACCEPTANCE_LINE = re.compile(
    r"^[-*]\s+`(?P<id>AC-\d{3})\s+"
    r"\[(?P<change>ADDED|MODIFIED|REMOVED)\]\s+"
    r"\[(?P<ears>Ubiquitous|Event-driven|State-driven|Unwanted Event|Optional Feature)\]:\s+"
    r"(?P<text>.+)`$"
)


def body_without_frontmatter(source):
    return re.sub(r"\A---\s*\n.*?\n---\s*\n", "", source, count=1, flags=re.DOTALL)


def section_body(body, heading):
    match = re.search(
        rf"^{re.escape(heading)}\s*$([\s\S]*?)(?=^##\s|\Z)",
        body,
        re.MULTILINE,
    )
    return match.group(1).strip() if match else ""


def validate(source, max_tokens=1500):
    body = body_without_frontmatter(source)
    errors = []

    token_count = len(re.findall(r"\S+", body))
    if token_count > max_tokens:
        errors.append(f"token budget exceeded: {token_count} > {max_tokens} whitespace tokens")

    for heading in REQUIRED_SECTIONS:
        if not re.search(rf"^{re.escape(heading)}\s*$", body, re.MULTILINE):
            errors.append(f"missing required section: {heading}")

    for label, pattern in REQUIRED_METADATA.items():
        if not re.search(pattern, body, re.MULTILINE):
            errors.append(f"missing or invalid metadata: {label}")

    out_of_scope = section_body(body, "## 5. Out of Scope")
    if not out_of_scope or not re.search(r"\S", out_of_scope):
        errors.append("Out of Scope must not be empty")

    contracts = section_body(body, "## 3. Interface Contracts & Invariants")
    if not re.search(r"\binvariant\b", contracts, re.IGNORECASE):
        errors.append("Interface Contracts & Invariants must declare an invariant")

    examples = section_body(body, "## 4. Examples")
    if not re.search(r"\bvalid\b", examples, re.IGNORECASE):
        errors.append("Examples must include a valid payload")
    if not re.search(r"\binvalid\b", examples, re.IGNORECASE):
        errors.append("Examples must include an invalid payload")

    acceptance = section_body(body, "## 2. Acceptance Criteria (EARS Notation)")
    acceptance_lines = [
        line for line in acceptance.splitlines() if re.search(r"\bAC-\d{3}\b", line)
    ]
    if not acceptance_lines:
        errors.append("Acceptance Criteria must contain at least one AC-NNN requirement")

    seen_ids = set()
    for line in acceptance_lines:
        requirement = re.search(r"\b(AC-\d{3})\b", line)
        requirement_id = requirement.group(1)
        match = ACCEPTANCE_LINE.fullmatch(line.strip())
        if not match:
            errors.append(f"{requirement_id} has invalid EARS or delta syntax")
            continue
        if requirement_id in seen_ids:
            errors.append(f"duplicate requirement id: {requirement_id}")
        seen_ids.add(requirement_id)
        ears = match.group("ears")
        if not re.fullmatch(EARS_PATTERNS[ears], match.group("text"), re.IGNORECASE):
            errors.append(f"{requirement_id} does not match {ears} EARS syntax")

    json_blocks = re.findall(r"```(?:json|jsonschema|openapi)\s*\n([\s\S]*?)```", body, re.IGNORECASE)
    if not json_blocks:
        errors.append("Interface Contracts & Invariants must contain a JSON or OpenAPI JSON block")
    for block in json_blocks:
        try:
            json.loads(block)
        except json.JSONDecodeError as error:
            errors.append(f"invalid JSON contract: {error.msg}")

    return errors, token_count


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("spec", type=Path, help="Markdown delta specification to validate")
    parser.add_argument("--max-tokens", type=int, default=1500)
    args = parser.parse_args(argv)

    try:
        source = args.spec.read_text(encoding="utf-8")
    except OSError as error:
        print(f"ERROR: cannot read {args.spec}: {error}", file=sys.stderr)
        return 2

    errors, token_count = validate(source, args.max_tokens)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    print(f"OK: {args.spec} ({token_count} whitespace tokens)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
