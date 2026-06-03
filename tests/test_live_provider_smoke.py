import json

import pytest

from heitang_kb_forge.live.provider_smoke import make_live_provider_smoke_report, should_run_live_tests


def test_live_provider_smoke_report_does_not_leak_api_keys(monkeypatch):
    monkeypatch.setenv("HEITANG_LLM_API_KEY", "secret-llm-key")
    monkeypatch.setenv("HEITANG_LLM_BASE_URL", "https://example.test/v1")
    monkeypatch.setenv("HEITANG_LLM_MODEL", "model")
    report = make_live_provider_smoke_report()
    payload = json.dumps(report.model_dump(mode="json"))
    assert "secret-llm-key" not in payload
    assert report.llm_provider_configured is True


@pytest.mark.skipif(not should_run_live_tests(), reason="Live provider smoke tests require HEITANG_RUN_LIVE_TESTS=1")
def test_live_provider_smoke_entrypoint_is_explicitly_opt_in():
    report = make_live_provider_smoke_report()
    assert report.live_smoke_version == "1.0.0"
