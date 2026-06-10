import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "docs" / "audits" / "s_a_contract_inclusion"


def _json(name: str) -> dict:
    return json.loads((AUDIT_DIR / name).read_text(encoding="utf-8"))


def test_planned_adapter_registry_contains_no_ready_or_local_executable_entries():
    payload = _json("planned_adapter_registry.json")

    assert payload["entry_count"] >= 8
    assert payload["ready_count"] == 0
    assert payload["can_execute_locally_before_v4_count"] == 0
    for entry in payload["entries"]:
        assert "planned_adapter" in entry["contract_status"]
        assert entry["can_execute_locally_before_v4"] is False
        if "optional_runtime_adapter" in entry["contract_status"]:
            assert "optional_runtime_dependency_missing" in entry["blocked_reasons"]
        else:
            assert "planned_adapter_not_implemented" in entry["blocked_reasons"]


def test_future_adapter_registry_contains_no_ready_or_local_executable_entries():
    payload = _json("future_adapter_registry.json")

    assert payload["entry_count"] >= 9
    assert payload["ready_count"] == 0
    assert payload["can_execute_locally_before_v4_count"] == 0
    for entry in payload["entries"]:
        assert "future_adapter" in entry["contract_status"]
        assert entry["can_execute_locally_before_v4"] is False
        assert "future_adapter_after_v4" in entry["blocked_reasons"]


def test_provider_boundary_report_keeps_provider_network_and_runtime_disabled():
    payload = _json("provider_boundary_report.json")
    entries = {entry["project_id"]: entry for entry in payload["entries"]}

    assert payload["provider_network_api_ready"] is False
    assert payload["n8n_bundled_runtime"] is False
    assert payload["anysearchskill_api_callable"] is False
    assert payload["weknora_embedded"] is False
    assert payload["llm_wiki_memory_engine_implemented"] is False
    assert entries["n8n"]["requires_external_runtime"] is True
    assert entries["anysearchskill"]["requires_api_key"] is True
    assert entries["anysearchskill"]["requires_network"] is True
    assert entries["last30days_skill"]["requires_network"] is True
    for entry in entries.values():
        assert entry["can_execute_locally_before_v4"] is False


def test_verified_closure_entries_are_not_executable():
    projects = {project["project_id"]: project for project in _json("external_capability_registry.json")["projects"]}

    for project_id in ["seedance2_skill", "rtk"]:
        assert "needs_verification" not in projects[project_id]["contract_status"]
        assert "needs_verification" not in projects[project_id]["blocked_reasons"]
        assert projects[project_id]["executable_action"] is False
        assert projects[project_id]["can_execute_locally_before_v4"] is False
