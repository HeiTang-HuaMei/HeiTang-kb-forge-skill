import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
VERSION = "4.2.0"


def test_project_versions_are_aligned():
    pyproject = (ROOT / "pyproject.toml").read_text(encoding="utf-8")
    skill = json.loads((ROOT / "skill.json").read_text(encoding="utf-8"))
    flutter_pubspec = (ROOT / "web" / "workbench" / "flutter_app" / "pubspec.yaml").read_text(encoding="utf-8")
    assert f'version = "{VERSION}"' in pyproject
    assert skill["version"] == VERSION
    assert f"version: {VERSION}+1" in flutter_pubspec
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
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    assert "Current stable release: `v4.2.0` P2.2" in readme
    assert "The `v4.0.0`, `v4.1.0`, and `v4.1.1` tags remain untouched" in readme
    assert "v4.2.0 UI industrial workflow release" in readme


