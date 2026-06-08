from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.pre_v4_p0 import (
    run_agent_runtime_completion,
    run_lifecycle_completion,
    run_live_llm_acceptance,
    run_memory_completion,
    run_pre_v4_p0_completion,
    run_rag_index_completion,
    run_security_completion,
    run_storage_completion,
)
from tests.p0_helpers import make_p0_package, read_json


def test_rag_index_completion_proves_local_index_loop(tmp_path):
    package = make_p0_package(tmp_path)

    report = run_rag_index_completion(package, tmp_path / "out")

    assert report["status"] == "pass"
    assert report["chunk_strategy_status"] == "pass"
    assert report["metadata_schema_status"] == "pass"
    assert report["local_vector_index_status"] == "pass"
    assert report["hybrid_retrieval_status"] == "pass"
    assert report["incremental_update_status"] == "pass"
    assert report["stale_index_detection_status"] == "pass"


def test_agent_runtime_completion_blocks_unauthorized_kb_and_writes_trace(tmp_path):
    package = make_p0_package(tmp_path)
    output = tmp_path / "out"

    report = run_agent_runtime_completion(package, output)

    assert report["status"] == "pass"
    access = read_json(output / "agent_kb_access_control_report.json")
    assert access["own_kb_access"] == "allowed"
    assert access["unauthorized_kb_access"] == "denied"
    trace = read_json(output / "agent_tool_call_trace.json")
    assert any(step.get("tool") == "local_kb_retrieval" for step in trace["steps"])
    assert read_json(output / "agent_loop_safety_report.json")["infinite_loop_prevented"] is True


def test_memory_storage_security_completion_keep_local_privacy_boundary(tmp_path):
    package = make_p0_package(tmp_path)

    memory = run_memory_completion(package, tmp_path / "memory")
    storage = run_storage_completion(tmp_path / "storage")
    security = run_security_completion(tmp_path, tmp_path / "security")

    assert memory["status"] == "pass"
    assert memory["no_all_history_injection"] is True
    assert storage["status"] == "pass"
    assert storage["no_platform_hosted_user_data"] is True
    assert storage["no_hidden_upload"] is True
    assert security["status"] == "blocked"


def test_live_llm_acceptance_does_not_require_network_or_print_key(tmp_path, monkeypatch):
    for name in [
        "HEITANG_LLM_ACCEPTANCE_ENABLED",
        "HEITANG_LLM_PROVIDER",
        "HEITANG_LLM_BASE_URL",
        "HEITANG_LLM_API_KEY",
        "HEITANG_LLM_MODEL",
        "HEITANG_LLM_TIMEOUT_SEC",
    ]:
        monkeypatch.delenv(name, raising=False)

    report = run_live_llm_acceptance(tmp_path)

    assert report["status"] == "blocked_with_reason"
    assert report["blocked_reason"] == "required_env_missing_or_process_environment_not_inherited"
    assert report["api_key_redacted"] is True
    assert report["tests_require_real_llm_api_network"] is False
    assert "sk-live-secret" not in (tmp_path / "live_llm_acceptance_report.md").read_text(encoding="utf-8")


def test_pre_v4_p0_completion_writes_final_gate_and_is_honest_about_missing_live_llm(tmp_path):
    package = make_p0_package(tmp_path)
    (tmp_path / ".gitignore").write_text("_local_acceptance_inputs/\n_local_acceptance_outputs/\n_local_acceptance_config/\n", encoding="utf-8")
    output = tmp_path / "out"

    summary = run_pre_v4_p0_completion(tmp_path, package, output)

    assert summary["status"] == "blocked"
    assert summary["p0_blockers"] == ["full_ocr"]
    assert summary["blocking_p1_or_live_acceptance_review"] == ["live_llm"]
    assert summary["blocking_p1_count"] == 0
    gate = read_json(output / "final_v4_rc_gate_report.json")
    assert gate["ready_for_v4_rc"] is False
    assert gate["ui_full_operation_readiness"]["classification"] == "not_run_core_only"


def test_pre_v4_p0_cli_runs_and_writes_reports(tmp_path):
    package = make_p0_package(tmp_path)
    (tmp_path / ".gitignore").write_text("_local_acceptance_inputs/\n_local_acceptance_outputs/\n_local_acceptance_config/\n", encoding="utf-8")
    output = tmp_path / "out"

    result = CliRunner().invoke(
        app,
        [
            "pre-v4-p0-completion",
            "--core-repo",
            str(tmp_path),
            "--package",
            str(package),
            "--output",
            str(output),
        ],
    )

    assert result.exit_code == 0, result.output
    assert "Pre-v4 P0 completion: blocked" in result.output
    assert (output / "pre_v4_p0_completion_report.json").exists()
    assert (output / "final_v4_rc_gate_report.json").exists()
