from heitang_kb_forge.llm.call_log import write_call_log


def test_llm_call_log_redacts_api_key(tmp_path):
    path = tmp_path / "llm_call_log.jsonl"

    write_call_log(path, {"provider": "mock", "api_key": "secret-value"})

    text = path.read_text(encoding="utf-8")
    assert "secret-value" not in text
    assert "[REDACTED]" in text
