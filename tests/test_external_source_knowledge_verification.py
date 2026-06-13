import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.external_sources import (
    validate_knowledge_verification,
    verify_answer,
    verify_claims,
    verify_knowledge_base,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _evidence_file(path: Path) -> Path:
    rows = [
        {
            "evidence_id": "ev_1",
            "source_id": "source_public_doc",
            "source_type": "public_doc",
            "source_url": "https://example.test/docs",
            "title": "Public docs",
            "text": "HeiTang external source verification supports traceable evidence maps.",
            "published_at": "2026-01-01",
            "content_hash": "hash_1",
            "backlink": "https://example.test/docs#verification",
        },
        {
            "evidence_id": "ev_2",
            "source_id": "source_manual_note",
            "source_type": "manual_evidence",
            "source_url": "",
            "title": "Manual note",
            "text": "HeiTang external source verification supports traceable evidence maps.",
            "published_at": "2026-01-02",
            "content_hash": "hash_2",
            "backlink": "manual_evidence_manifest.json#ev_2",
        },
        {
            "evidence_id": "ev_3",
            "source_id": "source_conflict",
            "source_type": "public_doc",
            "source_url": "https://example.test/conflict",
            "title": "Conflict docs",
            "text": "HeiTang external source verification does not support traceable evidence maps.",
            "published_at": "2026-01-03",
            "content_hash": "hash_3",
            "backlink": "https://example.test/conflict",
        },
    ]
    path.write_text("\n".join(json.dumps(row) for row in rows) + "\n", encoding="utf-8")
    return path


def test_verify_claims_generates_trace_correctness_grounding_and_dashboard(tmp_path):
    evidence = _evidence_file(tmp_path / "evidence.jsonl")

    report = verify_claims(
        tmp_path / "out",
        claim=["HeiTang external source verification supports traceable evidence maps."],
        evidence_file=[evidence],
    )
    validation = validate_knowledge_verification(tmp_path / "out")
    correctness = _json(tmp_path / "out" / "knowledge_correctness_report.json")
    grounding = _json(tmp_path / "out" / "answer_grounding_report.json")
    trace = _json(tmp_path / "out" / "verification_source_trace.json")
    evidence_map = _json(tmp_path / "out" / "verification_evidence_map.json")
    dashboard = _json(tmp_path / "out" / "knowledge_verification_dashboard.json")

    assert report["status"] == "passed"
    assert report["decision_qualifier"] == "knowledge_verification_foundations_only"
    assert report["claims"][0]["verification_status"] == "verified"
    assert report["claims"][0]["supporting_sources"][0]["backlink"]
    assert correctness["overall_correctness"] == 1.0
    assert grounding["status"] == "passed"
    assert trace["source_count"] == 3
    assert evidence_map["knowledge_verification_engine_foundations_complete"] is True
    assert dashboard["dashboard_foundation_only"] is True
    assert dashboard["not_campaign_4_ui"] is True
    assert validation["status"] == "passed"


def test_conflicting_and_unsupported_claims_are_structured(tmp_path):
    evidence = _evidence_file(tmp_path / "evidence.jsonl")

    verify_claims(
        tmp_path / "out",
        claim=[
            "HeiTang external source verification supports traceable evidence maps.",
            "HeiTang unsupported claim requires a source.",
            "HeiTang external source verification does not support traceable evidence maps.",
        ],
        evidence_file=[evidence],
    )
    report = _json(tmp_path / "out" / "claim_verification_report.json")
    statuses = {row["text"]: row["verification_status"] for row in report["claims"]}

    assert statuses["HeiTang external source verification supports traceable evidence maps."] == "verified"
    assert statuses["HeiTang unsupported claim requires a source."] == "unsupported"
    assert statuses["HeiTang external source verification does not support traceable evidence maps."] == "conflicting"
    unsupported = [row for row in report["claims"] if row["verification_status"] == "unsupported"][0]
    assert unsupported["failure_reason"] == "No supporting external evidence was found."
    assert unsupported["repair_suggestion"]


def test_verify_answer_extracts_answer_claims_and_scores_grounding(tmp_path):
    evidence = _evidence_file(tmp_path / "evidence.jsonl")

    verify_answer(
        tmp_path / "out",
        answer="HeiTang external source verification supports traceable evidence maps.",
        evidence_file=[evidence],
    )
    grounding = _json(tmp_path / "out" / "answer_grounding_report.json")

    assert grounding["answer_present"] is True
    assert grounding["answer_claim_count"] == 1
    assert grounding["answer_grounding_score"] == 1.0


def test_verify_knowledge_base_reads_claim_file(tmp_path):
    evidence = _evidence_file(tmp_path / "evidence.jsonl")
    kb = tmp_path / "kb.md"
    kb.write_text("HeiTang external source verification supports traceable evidence maps.", encoding="utf-8")

    report = verify_knowledge_base(tmp_path / "out", knowledge_file=[kb], evidence_file=[evidence])

    assert report["claim_count"] == 1
    assert _json(tmp_path / "out" / "claim_verification_report.json")["claims"][0]["verification_status"] == "verified"


def test_cli_verify_claims_validate_and_generate_correctness_report(tmp_path):
    evidence = _evidence_file(tmp_path / "evidence.jsonl")
    output = tmp_path / "out"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "verify-claims",
            "--output",
            str(output),
            "--claim",
            "HeiTang external source verification supports traceable evidence maps.",
            "--evidence-file",
            str(evidence),
        ],
    )
    validate = runner.invoke(
        app,
        ["validate-knowledge-verification", "--library", str(output), "--output", str(output)],
    )
    summary = runner.invoke(
        app,
        [
            "generate-correctness-report",
            "--output",
            str(tmp_path / "summary"),
            "--claim-report",
            str(output / "claim_verification_report.json"),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "knowledge_verification_foundations_only" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
    assert summary.exit_code == 0, summary.output
    assert "overall_correctness=1.0" in summary.output


def test_cli_verify_claims_preserves_package_mode_and_external_alias(tmp_path):
    evidence = _evidence_file(tmp_path / "evidence.jsonl")
    output = tmp_path / "out"
    runner = CliRunner()

    build = runner.invoke(
        app,
        [
            "verify-external-claims",
            "--output",
            str(output),
            "--claim",
            "HeiTang external source verification supports traceable evidence maps.",
            "--evidence-file",
            str(evidence),
        ],
    )
    conflict = runner.invoke(
        app,
        [
            "verify-claims",
            "--package",
            str(tmp_path),
            "--output",
            str(tmp_path / "conflict"),
            "--claim",
            "HeiTang external source verification supports traceable evidence maps.",
        ],
    )

    assert build.exit_code == 0, build.output
    assert "knowledge_verification_foundations_only" in build.output
    assert conflict.exit_code == 2
    assert "--package cannot be combined" in conflict.output


def test_knowledge_verification_foundations_do_not_accept_later_gates(tmp_path):
    evidence = _evidence_file(tmp_path / "evidence.jsonl")
    verify_claims(
        tmp_path / "out",
        claim=["HeiTang external source verification supports traceable evidence maps."],
        evidence_file=[evidence],
    )
    report = _json(tmp_path / "out" / "claim_verification_report.json")
    validation = validate_knowledge_verification(tmp_path / "out")
    run_manifest = _json(tmp_path / "out" / "run_manifest.json")

    assert report["runtime_boundary"]["supplement_3_0_complete"] is False
    assert report["runtime_boundary"]["campaign_3_3_0_acceptance_gate_passed"] is False
    assert report["runtime_boundary"]["campaign_4_active"] is False
    assert report["runtime_boundary"]["campaign_5_active"] is False
    assert report["runtime_boundary"]["bridge_execution_accepted"] is False
    assert validation["supplement_3_0_complete"] is False
    assert validation["campaign_4_active"] is False
    assert validation["campaign_5_active"] is False
    assert run_manifest["next_business_item"] == "Campaign 3 Supplement 3.0 Acceptance Gate"
