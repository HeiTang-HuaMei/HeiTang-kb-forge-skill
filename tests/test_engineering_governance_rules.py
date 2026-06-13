import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.engineering_governance_rules import (
    build_engineering_governance_rules,
    validate_engineering_governance_rules,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_engineering_governance_rules_preserve_boundaries(tmp_path):
    output = tmp_path / "rules"

    result = build_engineering_governance_rules(output)
    validation = validate_engineering_governance_rules(output)
    manifest = _json(output / "engineering_governance_manifest.json")
    pre_code = _json(output / "pre_code_gate_rules.json")
    test_gate = _json(output / "test_gate_rules.json")
    review_gate = _json(output / "review_gate_rules.json")
    collaboration = _json(output / "ai_collaboration_rules.json")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert manifest["section"] == "5.13"
    assert manifest["project_id"] == "mattpocock_skills"
    assert manifest["integration_decision"] == "real_integration"
    assert manifest["integration_mode"] == "engineering_governance_rule_pack"
    assert manifest["source_verification"]["repository_head"] == (
        "694fa30311e02c2639942308513555e61ee84a6f"
    )
    assert manifest["source_verification"]["license_spdx"] == "MIT"
    assert manifest["source_verification"]["repository_cloned"] is False
    assert manifest["source_verification"]["external_code_copied"] is False
    assert manifest["source_verification"]["external_prompt_text_copied"] is False
    assert manifest["source_verification"]["external_skill_files_copied"] is False
    assert manifest["runtime_boundary"]["external_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["external_agent_skill_installed"] is False
    assert manifest["runtime_boundary"]["business_runtime_created"] is False
    assert manifest["runtime_boundary"]["agent_created_or_bound"] is False
    assert manifest["runtime_boundary"]["campaign_3_3_0_implemented"] is False
    assert manifest["runtime_boundary"]["campaign_3_4_0_implemented"] is False
    assert manifest["ui_contract"]["local_ready"] is True
    assert manifest["ui_contract"]["ready"] is False
    assert manifest["ui_contract"]["executable_action"] is False
    assert {item["rule_id"] for item in pre_code["rules"]} == {
        "align_scope",
        "map_domain_language",
        "define_acceptance",
        "record_risks",
    }
    assert {item["rule_id"] for item in test_gate["rules"]} == {
        "red_first",
        "green_implementation",
        "refactor_with_regression",
        "diff_check",
    }
    assert {item["rule_id"] for item in review_gate["rules"]} == {
        "finite_priority_review",
        "evidence_first",
        "p3_backlog_only",
    }
    assert {item["rule_id"] for item in collaboration["rules"]} == {
        "concise_shared_language",
        "handoff_state",
        "ask_only_for_blocking_unknowns",
    }


def test_engineering_governance_validation_rejects_runtime_drift(tmp_path):
    output = tmp_path / "rules"
    build_engineering_governance_rules(output)
    manifest_path = output / "engineering_governance_manifest.json"
    manifest = _json(manifest_path)
    manifest["runtime_boundary"]["external_runtime_integrated"] = True
    manifest["ui_contract"]["ready"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_engineering_governance_rules(output)

    assert result["status"] == "failed"
    assert "external_runtime_integrated_must_be_false" in result["boundary_errors"]
    assert "ready_must_be_false" in result["boundary_errors"]


def test_engineering_governance_cli_build_and_validate(tmp_path):
    runner = CliRunner()
    library = tmp_path / "library"
    validation = tmp_path / "validation"

    build_result = runner.invoke(
        app,
        ["build-engineering-governance-rules", "--output", str(library)],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-engineering-governance-rules",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build_result.exit_code == 0, build_result.output
    assert "status=passed" in build_result.output
    assert validate_result.exit_code == 0, validate_result.output
    assert "status=passed" in validate_result.output
    assert _json(validation / "engineering_governance_validation_report.json")["status"] == "passed"
