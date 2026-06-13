import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.external_sources.link_import_entry import (
    build_external_link_import_entry_audit,
    validate_external_link_import_entry,
)


def _write_json(path: Path, payload: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2), encoding="utf-8")


def _fixture_runtime(root: Path) -> Path:
    runtime = root / "runtime"
    _write_json(
        runtime / "link_ingestion_report.json",
        {
            "status": "passed",
            "source_url": "https://example.com/article",
            "content_hash": "abc123",
            "backlink": "https://example.com/article",
        },
    )
    _write_json(
        runtime / "external_source_trace.json",
        {"source_trace_required": True, "sources": [{"source_id": "source_1"}]},
    )
    _write_json(
        runtime / "external_evidence_map.json",
        {"evidence_map_required": True, "evidence": [{"evidence_id": "evidence_1"}]},
    )
    (runtime / "progress_events.jsonl").write_text(
        json.dumps(
            {
                "stage": "external_link_import",
                "status": "passed",
                "timestamp": "2026-06-13T00:00:00Z",
                "message": "done",
                "artifact_path": "link_ingestion_report.json",
            }
        )
        + "\n",
        encoding="utf-8",
    )
    return runtime


def _fixture_ui(root: Path) -> Path:
    ui = root / "ui"
    files = {
        "lib/core_bridge/local_core_bridge.dart": "\n".join(
            [
                *[
                    f"'{action_id}': <String>['{command}'],"
                    for action_id, command in {
                        "ingest_external_link": "ingest-link",
                        "detect_platform_link": "detect-platform-link",
                        "preflight_platform_link": "preflight-platform-link",
                        "check_opencli_external_verification": "check-opencli-external-verification",
                        "verify_external_source": "verify-external-source",
                        "import_manual_evidence": "import-manual-evidence",
                        "build_external_source_unified_trace": "build-external-source-unified-trace",
                    }.items()
                ],
                "core_bridge_shell_executable_rejected",
                "core_bridge_shell_syntax_rejected",
                "external_link_import_url_rejected",
                "external_link_import_path_boundary_rejected",
                "external_link_import_timeout_rejected",
            ]
        ),
        "lib/core_bridge/local_core_bridge_runner_io.dart": "runInShell: false",
        "lib/external_sources/external_link_import_panel.dart": "\n".join(
            [
                "readability_state",
                "progress_events",
                "source_trace",
                "evidence_map",
                "backlink",
                "failure_reason",
                "repair_suggestion",
                "Browser OCR video transcription Knowledge Verification",
            ]
        ),
        "lib/main.dart": "page.id == 'import-parsing'\nExternalLinkImportPanel",
    }
    for relative, text in files.items():
        path = ui / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")
    return ui


def test_builds_and_validates_external_link_import_entry_audit(tmp_path):
    output = tmp_path / "audit"

    result = build_external_link_import_entry_audit(
        output,
        runtime_evidence=_fixture_runtime(tmp_path),
        ui_root=_fixture_ui(tmp_path),
    )

    assert result["status"] == "passed"
    assert result["integration_decision"] == "real_integration"
    assert result["decision_qualifier"] == "external_link_import_entry_bridge_allowlist_only"
    assert result["runtime_evidence"]["source_trace_count"] == 1
    assert result["runtime_evidence"]["evidence_count"] == 1
    assert result["runtime_evidence"]["progress_event_count"] == 1
    assert result["boundaries"]["campaign_5_bridge_accepted"] is False
    assert result["campaign_4_active"] is False
    assert result["campaign_5_active"] is False
    assert result["ui_industrial_workbench_complete"] is False
    assert result["local_core_bridge_complete"] is False
    assert result["bridge_execution_accepted"] is False
    assert result["external_link_import_ui_entry_only"] is True
    assert result["external_link_import_bridge_allowlist_only"] is True
    assert result["not_campaign_4_ui_redesign"] is True
    assert result["not_campaign_5_bridge_acceptance"] is True
    assert result["next_safe_action"].startswith(
        "STOP: Campaign 3 Supplement 3.0 next P0 subitem only"
    )
    security = json.loads(
        (output / "no_shell_security_report.json").read_text(encoding="utf-8")
    )
    assert security["status"] == "passed"
    assert security["run_in_shell"] is False
    assert security["arbitrary_shell_execution"] is False
    assert security["allowlist_only"] is True
    assert validate_external_link_import_entry(output)["status"] == "passed"


def test_validator_rejects_future_action_registration_and_campaign_5_claim(tmp_path):
    output = tmp_path / "audit"
    build_external_link_import_entry_audit(
        output,
        runtime_evidence=_fixture_runtime(tmp_path),
        ui_root=_fixture_ui(tmp_path),
    )
    allowlist_path = output / "core_bridge_allowlist_report.json"
    allowlist = json.loads(allowlist_path.read_text(encoding="utf-8"))
    allowlist["planned_not_active_actions"][0]["registered"] = True
    allowlist["campaign_5_bridge_acceptance"] = True
    allowlist_path.write_text(json.dumps(allowlist, indent=2), encoding="utf-8")

    validation = validate_external_link_import_entry(output)

    assert validation["status"] == "failed"
    assert "planned_action_must_not_be_registered:start_authenticated_browser_session" in validation[
        "boundary_errors"
    ]
    assert "campaign_5_bridge_acceptance_must_be_false" in validation["boundary_errors"]


def test_validator_rejects_campaign_4_or_5_completion_overclaims(tmp_path):
    output = tmp_path / "audit"
    build_external_link_import_entry_audit(
        output,
        runtime_evidence=_fixture_runtime(tmp_path),
        ui_root=_fixture_ui(tmp_path),
    )
    contract_path = output / "external_link_import_entry_contract.json"
    contract = json.loads(contract_path.read_text(encoding="utf-8"))
    contract["campaign_4_active"] = True
    contract["local_core_bridge_complete"] = True
    contract_path.write_text(json.dumps(contract, indent=2), encoding="utf-8")

    validation = validate_external_link_import_entry(output)

    assert validation["status"] == "failed"
    assert "contract:campaign_4_active_must_be_false" in validation["boundary_errors"]
    assert "contract:local_core_bridge_complete_must_be_false" in validation[
        "boundary_errors"
    ]


def test_cli_build_and_validate_external_link_import_entry_audit(tmp_path):
    runner = CliRunner()
    output = tmp_path / "audit"

    build = runner.invoke(
        app,
        [
            "build-external-link-import-entry-audit",
            "--runtime-evidence",
            str(_fixture_runtime(tmp_path)),
            "--ui-root",
            str(_fixture_ui(tmp_path)),
            "--output",
            str(output),
        ],
    )
    validate = runner.invoke(
        app,
        [
            "validate-external-link-import-entry",
            "--library",
            str(output),
            "--output",
            str(output),
        ],
    )

    assert build.exit_code == 0, build.output
    assert "status=passed" in build.output
    assert validate.exit_code == 0, validate.output
    assert "status=passed" in validate.output
