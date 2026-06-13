import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.gbrain_strengthening import (
    build_gbrain_strengthening_record,
    validate_gbrain_strengthening_record,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_gbrain_strengthening_record_preserves_runtime_boundaries(tmp_path):
    output = tmp_path / "gbrain"

    result = build_gbrain_strengthening_record(output)
    validation = validate_gbrain_strengthening_record(output)
    manifest = _json(output / "gbrain_strengthening_manifest.json")
    memory = _json(output / "memory_profile_rules.json")
    graph = _json(output / "knowledge_graph_gap_rules.json")
    boundary = _json(output / "agent_memory_boundary_rules.json")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert manifest["section"] == "5.S1"
    assert manifest["project_id"] == "gbrain"
    assert manifest["integration_decision"] == "needs_strengthening"
    assert manifest["integration_mode"] == "memory_profile_kg_strengthening_record"
    assert manifest["source_verification"]["repository_url"] == "https://github.com/garrytan/gbrain"
    assert manifest["source_verification"]["repository_head"] == (
        "4ee530f3c545b880cecc47c4f877e0ed014896b4"
    )
    assert manifest["source_verification"]["default_branch"] == "master"
    assert manifest["source_verification"]["license_spdx"] == "MIT"
    assert manifest["source_verification"]["repository_cloned"] is False
    assert manifest["source_verification"]["external_skill_files_copied"] is False
    assert manifest["official_runtime_observation"]["runtime_installed"] is False
    assert manifest["official_runtime_observation"]["database_created"] is False
    assert manifest["runtime_boundary"]["gbrain_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["bun_dependency_installed"] is False
    assert manifest["runtime_boundary"]["pglite_or_postgres_configured"] is False
    assert manifest["runtime_boundary"]["pgvector_required"] is False
    assert manifest["runtime_boundary"]["mcp_connector_enabled"] is False
    assert manifest["runtime_boundary"]["agent_created_or_bound"] is False
    assert manifest["runtime_boundary"]["campaign_3_3_0_implemented"] is False
    assert manifest["runtime_boundary"]["campaign_3_4_0_implemented"] is False
    assert manifest["ui_contract"]["local_ready"] is True
    assert manifest["ui_contract"]["ready"] is False
    assert manifest["ui_contract"]["executable_action"] is False
    assert {item["rule_id"] for item in memory["rules"]} == {
        "scope_memory_profile",
        "source_bound_identity",
        "confidence_and_staleness",
    }
    assert {item["rule_id"] for item in graph["rules"]} == {
        "typed_relation_gap_scan",
        "citation_gap_detection",
        "contradiction_gap_review",
    }
    assert {item["rule_id"] for item in boundary["rules"]} == {
        "no_runtime_install",
        "no_mcp_or_db_side_effect",
        "no_agent_binding_side_effect",
    }


def test_gbrain_validation_rejects_runtime_drift(tmp_path):
    output = tmp_path / "gbrain"
    build_gbrain_strengthening_record(output)
    manifest_path = output / "gbrain_strengthening_manifest.json"
    manifest = _json(manifest_path)
    manifest["runtime_boundary"]["gbrain_runtime_integrated"] = True
    manifest["ui_contract"]["ready"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_gbrain_strengthening_record(output)

    assert result["status"] == "failed"
    assert "gbrain_runtime_integrated_must_be_false" in result["boundary_errors"]
    assert "ready_must_be_false" in result["boundary_errors"]


def test_gbrain_cli_build_and_validate(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build_result = runner.invoke(
        app,
        ["build-gbrain-strengthening-record", "--output", str(library)],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-gbrain-strengthening-record",
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
    assert _json(validation / "gbrain_strengthening_validation_report.json")["status"] == "passed"
