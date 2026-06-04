from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_desktop_i18n_contains_english_and_chinese_labels():
    i18n = (ROOT / "desktop" / "tauri" / "src" / "i18n.ts").read_text(encoding="utf-8")

    assert 'defaultLocale: Locale = "zh-CN"' in i18n
    assert '"en-US":' in i18n
    assert "\"zh-CN\":" in i18n
    assert "HeiTang KB Forge Desktop" in i18n
    assert "本地桌面工具" in i18n
    assert "desktop tool" in i18n
    assert "本轮不实现数据库" in i18n


def test_desktop_i18n_contains_required_v124_keys():
    i18n = (ROOT / "desktop" / "tauri" / "src" / "i18n.ts").read_text(encoding="utf-8")
    for key in [
        "status.ready",
        "status.futureReserved",
        "field.knowledgeStoreBackend",
        "field.vectorStoreBackend",
        "field.agentTarget",
        "action.browse",
        "action.copy",
        "section.skillFirstBoundary",
        "page.settings.title",
        "page.lifecycle.description",
        "skillFirst.agentCallableSkill",
    ]:
        assert key in i18n


def test_settings_uses_global_locale_and_no_static_language_default():
    settings = (ROOT / "desktop" / "tauri" / "src" / "pages" / "Settings.tsx").read_text(encoding="utf-8")
    app = (ROOT / "desktop" / "tauri" / "src" / "App.tsx").read_text(encoding="utf-8")
    topbar = (ROOT / "desktop" / "tauri" / "src" / "components" / "TopBar.tsx").read_text(encoding="utf-8")

    assert "locale" in settings
    assert "setAppState" in settings
    assert "value={locale}" in settings
    assert "locale: defaultLocale" in app
    assert "setLocale" in topbar
    assert '<div className="readonly-field">zh-CN</div>' not in settings
