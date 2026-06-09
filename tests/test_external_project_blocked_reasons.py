import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "docs" / "audits" / "s_a_contract_inclusion"

REQUIRED_REASONS = {
    "external_project_registry_only",
    "benchmark_only_not_runtime",
    "planned_adapter_not_implemented",
    "future_adapter_after_v4",
    "provider_required",
    "secret_required",
    "network_required",
    "external_runtime_required",
    "license_review_required",
    "security_review_required",
    "needs_verification",
    "not_p1_blocker",
    "post_v4_target",
    "ui_visibility_only",
    "template_reference_only",
}


def _json(name: str) -> dict:
    return json.loads((AUDIT_DIR / name).read_text(encoding="utf-8"))


def test_blocked_reason_taxonomy_contains_required_reasons():
    payload = _json("workbench_error_taxonomy.json")
    reasons = {entry["blocked_reason"]: entry for entry in payload["blocked_reasons"]}

    assert REQUIRED_REASONS <= set(reasons)
    for reason in REQUIRED_REASONS:
        assert reasons[reason]["local_ready_allowed"] is False
        assert reasons[reason]["p1_gate_impact"] == "none"


def test_provider_secret_network_reasons_cannot_be_local_ready():
    projects = _json("external_capability_registry.json")["projects"]

    for project in projects:
        if project["requires_api_key"]:
            assert "secret_required" in project["blocked_reasons"]
            assert project["can_execute_locally_before_v4"] is False
        if project["requires_network"]:
            assert "network_required" in project["blocked_reasons"]
            assert project["can_execute_locally_before_v4"] is False
        if project["requires_external_runtime"]:
            assert "external_runtime_required" in project["blocked_reasons"]
            assert project["can_execute_locally_before_v4"] is False


def test_template_reference_entries_are_template_only():
    projects = {project["project_id"]: project for project in _json("external_capability_registry.json")["projects"]}

    for project_id in ["jellyfish", "story_flicks", "ai_marketing_skills"]:
        project = projects[project_id]
        assert "template_reference" in project["contract_status"]
        assert "template_reference_only" in project["blocked_reasons"]
        assert project["executable_action"] is False
