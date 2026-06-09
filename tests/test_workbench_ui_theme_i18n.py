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
    for token in ["--bg", "--panel", "--text", "--muted", "--line", "--accent", "--radius", "--sidebar"]:
        assert token in styles
    for shell_selector in [".workbench-shell", ".sidebar", ".topbar", ".panel", ".context-card", ".data-table", ".statusbar"]:
        assert shell_selector in styles
    assert "theme-toggle" in index
    assert 'state.theme === "light" ? "dark" : "light"' in app


def test_workbench_visual_style_stays_black_white_gray_with_state_colors_only_for_status():
    styles = (WORKBENCH / "styles.css").read_text(encoding="utf-8")
    root_blocks = re.findall(r":root\s*\{(?P<root>.*?)\}\s*\[data-theme=\"dark\"\]\s*\{(?P<dark>.*?)\}", styles, re.S)
    root_and_dark = "\n".join("".join(block) for block in root_blocks)
    allowed_state_selectors = [
        ".status-pill",
        ".risk-pill",
        ".score",
        ".progress-fill",
        ".accuracy-ring",
        ".status-dot",
        ".switch.is-on",
    ]

    assert "#111111" in styles
    assert "#ffffff" in styles
    assert "#666666" in styles
    assert "#f3f4f5" in styles
    assert "#141719" in styles
    assert "--success" in styles
    assert "--warning" in styles
    assert "--error" in styles
    assert "--running" in styles
    assert "--blocked" in styles

    css_values = "\n".join(re.findall(r":\s*([^;{}]+);", styles)).lower()
    for named_color in ["purple", "pink", "orange", "yellow", "green", "blue", "red"]:
        assert not re.search(rf"\b{named_color}\b", css_values)
    assert root_and_dark.count("--success") == 2
    assert root_and_dark.count("--warning") == 2
    assert root_and_dark.count("--error") == 2
    assert root_and_dark.count("--running") == 2
    assert root_and_dark.count("--blocked") == 2
    for token in ["var(--success)", "var(--warning)", "var(--error)", "var(--running)"]:
        for match in re.finditer(r"(?P<selectors>[^{}]+)\{[^{}]*" + re.escape(token), styles):
            selectors = match.group("selectors")
            assert any(selector in selectors for selector in allowed_state_selectors)


def test_workbench_supports_chinese_and_english_i18n_switching():
    index = (WORKBENCH / "index.html").read_text(encoding="utf-8")
    i18n = (WORKBENCH / "src" / "i18n.js").read_text(encoding="utf-8")
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")

    assert 'lang="zh-CN"' in index
    assert 'data-locale="zh-CN"' in index
    assert 'data-locale="en-US"' in index
    assert 'defaultLocale = "zh-CN"' in i18n
    assert '"zh-CN"' in i18n
    assert '"en-US"' in i18n
    assert "data-i18n-placeholder" in index
    assert "document.documentElement.lang = state.locale" in app
    assert "label_zh" in app
    assert "STATUS_LABELS" in app
    assert "RISK_LABELS" in app
    assert "statusText(value)" in app
    assert "riskText(value)" in app
    assert "supportedLocaleCodes" in flutter_main
    assert "const Locale('zh', 'CN')" in flutter_main
    assert "const Locale('en', 'US')" in flutter_main
    assert "SegmentedButton<String>" in flutter_main
    assert "localeCode == 'zh-CN' ? '打开' : 'Open'" in flutter_main


def test_workbench_brand_and_mascot_assets_exist():
    index = (WORKBENCH / "index.html").read_text(encoding="utf-8")
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")
    pubspec = (WORKBENCH / "flutter_app" / "pubspec.yaml").read_text(encoding="utf-8")

    assert "HeiTang 黑糖" in index
    assert "black_cat_head.svg" in index
    assert "black_tiger_head.svg" in index
    assert "black_cat_head.svg" in pubspec
    assert "black_tiger_head.svg" in pubspec
    assert "black_cat_head.svg" in flutter_main
    assert "black_tiger_head.svg" in flutter_main
    assert (WORKBENCH / "flutter_app" / "assets" / "brand" / "black_cat_head.svg").exists()
    assert (WORKBENCH / "flutter_app" / "assets" / "brand" / "black_tiger_head.svg").exists()


def test_flutter_scaffold_supports_light_and_dark_modes():
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")

    assert "ThemeMode.light" in flutter_main
    assert "ThemeMode.dark" in flutter_main
    assert "theme: _theme(Brightness.light)" in flutter_main
    assert "darkTheme: _theme(Brightness.dark)" in flutter_main
    assert "Icons.light_mode_outlined" in flutter_main
    assert "Icons.dark_mode_outlined" in flutter_main


def test_workbench_defaults_to_windows_desktop_shell_not_macos_shell():
    index = (WORKBENCH / "index.html").read_text(encoding="utf-8")
    styles = (WORKBENCH / "styles.css").read_text(encoding="utf-8")
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")

    assert 'data-shell="windows-desktop"' in index
    assert "Windows Desktop Workbench" in index
    assert "Windows Desktop Workbench" in (WORKBENCH / "src" / "i18n.js").read_text(encoding="utf-8")
    assert "traffic-light" not in index
    assert "window-control" not in index
    assert "macos" not in index.lower()
    assert "macOS" not in app
    assert "border-radius: 50%;" in styles  # allowed for avatar/status, not shell chrome


def test_key_pages_have_light_dark_renderable_shell_and_i18n_titles():
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")
    styles = (WORKBENCH / "styles.css").read_text(encoding="utf-8")

    for page_id in ["dashboard", "workspace", "import-parsing", "retrieval-verification", "agent-factory-runtime", "reports-audit"]:
        assert f'id: "{page_id}"' in app
    for title in ["仪表盘", "工作空间", "Import & Parsing", "Retrieval & Verification", "Agent 工厂与运行", "Reports & Audit"]:
        assert title in app
    assert "pageShell(" in app
    assert "right-context" in app
    assert ".right-context" in styles
    assert "[data-theme=\"dark\"]" in styles
