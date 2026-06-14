from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_desktop_packaging_scripts_remain_available_without_legacy_docs():
    for path in [
        ROOT / "desktop" / "tauri" / "README.md",
        ROOT / "packaging" / "desktop" / "README.md",
        ROOT / "packaging" / "desktop" / "dev_tauri.ps1",
        ROOT / "packaging" / "desktop" / "build_tauri.ps1",
    ]:
        assert path.exists(), path


def test_current_docs_describe_ui_as_presentation_layer():
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    chinese = (ROOT / "README.zh-CN.md").read_text(encoding="utf-8")
    roadmap = (ROOT / "docs" / "路线图.md").read_text(encoding="utf-8")

    assert "Campaign 4 UI work is not active" in readme
    assert "Campaign 4 UI 未启动" in chinese
    assert "Campaign 4" in roadmap
    assert "not_started" in roadmap
    assert "full Workbench" not in readme
