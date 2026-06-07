import json

import pytest

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench_contracts import generate_workbench_contracts


def test_workbench_contracts_describe_core_assets_and_actions(tmp_path):
    core = tmp_path / "core"
    core.mkdir()
    write_json(core / "manifest.json", {"package_id": "demo"})
    write_json(core / "generated_file_report.json", {"status": "pass"})
    (core / "skill_package").mkdir()
    (core / "skill_package" / "SKILL.md").write_text("# Demo Skill\n", encoding="utf-8")
    write_json(core / "hierarchy_trace.json", {"status": "pass"})
    write_json(core / "memory_writeback_report.json", {"status": "queued"})
    write_json(core / "memory_isolation_report.json", {"status": "pass"})
    write_json(core / "memory_lifecycle_report.json", {"status": "contract_only"})

    result = generate_workbench_contracts(core, project_name="Demo Workbench")

    assert result["status"] == "ready"
    status = _json(core / "workbench_status_contract.json")
    assert status["asset_count"] == 7
    assert status["hierarchy_trace_available"] is True
    assert status["memory_writeback_available"] is True
    assert status["storage_backend"] == "local_workspace"
    assert status["backup_export_status"] == "available_local_export"
    actions = _json(core / "workbench_action_contract.json")["actions"]
    assert {action["command"] for action in actions} >= {"build", "generate-documents", "generate-bound-agent", "orchestrate-multi-kb --parent-writeback"}
    assert _json(core / "workbench_agent_contract.json")["hierarchy_roles"] == ["mother_agent", "child_agent"]
    hierarchy = _json(core / "workbench_hierarchy_contract.json")
    assert hierarchy["entities"]["parent_child_binding"]["required_fields"] == ["parent", "child", "child_mode", "bound_kbs"]
    memory = _json(core / "workbench_memory_contract.json")
    assert memory["policy"]["workflow_shared_memory"] == "explicit_only"
    assert "token_budget_policy" in memory["lifecycle_fields"]
    assert "memory_candidate_queue.jsonl" in memory["status_files"]
    storage = _json(core / "workbench_storage_contract.json")
    assert storage["storage_backend"] == "local_workspace"
    assert storage["supported_storage_backends"] == ["local_workspace", "local_db", "byo_cloud"]
    assert storage["future_backends"]["byo_cloud"]["platform_hosted_user_data"] is False
    assert set(storage["storage_areas"]) >= {
        "local_workspace",
        "package_storage",
        "skill_storage",
        "agent_storage",
        "memory_storage",
        "index_storage",
        "generated_document_storage",
    }
    assert storage["storage_areas"]["memory_storage"]["backend"] == "local_workspace"
    assert {"memory_size_bytes", "package_size_bytes", "index_size_bytes", "generated_document_size_bytes"}.issubset(storage["sizes"])
    assert "cleanup_suggestions" in storage
    assert storage["compaction_status"] == "not_required"
    assert storage["backup_export_status"] == "available_local_export"
    error_contract = _json(core / "workbench_error_contract.json")
    assert "contract_file_missing" in {state["id"] for state in error_contract["error_states"]}
    assert "no_assets" in {state["id"] for state in error_contract["empty_states"]}
    assert (core / "workbench_contract_report.md").exists()


def test_workbench_contracts_require_existing_core_output(tmp_path):
    with pytest.raises(FileNotFoundError):
        generate_workbench_contracts(tmp_path / "missing")


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
