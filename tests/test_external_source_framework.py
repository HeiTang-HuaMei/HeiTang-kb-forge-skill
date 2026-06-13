import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.external_sources import (
    build_external_source_framework,
    validate_external_source_framework,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_external_source_framework_builds_contracts_without_runtime_overclaim(tmp_path):
    output = tmp_path / "framework"

    result = build_external_source_framework(output)
    validation = validate_external_source_framework(output)
    manifest = _json(output / "external_source_framework_manifest.json")
    states = _json(output / "external_source_state_schema.json")
    chunks = _json(output / "external_source_chunk_schema.json")
    trace = _json(output / "external_source_trace_schema.json")
    evidence = _json(output / "external_evidence_map_schema.json")
    actions = _json(output / "external_source_action_registry.json")
    safety = _json(output / "external_source_safety_boundary.json")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert manifest["supplement"] == "3.0 External Source Memory & Verification"
    assert manifest["step"] == "P0 External Source Memory & Verification framework"
    assert manifest["integration_decision"] == "real_integration"
    assert manifest["decision_qualifier"] == "framework_only"
    assert manifest["runtime_boundary"]["framework_contracts_implemented"] is True
    assert manifest["runtime_boundary"]["generic_web_url_ingestion_implemented"] is False
    assert manifest["runtime_boundary"]["opencli_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["authenticated_browser_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["knowledge_verification_runtime_implemented"] is False
    assert manifest["runtime_boundary"]["campaign_3_3_0_accepted"] is False
    assert manifest["runtime_boundary"]["campaign_3_4_0_active"] is False
    assert manifest["runtime_boundary"]["campaign_4_allowed"] is False
    assert manifest["ui_contract"]["external_link_import_entry_required"] is True
    assert manifest["ui_contract"]["ui_entry_implemented"] is False
    assert manifest["ui_contract"]["ready"] is False
    assert manifest["core_bridge_contract"]["allowlist_required"] is True
    assert manifest["core_bridge_contract"]["registered_in_this_step"] is False
    assert manifest["core_bridge_contract"]["bridge_execution_accepted"] is False
    assert manifest["default_fetch_policy"] == {
        "url_depth": 0,
        "max_pages": 1,
        "same_domain_only": True,
        "timeout_seconds": 30,
        "respect_robots": True,
        "user_triggered_only": True,
    }
    assert "public_readable" in states["readability_states"]
    assert "anti_crawl_detected" in states["readability_states"]
    assert "user_authorized_session" in states["auth_session_states"]
    assert "conflicting" in states["verification_states"]
    assert "mixed_multimodal" in chunks["chunk_types"]
    assert {"chunk_id", "source_url", "content_hash", "backlink", "confidence"} <= set(
        chunks["required_fields"]
    )
    assert trace["source_trace_required"] is True
    assert trace["timestamp_trace_supported"] is True
    assert trace["image_trace_supported"] is True
    assert evidence["evidence_map_required"] is True
    assert evidence["supports_answer_grounding"] is True
    action_names = {item["action"] for item in actions["actions"]}
    for action in [
        "ingest-link",
        "batch-ingest-links",
        "detect-platform-link",
        "preflight-platform-link",
        "search-external-source",
        "verify-external-source",
        "import-manual-evidence",
        "verify-knowledge-base",
    ]:
        assert action in action_names
    assert all(item["arbitrary_shell_allowed"] is False for item in actions["actions"])
    assert safety["no_login_bypass"] is True
    assert safety["no_cookie_import"] is True
    assert safety["no_unlimited_crawler"] is True
    assert safety["authorized_browser_visible_content_only"] is True
    assert manifest["next_required_e2e_step"] == (
        "Run Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion only."
    )
    assert manifest["not_goal_complete"] is True


def test_external_source_framework_validation_rejects_runtime_and_ready_drift(tmp_path):
    output = tmp_path / "framework"
    build_external_source_framework(output)
    manifest_path = output / "external_source_framework_manifest.json"
    manifest = _json(manifest_path)
    manifest["runtime_boundary"]["generic_web_url_ingestion_implemented"] = True
    manifest["runtime_boundary"]["opencli_runtime_integrated"] = True
    manifest["ui_contract"]["ready"] = True
    manifest["core_bridge_contract"]["bridge_execution_accepted"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_external_source_framework(output)

    assert result["status"] == "failed"
    assert "generic_web_url_ingestion_implemented_must_be_false" in result["boundary_errors"]
    assert "opencli_runtime_integrated_must_be_false" in result["boundary_errors"]
    assert "ready_must_be_false" in result["boundary_errors"]
    assert "bridge_execution_accepted_must_be_false" in result["boundary_errors"]


def test_external_source_framework_cli_build_and_validate(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build_result = runner.invoke(
        app,
        ["build-external-source-framework", "--output", str(library)],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-external-source-framework",
            "--library",
            str(library),
            "--output",
            str(validation),
        ],
    )

    assert build_result.exit_code == 0, build_result.output
    assert "status=passed" in build_result.output
    assert "framework_only" in build_result.output
    assert validate_result.exit_code == 0, validate_result.output
    assert "status=passed" in validate_result.output
    assert _json(validation / "external_source_framework_validation_report.json")["status"] == "passed"
