import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.knowledge_lifecycle import write_knowledge_lifecycle_outputs


def _read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8-sig"))


def _write_package(package: Path) -> None:
    package.mkdir(parents=True)
    (package / "manifest.json").write_text(
        json.dumps(
            {
                "package_id": "pkg_test_lifecycle",
                "generated_at": "2026-06-01T00:00:00+00:00",
                "source_count": 1,
                "chunk_count": 2,
                "quality_status": "excellent",
            }
        ),
        encoding="utf-8",
    )
    chunks = [
        {
            "chunk_id": "chunk_a",
            "title": "Traceable source",
            "text": "A living knowledge base keeps source trace and refresh policy.",
            "source_path": "source_a.md",
        },
        {
            "chunk_id": "chunk_b",
            "title": "Second source",
            "text": "Confidence and retention decisions are local and deterministic.",
            "source_path": "source_b.md",
        },
    ]
    (package / "chunks.jsonl").write_text(
        "\n".join(json.dumps(chunk) for chunk in chunks) + "\n",
        encoding="utf-8",
    )
    (package / "evidence_map.json").write_text(
        json.dumps(
            {
                "chunks": {
                    "chunk_a": {
                        "evidence_id": "ev_chunk_a",
                        "source_file": "source_a.md",
                        "evidence_type": "text",
                    },
                    "chunk_b": {
                        "evidence_id": "ev_chunk_b",
                        "source_file": "source_b.md",
                        "evidence_type": "text",
                    },
                }
            }
        ),
        encoding="utf-8",
    )
    (package / "quality_report.json").write_text(
        json.dumps({"status": "pass", "quality_status": "excellent"}),
        encoding="utf-8",
    )
    (package / "source_inventory.json").write_text(
        json.dumps({"sources": ["source_a.md", "source_b.md"]}),
        encoding="utf-8",
    )


def test_knowledge_lifecycle_outputs_confidence_stale_refresh_and_trace(tmp_path):
    package = tmp_path / "package"
    output = tmp_path / "lifecycle"
    _write_package(package)

    result = write_knowledge_lifecycle_outputs(package, output, max_age_days=1)

    assert result["status"] == "passed"
    report = _read_json(output / "knowledge_lifecycle_report.json")
    confidence = _read_json(output / "confidence_report.json")
    stale = _read_json(output / "stale_evidence_report.json")
    refresh = _read_json(output / "refresh_suggestions.json")
    retention = _read_json(output / "forgetting_retention_plan.json")
    source_trace = _read_json(output / "source_trace.json")

    assert report["integration_mode"] == "capability_fusion"
    assert report["vendor_runtime_integrated"] is False
    assert report["llm_required"] is False
    assert report["network_required"] is False
    assert report["external_runtime_required"] is False
    assert confidence["average_confidence"] > 0.9
    assert stale["status"] in {"passed", "needs_refresh"}
    assert refresh["suggestion_count"] >= 0
    assert all(item["decision"] in {"retain", "retain_but_refresh", "quarantine_for_review"} for item in retention["items"])
    assert source_trace["source_trace_preserved"] is True
    assert (output / "knowledge_lifecycle_report.md").exists()


def test_plan_knowledge_lifecycle_cli_reads_knowledge_package(tmp_path):
    package = tmp_path / "package"
    output = tmp_path / "lifecycle"
    _write_package(package)

    result = CliRunner().invoke(
        app,
        [
            "plan-knowledge-lifecycle",
            "--knowledge-package",
            str(package),
            "--output",
            str(output),
            "--max-age-days",
            "1",
        ],
    )

    assert result.exit_code == 0, result.output
    report = _read_json(output / "knowledge_lifecycle_report.json")
    assert report["status"] == "passed"
    assert report["chunk_count"] == 2
    assert report["source_trace_preserved"] is True
    assert report["final_target_not_downgraded"] is True
    assert report["not_goal_complete"] is True
