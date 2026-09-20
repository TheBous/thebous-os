#!/usr/bin/env python3
"""Project entrypoint for the canonical sdd-plan validator."""

import runpy
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
CANONICAL = ROOT / "skills" / "sdd-plan" / "scripts" / "validate_plan.py"
sys.argv[0] = str(CANONICAL)
runpy.run_path(str(CANONICAL), run_name="__main__")
