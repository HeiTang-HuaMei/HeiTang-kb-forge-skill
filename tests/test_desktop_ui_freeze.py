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
        for path in ["README.md", "README.zh-CN.md", "docs/ROADMAP.md", "docs/10_roadmap/P1_UI_CORE_PARITY.md"]
    )
    assert "UI information architecture is frozen" in text or "UI 信息架构已冻结" in text
    assert "presentation layer" in text
    assert "UI full-operation remains blocked" in text
    assert "Web Console" not in text
    assert "web console" not in text
