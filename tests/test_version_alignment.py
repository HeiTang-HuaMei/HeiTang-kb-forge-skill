import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERSION = "2.6.0-alpha.1"


def test_project_versions_are_aligned():
    pyproject = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    skill = json.loads((ROOT / "skill.json").read_text(encoding="utf-8"))
    assert f'version = "{VERSION}"' in pyproject
    assert skill["version"] == VERSION
    for relative in [
        "README.md",
        "README.zh-CN.md",
        "docs/CAPABILITY_STATUS.md",
        "docs/CAPABILITY_STATUS.zh-CN.md",
        "docs/VERSION_MATRIX.md",
        "docs/VERSION_MATRIX.zh-CN.md",
        "docs/RELEASE_CHECKLIST.md",
        "docs/RELEASE_CHECKLIST.zh-CN.md",
    ]:
        assert VERSION in (ROOT / relative).read_text(encoding="utf-8")


