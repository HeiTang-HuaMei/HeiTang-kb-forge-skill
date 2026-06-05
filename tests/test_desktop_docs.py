from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_desktop_docs_and_packaging_scripts_exist():
    for path in [
        ROOT / "docs" / "DESKTOP_APP_GUIDE.md",
        ROOT / "desktop" / "tauri" / "README.md",
        ROOT / "packaging" / "desktop" / "README.md",
        ROOT / "packaging" / "desktop" / "dev_tauri.ps1",
        ROOT / "packaging" / "desktop" / "build_tauri.ps1",
    ]:
        assert path.exists(), path


def test_desktop_docs_describe_tauri_exe_and_boundaries():
    guide = (ROOT / "docs" / "DESKTOP_APP_GUIDE.md").read_text(encoding="utf-8")
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    chinese = (ROOT / "README.zh-CN.md").read_text(encoding="utf-8")
    changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")

    assert "Tauri" in guide
    assert "Build Windows EXE" in guide
    assert "does not call external APIs" in guide
    assert "Desktop App Guide" in readme
    assert "桌面" in chinese
    assert "## v1.2.2" in changelog
    assert "## v1.2.3" in changelog
