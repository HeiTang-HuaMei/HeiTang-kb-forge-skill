import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.external_sources import (
    build_external_source_unified_trace,
    validate_external_source_unified_trace,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _write_pipeline_fixtures(root: Path) -> None:
    _write_generic_fixture(root / "external_source_generic_url" / "ingestion")
    _write_platform_fixture(root / "external_source_platform_preflight" / "preflight")
    _write_opencli_fixture(root / "external_source_opencli_verification")
    _write_manual_fixture(root / "external_source_manual_evidence")


def _write_generic_fixture(path: Path) -> None:
    write_json(
        path / "link_ingestion_report.json",
        {
            "status": "passed",
            "integration_decision": "real_integration",
            "decision_qualifier": "generic_web_url_ingestion_only",
            "integration_mode": "public_http_html_to_traceable_chunks",
        },
    )
    write_json(path / "generic_web_url_ingestion_validation_report.json", {"status": "passed", "boundary_errors": []})
    write_json(
        path / "external_source_trace.json",
        {
            "source_count": 1,
            "sources": [
                {
                    "source_id": "web_source_1",
                    "source_type": "public_html",
                    "source_url": "https://example.com/docs",
                    "canonical_url": "https://example.com/docs",
                    "content_hash": "hash_web",
                    "backlink": "https://example.com/docs",
                    "trace_status": "public_readable",
                    "failure_reason": "",
                }
            ],
        },
    )
    write_json(
        path / "external_evidence_map.json",
        {
            "evidence_count": 1,
            "evidence": [
                {
                    "evidence_id": "web_ev_1",
                    "chunk_id": "web_chunk_1",
                    "source_id": "web_source_1",
                    "support_status": "source_chunk",
                    "confidence": 0.86,
                    "backlink": "https://example.com/docs",
                }
            ],
        },
    )


def _write_platform_fixture(path: Path) -> None:
    write_json(
        path / "platform_preflight_report.json",
        {
            "status": "passed",
            "integration_decision": "real_integration",
            "decision_qualifier": "platform_preflight_only",
            "integration_mode": "platform_link_detection_and_structured_readability_state",
            "records": [
                {
                    "source_id": "platform_xhs",
                    "source_url": "https://www.xiaohongshu.com/explore/abc",
                    "platform": "xiaohongshu",
                    "platform_label": "Xiaohongshu note",
                    "source_type": "platform_note",
                    "readability_state": "auth_required",
                    "failure_reason": "Requires user-visible authorized session; no bypass allowed.",
                    "next_available_paths": ["opencli_external_search_verification", "manual_evidence_upload"],
                },
                {
                    "source_id": "platform_zhihu",
                    "source_url": "https://www.zhihu.com/question/1/answer/2",
                    "platform": "zhihu",
                    "platform_label": "Zhihu answer",
                    "source_type": "platform_article",
                    "readability_state": "partial_readable",
                    "failure_reason": "Partial public content only.",
                    "next_available_paths": ["manual_evidence_upload"],
                },
            ],
        },
    )
    write_json(path / "platform_preflight_validation_report.json", {"status": "passed", "boundary_errors": []})


def _write_opencli_fixture(path: Path) -> None:
    write_json(
        path / "external_verification_report.json",
        {
            "status": "passed",
            "integration_decision": "real_integration",
            "decision_qualifier": "opencli_external_search_verification_only",
            "integration_mode": "opencli_read_only_public_source_search_to_evidence_pipeline",
        },
    )
    write_json(path / "opencli_external_verification_validation_report.json", {"status": "passed", "boundary_errors": []})
    write_json(
        path / "external_source_trace.json",
        {
            "source_count": 1,
            "sources": [
                {
                    "source_id": "opencli_candidate_1",
                    "evidence_id": "opencli_ev_1",
                    "source_type": "public_registry_result",
                    "title": "OpenCLI",
                    "source_url": "https://www.npmjs.com/package/opencli",
                    "provider": "opencli:npm",
                    "retrieved_at": "2026-06-13T00:00:00+08:00",
                }
            ],
        },
    )
    write_json(
        path / "external_evidence_map.json",
        {
            "evidence_count": 1,
            "evidence": [
                {
                    "evidence_id": "opencli_ev_1",
                    "candidate_id": "opencli_candidate_1",
                    "source_url": "https://www.npmjs.com/package/opencli",
                    "source_type": "public_registry_result",
                    "confidence": 0.82,
                    "support_state": "supporting_candidate",
                }
            ],
        },
    )


def _write_manual_fixture(path: Path) -> None:
    trace = {
        "trace_id": "manual_trace_1",
        "trace_type": "manual_evidence",
        "manual_evidence_not_public_fetch": True,
        "manual_evidence_not_ocr_completion": True,
        "manual_evidence_not_browser_read": True,
        "manual_evidence_not_opencli_result": True,
    }
    write_json(
        path / "manual_evidence_manifest.json",
        {
            "status": "passed",
            "integration_decision": "real_integration",
            "decision_qualifier": "manual_evidence_upload_only",
            "integration_mode": "user_supplied_manual_evidence_to_traceable_blocks",
        },
    )
    write_json(path / "manual_evidence_validation_report.json", {"status": "passed", "boundary_errors": []})
    write_json(
        path / "manual_source_trace.json",
        {
            "source_count": 1,
            "sources": [
                {
                    "evidence_id": "manual_ev_1",
                    "source_type": "manual_upload",
                    "manual_input_type": "copied_text",
                    "user_provided_source_url": "https://example.com/manual-source",
                    "title": "Manual note",
                    "content_hash": "hash_manual",
                    "backlink": "manual_evidence_manifest.json#manual_ev_1",
                    "trace_status": "accepted",
                    "failure_reason": "",
                    "trace": trace,
                }
            ],
        },
    )
    write_json(
        path / "manual_evidence_map.json",
        {
            "evidence_count": 1,
            "evidence": [
                {
                    "evidence_id": "manual_ev_1",
                    "chunk_id": "manual_chunk_1",
                    "source_type": "manual_upload",
                    "support_status": "manual_evidence_accepted",
                    "confidence": 0.9,
                    "content_hash": "hash_manual",
                    "backlink": "manual_evidence_manifest.json#manual_ev_1",
                    "trace": trace,
                }
            ],
        },
    )


def test_unified_trace_combines_completed_p0_pipelines_with_source_level_status(tmp_path):
    evidence_root = tmp_path / "section_5"
    output = tmp_path / "unified"
    _write_pipeline_fixtures(evidence_root)

    result = build_external_source_unified_trace(output, evidence_root=evidence_root)
    validation = validate_external_source_unified_trace(output)
    trace = _json(output / "unified_source_trace.json")
    evidence_map = _json(output / "unified_evidence_map.json")
    failures = _json(output / "external_source_failure_isolation_report.json")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert {pipeline["pipeline_id"] for pipeline in trace["pipelines"]} == {
        "generic_web_url",
        "platform_link_preflight",
        "opencli_external_search_verification",
        "manual_evidence_upload",
    }
    assert all(pipeline["status"] == "passed" for pipeline in trace["pipelines"])
    source_statuses = {source["source_status"] for source in trace["sources"]}
    assert {"passed", "blocked", "partial"}.issubset(source_statuses)
    assert failures["isolated_failure_count"] == 2
    assert evidence_map["evidence_count"] == 5


def test_unified_evidence_map_preserves_traceability_and_decision_boundaries(tmp_path):
    evidence_root = tmp_path / "section_5"
    output = tmp_path / "unified"
    _write_pipeline_fixtures(evidence_root)

    build_external_source_unified_trace(output, evidence_root=evidence_root)
    trace = _json(output / "unified_source_trace.json")
    evidence = _json(output / "unified_evidence_map.json")["evidence"]

    manual_sources = [source for source in trace["sources"] if source["source_pipeline"] == "manual_evidence_upload"]
    opencli_sources = [source for source in trace["sources"] if source["source_pipeline"] == "opencli_external_search_verification"]
    platform_evidence = [item for item in evidence if item["source_pipeline"] == "platform_link_preflight"]

    assert manual_sources[0]["decision_class"] == "manual_evidence"
    assert "platform_fetch" not in manual_sources[0]["integration_mode"]
    assert opencli_sources[0]["decision_class"] == "verification_result"
    assert "browser" not in opencli_sources[0]["integration_mode"]
    assert platform_evidence[0]["decision_class"] == "preflight_only"
    for item in evidence:
        assert item["source_id"]
        assert item["evidence_id"]
        assert item["content_hash"]
        assert item["source_type"]
        assert item["integration_mode"]
        assert item["source_audit_file"]
        assert item["evidence_audit_file"]


def test_progress_events_have_required_industrial_fields(tmp_path):
    evidence_root = tmp_path / "section_5"
    output = tmp_path / "unified"
    _write_pipeline_fixtures(evidence_root)

    build_external_source_unified_trace(output, evidence_root=evidence_root)
    events = _jsonl(output / "external_source_progress_events.jsonl")

    assert {event["stage"] for event in events} >= {
        "build_started",
        "pipeline_discovered",
        "pipeline_merged",
        "failure_isolated",
        "validation_completed",
        "build_completed",
    }
    for event in events:
        assert event["stage"]
        assert event["status"]
        assert event["timestamp"]
        assert event["message"]
        assert event["artifact_path"]


def test_missing_pipeline_is_isolated_not_crashing_unified_report(tmp_path):
    evidence_root = tmp_path / "section_5"
    output = tmp_path / "unified"
    _write_generic_fixture(evidence_root / "external_source_generic_url" / "ingestion")
    _write_platform_fixture(evidence_root / "external_source_platform_preflight" / "preflight")
    _write_manual_fixture(evidence_root / "external_source_manual_evidence")

    result = build_external_source_unified_trace(output, evidence_root=evidence_root)
    validation = validate_external_source_unified_trace(output)
    failures = _json(output / "external_source_failure_isolation_report.json")

    assert result["status"] == "partial"
    assert validation["status"] == "passed"
    assert any(item["pipeline_id"] == "opencli_external_search_verification" for item in failures["isolated_failures"])
    assert failures["one_source_failure_does_not_abort_unified_report"] is True


def test_unified_trace_preserves_planned_not_active_later_business_boundaries(tmp_path):
    evidence_root = tmp_path / "section_5"
    output = tmp_path / "unified"
    _write_pipeline_fixtures(evidence_root)

    build_external_source_unified_trace(output, evidence_root=evidence_root)
    trace = _json(output / "unified_source_trace.json")
    evidence_map = _json(output / "unified_evidence_map.json")
    runtime = trace["runtime_boundary"]

    assert runtime["authenticated_browser_runtime_integrated"] is False
    assert runtime["video_transcription_implemented"] is False
    assert runtime["visual_ocr_runtime_integrated"] is False
    assert runtime["knowledge_verification_runtime_implemented"] is False
    assert runtime["campaign_3_3_0_accepted"] is False
    assert runtime["campaign_3_4_0_active"] is False
    assert runtime["campaign_4_allowed"] is False
    assert evidence_map["knowledge_verification_engine_completed"] is False
    assert trace["planned_not_active_schema_fields"]["video_ocr_visual_evidence"] == "planned_not_active"
    assert trace["planned_not_active_schema_fields"]["knowledge_verification_engine"] == "planned_not_active"


def test_cli_build_and_validate_unified_trace_are_runnable(tmp_path):
    evidence_root = tmp_path / "section_5"
    output = tmp_path / "unified"
    validation_output = tmp_path / "validation"
    _write_pipeline_fixtures(evidence_root)
    runner = CliRunner()

    build_result = runner.invoke(
        app,
        [
            "build-external-source-unified-trace",
            "--evidence-root",
            str(evidence_root),
            "--output",
            str(output),
        ],
    )
    validate_result = runner.invoke(
        app,
        [
            "validate-external-source-unified-trace",
            "--library",
            str(output),
            "--output",
            str(validation_output),
        ],
    )

    assert build_result.exit_code == 0, build_result.output
    assert validate_result.exit_code == 0, validate_result.output
    assert _json(output / "unified_source_trace.json")["status"] == "passed"
    assert _json(validation_output / "unified_trace_validation_report.json")["status"] == "passed"
