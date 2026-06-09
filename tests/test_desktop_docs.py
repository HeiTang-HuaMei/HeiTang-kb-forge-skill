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
    roadmap = (ROOT / "docs" / "ROADMAP.md").read_text(encoding="utf-8")
    p1 = (ROOT / "docs" / "10_roadmap" / "P1_UI_CORE_PARITY.md").read_text(encoding="utf-8")

    assert "presentation layer" in readme
    assert "presentation layer" in chinese
    assert "presentation layer" in roadmap
    assert "ready_for_v4_rc=true" in p1
    assert "not released, not tagged, and not started" in p1
    assert "full Workbench" not in readme
