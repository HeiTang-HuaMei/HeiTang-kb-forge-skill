from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.skill import generate_skill_package
from tests.p0_helpers import make_p0_package


def make_structured_skill(tmp_path: Path) -> tuple[Path, Path]:
    package = make_p0_package(tmp_path)
    skill = tmp_path / "structured_skill"
    generate_skill_package(package, skill, "Structured Demo Skill", target="codex", language="bilingual")
    return package, skill


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))
