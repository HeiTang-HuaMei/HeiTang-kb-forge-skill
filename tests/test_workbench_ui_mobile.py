from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"


def test_workbench_declares_responsive_viewport_and_mobile_nav():
    index = (WORKBENCH / "index.html").read_text(encoding="utf-8")

    assert 'name="viewport"' in index
    assert "width=device-width, initial-scale=1" in index
    assert 'class="mobile-nav"' in index
    assert 'id="mobile-page-select"' in index


def test_workbench_css_contains_mobile_breakpoints_and_single_column_layout():
    styles = (WORKBENCH / "styles.css").read_text(encoding="utf-8")

    assert "@media (max-width: 980px)" in styles
    assert "@media (max-width: 760px)" in styles
    assert "@media (max-width: 480px)" in styles
    assert ".sidebar {\n    display: none;" in styles
    assert ".mobile-nav {\n    display: block;" in styles
    assert "grid-template-columns: 1fr;" in styles
    assert "min-width: 320px;" in styles


def test_workbench_mobile_spec_is_responsive_web_not_native():
    english_spec = (ROOT / "docs" / "WORKBENCH_MOBILE_SPEC.md").read_text(encoding="utf-8")
    chinese_spec = (ROOT / "docs" / "WORKBENCH_MOBILE_SPEC.zh-CN.md").read_text(encoding="utf-8")

    assert "responsive web" in english_spec.lower()
    assert "Native iOS and Android apps are out of scope." in english_spec
    assert "响应式 Web" in chinese_spec
    assert "不实现原生 iOS 或 Android 应用" in chinese_spec
