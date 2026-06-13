import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.campaign_3_closure import (
    build_campaign_3_supplement_4_0_agent_package,
    validate_campaign_3_supplement_4_0_agent_package,
    write_campaign_3_supplement_4_0_agent_package,
)
from heitang_kb_forge.cli_runtime import app


ROOT = Path(__file__).resolve().parents[1]
AUDIT_DIR = ROOT / "artifacts" / "audits" / "section_5" / "campaign_3_supplement_4_0_agent_package"
NEXT_ACTION = "Campaign 3 Supplement 4.0E Agent Workspace Binding Spec only"


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_agent_package_builds_from_4_0c_dedicated_skill():
    report = build_campaign_3_supplement_4_0_agent_package(ROOT)
    profile = report["agent_profile"]
    manifest = report["agent_manifest"]

    assert report["status"] == "passed"
    assert report["implementation_level"] == "bounded industrial-grade implementation"
    assert report["decision_qualifier"] == "skill_to_agent_package_unification_only"
    assert report["preconditions"]["status"] == "passed"
    assert profile["agent_state"] == "agent_package_ready"
    assert profile["agent_runtime_state"] == "agent_runtime_not_integrated"
    assert profile["agent_executable_state"] == "agent_executable_not_ready"
    assert manifest["bound_to_kb"] is True
    assert manifest["bound_to_skill"] is True
    assert manifest["runtime_required"] is False


def test_agent_package_boundaries_do_not_claim_runtime_or_later_campaigns():
    report = build_campaign_3_supplement_4_0_agent_package(ROOT)
    state = report["campaign_state_after_step"]
    runtime = report["agent_runtime_boundary_report"]
    next_action = report["next_action_manifest"]

    assert state["campaign_3_supplement_4_0d_passed"] is True
    assert state["agent_package_ready"] is True
    assert state["agent_runtime_ready"] is False
    assert state["agent_executable"] is False
    assert state["campaign_3_supplement_4_0_acceptance_gate_passed"] is False
    assert state["campaign_4_active"] is False
    assert state["campaign_5_active"] is False
    assert runtime["agent_package_ready_is_agent_executable"] is False
    assert runtime["generate_agent_is_complete_runtime"] is False
    assert runtime["local_offline_runtime_formal_platform"] is False
    assert next_action["next_safe_action"] == NEXT_ACTION
    assert next_action["may_enter_4_0e_agent_workspace_binding"] is True
    assert next_action["may_enter_supplement_4_0_acceptance_gate"] is False
    assert next_action["may_enter_campaign_4"] is False
    assert next_action["may_enter_campaign_5"] is False


def test_write_outputs_include_required_agent_package_artifacts(tmp_path):
    output = tmp_path / "agent_package"
    report = write_campaign_3_supplement_4_0_agent_package(ROOT, output)

    assert report["status"] == "passed"
    for name in [
        "agent_package/agent_profile.json",
        "agent_package/agent_manifest.json",
        "agent_package/agent_config.json",
        "agent_package/agent_prompt.md",
        "agent_package/bound_knowledge_bases.json",
        "agent_package/bound_skills.json",
        "agent_package/memory_policy.md",
        "agent_package/memory_policy.yaml",
        "agent_package/workflow_policy.md",
        "agent_package/safety_boundary.md",
        "agent_package/output_contract.json",
        "agent_package/eval_cases.jsonl",
        "agent_package/source_trace.json",
        "agent_package/audit_manifest.json",
        "agent_package/export_manifest.json",
        "agent_state_matrix.json",
        "agent_runtime_boundary_report.json",
        "validation_report.json",
        "run_manifest.json",
        "checkpoint.json",
    ]:
        assert (output / name).exists()

    config = _json(output / "agent_package" / "agent_config.json")
    assert config["allow_shell"] is False
    assert config["allow_external_runtime"] is False
    assert config["execution_enabled"] is False
    assert _json(output / "checkpoint.json")["next_safe_action"] == NEXT_ACTION


def test_agent_package_validation_detects_runtime_overclaim(tmp_path):
    output = tmp_path / "agent_package"
    write_campaign_3_supplement_4_0_agent_package(ROOT, output)
    runtime_path = output / "agent_runtime_boundary_report.json"
    runtime = _json(runtime_path)
    runtime["generate_agent_is_complete_runtime"] = True
    runtime_path.write_text(json.dumps(runtime, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

    validation = validate_campaign_3_supplement_4_0_agent_package(ROOT, output)

    assert validation["status"] == "failed"
    assert "generate_agent_runtime_overclaim" in validation["errors"]


def test_agent_package_cli_build_and_validate_are_runnable(tmp_path):
    output = tmp_path / "agent_package"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "campaign-3-supplement-4-0-build-agent-package",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-campaign-3-supplement-4-0-agent-package",
            "--repo-root",
            str(ROOT),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "skill_to_agent_package_unification_only" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert _json(output / "validation_report.json")["status"] == "passed"


def test_active_agent_package_audit_outputs_validate_when_present():
    if not AUDIT_DIR.exists():
        return

    validation = validate_campaign_3_supplement_4_0_agent_package(ROOT, AUDIT_DIR)

    assert validation["status"] == "passed"
    assert validation["next_safe_action"] == NEXT_ACTION
    assert validation["campaign_3_supplement_4_0_acceptance_gate_passed"] is False
    assert validation["campaign_4_active"] is False
    assert validation["campaign_5_active"] is False
