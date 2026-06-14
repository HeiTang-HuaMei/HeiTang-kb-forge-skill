from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ICONS = ROOT / "desktop" / "tauri" / "src-tauri" / "icons"


def test_icon_sources_and_generated_assets_exist():
    for path in [
        ROOT / "assets" / "icon_sources" / "tiger_source.png",
        ROOT / "assets" / "icon_sources" / "cat_source.png",
        ICONS / "icon.ico",
        ICONS / "icon.png",
        ICONS / "32x32.png",
        ICONS / "128x128.png",
        ICONS / "128x128@2x.png",
        ICONS / "tiger-app-16.png",
        ICONS / "tiger-app-512.png",
        ICONS / "cat-small.ico",
        ICONS / "cat-window.png",
        ICONS / "cat-taskbar.png",
        ICONS / "cat-tray.png",
        ICONS / "cat-file.png",
        ROOT / "desktop" / "tauri" / "src" / "assets" / "icons" / "cat-head.png",
    ]:
        assert path.exists(), path


def test_tauri_regular_app_icon_uses_tiger_assets():
    config = (ROOT / "desktop" / "tauri" / "src-tauri" / "tauri.conf.json").read_text(encoding="utf-8")
    assert "icons/icon.ico" in config
    assert "cat-small.ico" not in config


def test_icon_guidelines_describe_tiger_cat_split():
    assert (ROOT / "assets" / "icon_sources" / "tiger_source.png").exists()
    assert (ROOT / "assets" / "icon_sources" / "cat_source.png").exists()
    config = (ROOT / "desktop" / "tauri" / "src-tauri" / "tauri.conf.json").read_text(encoding="utf-8")
    assert "icons/icon.ico" in config
