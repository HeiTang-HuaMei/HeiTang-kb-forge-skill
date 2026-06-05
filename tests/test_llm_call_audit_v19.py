from heitang_kb_forge.llm.audit import import_llm_call_logs


def test_llm_call_audit_imports_sanitized_records(tmp_path):
    workspace = tmp_path / "workspace"
    (workspace / "registries").mkdir(parents=True)
    log = tmp_path / "llm_call_log.jsonl"
    log.write_text('{"task":"skill_generation","provider":"mock","api_key":"secret","status":"success"}\n', encoding="utf-8")

    records = import_llm_call_logs(workspace, log)
    text = (workspace / "registries" / "llm_call_audit.jsonl").read_text(encoding="utf-8")

    assert records[0]["task"] == "skill_generation"
    assert "secret" not in text
