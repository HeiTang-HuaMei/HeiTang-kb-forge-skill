import pytest


def test_web_app_imports_without_streamlit():
    from heitang_kb_forge.web import app

    assert hasattr(app, "render_app")


def test_web_app_reports_missing_optional_dependency(monkeypatch):
    from heitang_kb_forge.web.app import render_app

    monkeypatch.setitem(__import__("sys").modules, "streamlit", None)
    with pytest.raises(RuntimeError, match="Web UI dependencies are not installed"):
        render_app()
