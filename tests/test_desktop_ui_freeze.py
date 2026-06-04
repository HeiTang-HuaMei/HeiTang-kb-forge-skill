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


def test_docs_describe_ui_freeze_and_do_not_call_it_web_console():
    text = "\n".join(
        (ROOT / path).read_text(encoding="utf-8")
        for path in ["README.md", "README.zh-CN.md", "docs/DESKTOP_APP_GUIDE.md", "docs/UI_INFORMATION_ARCHITECTURE.md"]
    )
    assert "UI information architecture is frozen" in text or "UI 信息架构已冻结" in text
    assert "Web Console" not in text
    assert "web console" not in text
