from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESKTOP = ROOT / "desktop" / "tauri"


def test_desktop_fixed_navigation_has_eleven_pages():
    sidebar = (DESKTOP / "src" / "components" / "Sidebar.tsx").read_text(encoding="utf-8")
    for page_id in [
        "dashboard",
        "buildPackage",
        "batchProcessing",
        "workspace",
        "lifecycleUpdate",
        "qualityGate",
        "packageDetail",
        "askRuntime",
        "publishExport",
        "planningReadiness",
        "settings",
    ]:
        assert page_id in sidebar


def test_desktop_dark_theme_variables_are_present():
    css = (DESKTOP / "src" / "styles.css").read_text(encoding="utf-8")
    for token in ["#0f1115", "#151821", "#11141b", "#1a1f2b", "#2a3140", "#f4f7fb"]:
        assert token in css
    assert "grid-template-columns: 260px" in css


def test_current_docs_describe_ui_boundary_without_legacy_ui_docs():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in ["README.md", "README.zh-CN.md", "docs/路线图.md", "docs/治理/当前运行状态.md"]
    )
    assert "Campaign 4 UI work is not active" in text or "Campaign 4 UI 未启动" in text
    assert "Campaign 4 active：false" in text
    assert "v4.2" in text
    assert "Web Console" not in text
    assert "web console" not in text
