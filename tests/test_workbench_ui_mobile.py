from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"
FLUTTER_LIB = WORKBENCH / "flutter_app" / "lib"


def _flutter_shell_sources() -> str:
    return "\n".join(
        [
            (FLUTTER_LIB / "main.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "app" / "product_top_bar.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "app" / "desktop_status_bar.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "app" / "workbench_sidebar.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "app" / "workbench_shell.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "shared" / "workbench_layout.dart").read_text(encoding="utf-8"),
            (FLUTTER_LIB / "shared" / "product_components.dart").read_text(encoding="utf-8"),
        ]
    )


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


def test_workbench_mobile_spec_is_responsive_web_with_platform_scaffolds():
    english_spec = (ROOT / "docs" / "WORKBENCH_MOBILE_SPEC.md").read_text(encoding="utf-8")
    chinese_spec = (ROOT / "docs" / "WORKBENCH_MOBILE_SPEC.zh-CN.md").read_text(encoding="utf-8")

    assert "responsive web" in english_spec.lower()
    assert "Android" in english_spec
    assert "iOS" in english_spec
    assert "Windows desktop scaffold" in english_spec
    assert "响应式 Web" in chinese_spec
    assert "Android" in chinese_spec
    assert "iOS" in chinese_spec
    assert "Windows 桌面 scaffold" in chinese_spec


def test_flutter_scaffold_contains_fixed_desktop_shell_not_mobile_scaling():
    flutter_sources = _flutter_shell_sources()

    assert "initialWindowWidth = 1440" in flutter_sources
    assert "initialWindowHeight = 900" in flutter_sources
    assert "_DesktopWindowPreviewShell" in flutter_sources
    assert "_DesktopWorkbench" in flutter_sources
    assert "desktop-window-preview-frame" in flutter_sources
    assert "desktop-topbar-single-row" in flutter_sources
    assert "_WorkbenchSidebar" in flutter_sources
    assert "ListView(" in flutter_sources
    assert "NavigationRail" not in flutter_sources
    assert "columns: 3" in flutter_sources


def test_web_pwa_and_flutter_platform_targets_are_scaffolded():
    android_activity = (
        WORKBENCH
        / "flutter_app"
        / "android"
        / "app"
        / "src"
        / "main"
        / "kotlin"
        / "com"
        / "heitang"
        / "workbench"
        / "MainActivity.kt"
    ).read_text(encoding="utf-8")
    android_gradle = (WORKBENCH / "flutter_app" / "android" / "app" / "build.gradle").read_text(encoding="utf-8")
    ios_info = (WORKBENCH / "flutter_app" / "ios" / "Runner" / "Info.plist").read_text(encoding="utf-8")

    assert (WORKBENCH / "manifest.webmanifest").exists()
    assert (WORKBENCH / "flutter_app" / "web" / "manifest.json").exists()
    assert (WORKBENCH / "flutter_app" / "web" / "index.html").exists()
    assert (WORKBENCH / "flutter_app" / "windows" / "CMakeLists.txt").exists()
    assert (WORKBENCH / "flutter_app" / "windows" / "runner" / "main.cpp").exists()
    assert (WORKBENCH / "flutter_app" / "android" / "settings.gradle").exists()
    assert (WORKBENCH / "flutter_app" / "android" / "app" / "src" / "main" / "AndroidManifest.xml").exists()
    assert (WORKBENCH / "flutter_app" / "ios" / "Runner" / "Info.plist").exists()
    assert "FlutterActivity" in android_activity
    assert "dev.flutter.flutter-gradle-plugin" in android_gradle
    assert "com.heitang.workbench" in ios_info
