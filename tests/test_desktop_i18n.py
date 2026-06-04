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
