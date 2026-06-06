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


def test_flutter_scaffold_contains_adaptive_mobile_layout_not_simple_scaling():
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")

    assert "constraints.maxWidth < 720" in flutter_main
    assert "constraints.maxWidth >= 720 && constraints.maxWidth < 1040" in flutter_main
    assert "_PhoneWorkbench" in flutter_main
    assert "_DesktopWorkbench" in flutter_main
    assert "DropdownButtonFormField<int>" in flutter_main
    assert "_WorkbenchSidebar" in flutter_main
    assert "ListView.separated" in flutter_main
    assert "NavigationRail" not in flutter_main
    assert "columns: 1" in flutter_main


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
