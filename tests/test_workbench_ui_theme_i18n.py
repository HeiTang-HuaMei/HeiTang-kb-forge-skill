import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"


def test_workbench_supports_light_and_dark_theme_tokens():
    index = (WORKBENCH / "index.html").read_text(encoding="utf-8")
    styles = (WORKBENCH / "styles.css").read_text(encoding="utf-8")
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")

    assert 'data-theme="light"' in index
    assert '[data-theme="dark"]' in styles
    for token in ["--bg", "--panel", "--text", "--muted", "--line", "--accent", "--radius"]:
        assert token in styles
    assert "theme-toggle" in index
    assert 'state.theme === "light" ? "dark" : "light"' in app


def test_workbench_visual_style_stays_black_white_gray():
    styles = (WORKBENCH / "styles.css").read_text(encoding="utf-8")
    declarations = re.findall(r":\s*([^;{}]+);", styles)

    for disallowed_color in ["purple", "blue", "orange", "pink", "green", "red", "yellow"]:
        assert all(disallowed_color not in declaration.lower() for declaration in declarations)
    assert "#111111" in styles
    assert "#ffffff" in styles
    assert "#666666" in styles


def test_workbench_supports_chinese_and_english_i18n_switching():
    index = (WORKBENCH / "index.html").read_text(encoding="utf-8")
    i18n = (WORKBENCH / "src" / "i18n.js").read_text(encoding="utf-8")
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")

    assert 'lang="zh-CN"' in index
    assert 'data-locale="zh-CN"' in index
    assert 'data-locale="en-US"' in index
    assert 'defaultLocale = "zh-CN"' in i18n
    assert '"zh-CN"' in i18n
    assert '"en-US"' in i18n
    assert "document.documentElement.lang = state.locale" in app
    assert "label_zh" in app
