import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.2.0"


def test_project_versions_are_aligned():
    pyproject = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    skill = json.loads((ROOT / "skill.json").read_text(encoding="utf-8"))
    assert f'version = "{VERSION}"' in pyproject
    assert skill["version"] == VERSION
    for relative in [
        "README.md",
        "README.zh-CN.md",
        "docs/项目概览.md",
        "docs/治理/历史版本说明.md",
    ]:
        assert VERSION in (ROOT / relative).read_text(encoding="utf-8")
    assert "Current Core package version: `4.2.0`" in (ROOT / "README.md").read_text(encoding="utf-8")


