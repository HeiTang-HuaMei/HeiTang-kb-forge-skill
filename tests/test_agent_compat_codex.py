import json

from heitang_kb_forge.agent_compat.checker import check_agent_compat
from heitang_kb_forge.agent_compat import export_agent_compat


def test_agent_compat_exports_codex_files(tmp_path):
    result = export_agent_compat(tmp_path, "Demo Agent")

    assert (tmp_path / "compat" / "codex_instructions.md").exists()
    assert (tmp_path / "compat" / "codex_task_plan.md").exists()
    assert (tmp_path / "compat" / "codex_harness_contract.json").exists()
    assert (tmp_path / "compat" / "codex_harness_check_result.json").exists()
    assert result["codex_harness"]["status"] == "passed"
    assert result["codex_harness"]["failed_checks"] == []

    contract = json.loads((tmp_path / "compat" / "codex_harness_contract.json").read_text(encoding="utf-8"))
    assert contract["schema_version"] == "codex_execution_harness.v1"
    assert contract["execution_mode"] == "local_codex_handoff_contract"
    assert contract["boundary"]["network"] == "not_required"
    assert contract["boundary"]["redis_service_packaging"] == "forbidden"
    assert contract["boundary"]["vector_service_packaging"] == "forbidden"


def test_codex_harness_check_fails_when_contract_is_missing(tmp_path):
    export_agent_compat(tmp_path, "Demo Agent")
    (tmp_path / "compat" / "codex_harness_contract.json").unlink()

    result = check_agent_compat(tmp_path / "compat")

    assert result["status"] == "failed"
    assert result["codex_harness"]["status"] == "failed"
    assert "codex_harness_failed" in result["failed_checks"]
    assert "codex_harness_contract.json" in result["codex_harness"]["missing_files"]

