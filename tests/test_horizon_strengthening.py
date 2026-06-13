import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.horizon_strengthening import (
    build_horizon_strengthening_record,
    validate_horizon_strengthening_record,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def test_horizon_strengthening_record_builds_topic_intake_schema_only(tmp_path):
    output = tmp_path / "horizon"

    result = build_horizon_strengthening_record(output)
    validation = validate_horizon_strengthening_record(output)
    manifest = _json(output / "horizon_strengthening_manifest.json")
    scoring = _json(output / "source_scoring_rules.json")
    dedup = _json(output / "topic_dedup_rules.json")
    schema = _json(output / "briefing_candidate_schema.json")
    boundary = _json(output / "content_intake_boundary_rules.json")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert manifest["section"] == "5.S2"
    assert manifest["project_id"] == "horizon"
    assert manifest["integration_decision"] == "real_integration"
    assert manifest["decision_qualifier"] == "topic_intake_pipeline_schema_only"
    assert manifest["integration_mode"] == "topic_intake_pipeline_schema_strengthening"
    assert manifest["source_verification"]["repository_url"] == "https://github.com/Thysrael/Horizon"
    assert manifest["source_verification"]["repository_head"] == (
        "7e0ffbbd069765b77af053e73ccc0cd6ccc2456f"
    )
    assert manifest["source_verification"]["default_branch"] == "main"
    assert manifest["source_verification"]["license_spdx"] == "MIT"
    assert manifest["source_verification"]["repository_cloned"] is False
    assert manifest["source_verification"]["external_workflow_copied"] is False
    assert manifest["official_runtime_observation"]["runtime_installed"] is False
    assert manifest["official_runtime_observation"]["crawler_or_scraper_enabled"] is False
    assert manifest["official_runtime_observation"]["network_ingestion_executed"] is False
    assert manifest["runtime_boundary"]["local_topic_intake_schema_implemented"] is True
    assert manifest["runtime_boundary"]["horizon_runtime_integrated"] is False
    assert manifest["runtime_boundary"]["crawler_or_scraper_integrated"] is False
    assert manifest["runtime_boundary"]["scheduled_fetcher_enabled"] is False
    assert manifest["runtime_boundary"]["api_key_required"] is False
    assert manifest["runtime_boundary"]["delivery_channel_enabled"] is False
    assert manifest["runtime_boundary"]["campaign_3_3_0_implemented"] is False
    assert manifest["runtime_boundary"]["campaign_3_4_0_implemented"] is False
    assert manifest["ui_contract"]["topic_radar_visible"] is True
    assert manifest["ui_contract"]["daily_briefing_preview_visible"] is True
    assert manifest["ui_contract"]["ready"] is False
    assert manifest["ui_contract"]["executable_action"] is False
    assert {item["rule_id"] for item in scoring["rules"]} == {
        "source_trust_score",
        "freshness_window",
        "evidence_coverage_score",
    }
    assert {item["rule_id"] for item in dedup["rules"]} == {
        "canonical_url_hash",
        "cross_source_story_merge",
        "conflict_preserving_dedup",
    }
    assert {"candidate_id", "source_trace", "risk_flags"} <= set(schema["required_fields"])
    assert {item["rule_id"] for item in boundary["rules"]} == {
        "no_vendor_runtime",
        "no_crawler_or_scheduler",
        "no_delivery_or_mcp_side_effect",
        "no_campaign_3_0_substitution",
    }


def test_horizon_validation_rejects_runtime_or_crawler_drift(tmp_path):
    output = tmp_path / "horizon"
    build_horizon_strengthening_record(output)
    manifest_path = output / "horizon_strengthening_manifest.json"
    manifest = _json(manifest_path)
    manifest["runtime_boundary"]["horizon_runtime_integrated"] = True
    manifest["runtime_boundary"]["crawler_or_scraper_integrated"] = True
    manifest["ui_contract"]["ready"] = True
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")

    result = validate_horizon_strengthening_record(output)

    assert result["status"] == "failed"
    assert "horizon_runtime_integrated_must_be_false" in result["boundary_errors"]
    assert "crawler_or_scraper_integrated_must_be_false" in result["boundary_errors"]
    assert "ready_must_be_false" in result["boundary_errors"]


def test_horizon_cli_build_and_validate(tmp_path):
    library = tmp_path / "library"
    validation = tmp_path / "validation"
    runner = CliRunner()

    build_result = runner.invoke(
        app,
        ["build-horizon-strengthening-record", "--output", str(library)],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-horizon-strengthening-record",
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
    assert _json(validation / "horizon_strengthening_validation_report.json")["status"] == "passed"
