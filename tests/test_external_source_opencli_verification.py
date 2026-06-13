import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.external_sources import (
    check_opencli_external_verification,
    validate_opencli_external_verification,
    verify_external_source_with_opencli,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _opencli_runner(command: list[str], timeout_seconds: int) -> dict:
    assert timeout_seconds in {15, 30}
    if command[-1] == "--version":
        return {"returncode": 0, "stdout": "1.8.3\n", "stderr": ""}
    assert command[1:3] == ["npm", "search"]
    assert command[-2:] == ["-f", "json"]
    return {
        "returncode": 0,
        "stdout": json.dumps(
            [
                {
                    "rank": 1,
                    "name": "@jackwener/opencli",
                    "version": "1.8.3",
                    "description": "Make any website or Electron App your CLI. AI-powered.",
                    "weeklyDownloads": 11142,
                    "license": "Apache-2.0",
                    "publisher": "jackwener",
                    "updated": "2026-06-12",
                    "url": "https://www.npmjs.com/package/@jackwener/opencli",
                }
            ]
        ),
        "stderr": "",
    }


def test_opencli_external_verification_builds_candidates_confidence_trace_and_evidence(tmp_path):
    fake_bin = tmp_path / "opencli.cmd"
    fake_bin.write_text("@echo off\n", encoding="utf-8")

    report = verify_external_source_with_opencli(
        tmp_path,
        query="opencli",
        claim="OpenCLI can expose websites as structured CLI adapters",
        opencli_bin=fake_bin,
        provider="npm",
        runner=_opencli_runner,
    )
    validation = validate_opencli_external_verification(tmp_path)

    assert report["status"] == "passed"
    assert report["verification_status"] in {"verified", "partially_verified"}
    assert report["decision_qualifier"] == "opencli_external_search_verification_only"
    assert report["runtime_boundary"]["opencli_external_search_verification_implemented"] is True
    assert report["runtime_boundary"]["manual_evidence_processing_implemented"] is False
    assert report["runtime_boundary"]["authenticated_browser_runtime_integrated"] is False
    assert report["runtime_boundary"]["ui_workflow_accepted"] is False
    assert report["runtime_boundary"]["bridge_execution_accepted"] is False
    assert report["safety_boundary"]["no_browser_session_used"] is True
    assert report["safety_boundary"]["no_cookie_import"] is True
    assert report["safety_boundary"]["no_arbitrary_shell_execution"] is True

    candidates = _jsonl(tmp_path / "external_search_candidates.jsonl")
    confidence = _json(tmp_path / "external_source_confidence.json")
    trace = _json(tmp_path / "external_source_trace.json")
    evidence = _json(tmp_path / "external_evidence_map.json")

    assert len(candidates) == 1
    assert candidates[0]["source_url"] == "https://www.npmjs.com/package/@jackwener/opencli"
    assert candidates[0]["cookie_or_session_material_present"] is False
    assert confidence["candidate_count"] == 1
    assert trace["source_trace_required"] is True
    assert trace["source_count"] == 1
    assert evidence["evidence_map_required"] is True
    assert evidence["evidence_count"] == 1
    assert validation["status"] == "passed"
    assert validation["manual_evidence_processing_implemented"] is False


def test_opencli_external_verification_degrades_gracefully_on_timeout(tmp_path):
    fake_bin = tmp_path / "opencli.cmd"
    fake_bin.write_text("@echo off\n", encoding="utf-8")

    def timeout_runner(command: list[str], _timeout_seconds: int) -> dict:
        if command[-1] == "--version":
            return {"returncode": 0, "stdout": "1.8.3\n", "stderr": ""}
        return {"returncode": 124, "stdout": "", "stderr": "Connect Timeout Error"}

    report = verify_external_source_with_opencli(
        tmp_path,
        query="opencli",
        opencli_bin=fake_bin,
        runner=timeout_runner,
    )
    validation = validate_opencli_external_verification(tmp_path)

    assert report["status"] == "degraded"
    assert report["graceful_degradation"] is True
    assert report["error_code"] == "network_timeout"
    assert report["candidate_count"] == 0
    assert _jsonl(tmp_path / "external_search_candidates.jsonl") == []
    assert validation["status"] == "passed"


def test_opencli_validation_rejects_manual_or_ui_overclaim(tmp_path):
    fake_bin = tmp_path / "opencli.cmd"
    fake_bin.write_text("@echo off\n", encoding="utf-8")
    verify_external_source_with_opencli(
        tmp_path,
        query="opencli",
        opencli_bin=fake_bin,
        runner=_opencli_runner,
    )

    report_path = tmp_path / "external_verification_report.json"
    report = _json(report_path)
    report["runtime_boundary"]["manual_evidence_processing_implemented"] = True
    report["runtime_boundary"]["ui_workflow_accepted"] = True
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    validation = validate_opencli_external_verification(tmp_path)

    assert validation["status"] == "failed"
    assert "manual_evidence_processing_implemented_must_be_false" in validation["boundary_errors"]
    assert "ui_workflow_accepted_must_be_false" in validation["boundary_errors"]


def test_opencli_external_verification_cli_writes_structured_outputs(tmp_path):
    runner = CliRunner()
    check_output = tmp_path / "check"
    verify_output = tmp_path / "verify"
    validation_output = tmp_path / "validation"

    check = runner.invoke(app, ["check-opencli-external-verification", "--output", str(check_output)])
    verify = runner.invoke(
        app,
        [
            "verify-external-source",
            "opencli",
            "--output",
            str(verify_output),
            "--no-network",
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-opencli-external-verification",
            "--library",
            str(verify_output),
            "--output",
            str(validation_output),
        ],
    )

    assert check.exit_code == 0, check.output
    assert verify.exit_code == 0, verify.output
    assert validate.exit_code == 0, validate.output
    assert _json(check_output / "opencli_availability_report.json")["runtime_status"] in {
        "available",
        "unavailable",
    }
    assert _json(verify_output / "external_verification_report.json")["status"] == "degraded"
    assert _json(validation_output / "opencli_external_verification_validation_report.json")[
        "status"
    ] == "passed"
