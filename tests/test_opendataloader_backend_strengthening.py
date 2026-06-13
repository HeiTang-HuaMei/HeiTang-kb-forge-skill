import json
import subprocess
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parser_backends import release_hardening
from heitang_kb_forge.parser_backends import opendataloader_adapter
from heitang_kb_forge.parser_backends.document_backend_contract import AdapterResult


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _install_fake_opendataloader_cli(monkeypatch):
    monkeypatch.setattr(
        opendataloader_adapter.shutil,
        "which",
        lambda name: name if name in {"opendataloader-pdf", "java"} else None,
    )
    monkeypatch.setattr(
        release_hardening.shutil,
        "which",
        lambda name: name if name in {"opendataloader-pdf", "java"} else None,
    )

    def fake_run(command, cwd, text, stdout, stderr, timeout):
        output_dir = Path(command[command.index("-o") + 1])
        source = Path(command[1])
        output_dir.mkdir(parents=True, exist_ok=True)
        (output_dir / f"{source.stem}.md").write_text(
            "# OpenDataLoader document\n\nNormalized Markdown text.",
            encoding="utf-8",
        )
        (output_dir / f"{source.stem}.json").write_text(
            json.dumps(
                {
                    "filename": source.name,
                    "pages": 1,
                    "kids": [
                        {"type": "title", "text": "OpenDataLoader document", "page number": 1, "order": 1},
                        {"type": "table", "text": "Table metadata", "page number": 1, "order": 2},
                        {"type": "image", "text": "Figure metadata", "page number": 1, "order": 3},
                    ],
                }
            ),
            encoding="utf-8",
        )
        return subprocess.CompletedProcess(command, 0, stdout="ok", stderr="")

    monkeypatch.setattr(opendataloader_adapter.subprocess, "run", fake_run)


def test_check_opendataloader_backend_writes_decision_report_when_dependency_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(opendataloader_adapter.shutil, "which", lambda name: None)
    monkeypatch.setattr(release_hardening.shutil, "which", lambda name: None)
    output = tmp_path / "check"

    result = CliRunner().invoke(app, ["check-opendataloader-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "opendataloader_integration_decision_report.json")
    assert payload["decision"] == "real_integration"
    assert payload["current_environment_status"] == "blocked_by_dependency"
    assert payload["dependency_status"] == "missing"
    assert payload["capabilities"]["pdf_conversion"] is True
    assert payload["capabilities"]["markdown_json_normalization"] is True
    assert payload["capabilities"]["hybrid_mode_in_default_smoke"] is False
    assert payload["capabilities"]["structured_skipped_when_missing"] is True
    assert payload["repair_suggestion"]
    remediation = _json(output / "opendataloader_dependency_remediation_report.json")
    assert remediation["adapter_name"] == "opendataloader"
    assert remediation["missing_dependencies"] == ["opendataloader-pdf", "Java 11+"]
    assert remediation["install_attempted"] is False
    assert remediation["post_install_check_result"] == "blocked_by_dependency"
    assert remediation["final_decision"] == "needs_strengthening"
    ui_note = _json(output / "opendataloader_ui_impact_note.json")
    assert ui_note["ui_status"] == "dependency_missing"
    assert ui_note["web_execution_enabled"] is False
    assert (output / "opendataloader_integration_decision_report.md").exists()
    assert (output / "opendataloader_dependency_remediation_report.md").exists()
    assert (output / "opendataloader_ui_impact_note.md").exists()


def test_smoke_opendataloader_backend_without_input_reports_missing_dependency(tmp_path, monkeypatch):
    monkeypatch.setattr(opendataloader_adapter.shutil, "which", lambda name: None)
    monkeypatch.setattr(release_hardening.shutil, "which", lambda name: None)
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-opendataloader-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "opendataloader_smoke_report.json")
    result_payload = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "blocked"
    assert payload["adapter_smoke_report"]["status"] == "skipped"
    assert result_payload["status"] == "skipped"
    assert {error["code"] for error in result_payload["errors"]} == {"optional_runtime_dependency_missing"}
    assert "no_supported_sources" not in payload["run"]["warnings"]
    assert payload["hybrid_mode_in_default_smoke"] is False
    remediation = _json(output / "opendataloader_dependency_remediation_report.json")
    assert remediation["post_install_smoke_result"] == "blocked"
    assert remediation["final_decision"] == "needs_strengthening"
    assert (output / "opendataloader_smoke_report.md").exists()
    assert (output / "opendataloader_integration_decision_report.json").exists()
    assert (output / "opendataloader_dependency_remediation_report.json").exists()
    assert (output / "opendataloader_ui_impact_note.md").exists()


def test_smoke_opendataloader_backend_passes_with_cli_fixture(tmp_path, monkeypatch):
    _install_fake_opendataloader_cli(monkeypatch)
    source = tmp_path / "document.pdf"
    source.write_bytes(b"%PDF fake fixture")
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-opendataloader-backend", "--input", str(source), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "opendataloader_smoke_report.json")
    adapter_result = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "pass"
    assert payload["adapter_smoke_report"]["status"] == "pass"
    assert adapter_result["status"] == "success"
    assert adapter_result["source_trace"][0]["page"] == 1
    assert payload["pdf_supported"] is True
    assert payload["markdown_json_normalization_supported"] is True
    assert payload["hybrid_mode_in_default_smoke"] is False
    remediation = _json(output / "opendataloader_dependency_remediation_report.json")
    assert remediation["post_install_smoke_result"] == "pass"
    assert remediation["final_decision"] == "real_integration"
    AdapterResult.model_validate(adapter_result)


def test_run_opendataloader_convert_normalizes_markdown_and_json_metadata(tmp_path, monkeypatch):
    _install_fake_opendataloader_cli(monkeypatch)
    input_dir = tmp_path / "input"
    output = tmp_path / "run"
    input_dir.mkdir()
    (input_dir / "document.pdf").write_bytes(b"%PDF fake fixture")
    (input_dir / "ignored.md").write_text("not supported", encoding="utf-8")

    result = CliRunner().invoke(app, ["run-opendataloader-convert", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "success"
    assert payload["source_count"] == 1
    record = payload["records"][0]
    assert record["source_type"] == "pdf"
    assert record["status"] == "success"
    assert "Normalized Markdown text" in record["text"]
    assert record["metadata"]["runtime_invoked"] is True
    assert record["metadata"]["layout_block_count"] == 3
    assert record["metadata"]["table_count"] == 1
    assert record["metadata"]["figure_count"] == 1
    assert record["metadata"]["reading_order_available"] is True
    adapter_result = record["adapter_result"]
    assert adapter_result["source_trace"][0]["command"] == "run-opendataloader-convert"
    AdapterResult.model_validate(adapter_result)
    report = _json(output / "opendataloader_convert_result.json")
    assert report["status"] == "success"
    assert report["markdown_json_normalization_reported"] is True
    decision = _json(output / "opendataloader_integration_decision_report.json")
    assert decision["run_status"] == "success"
    remediation = _json(output / "opendataloader_dependency_remediation_report.json")
    assert remediation["post_install_smoke_result"] == "success"
    assert remediation["final_decision"] == "real_integration"
    ui_note = _json(output / "opendataloader_ui_impact_note.json")
    assert ui_note["ui_status"] == "available"
    assert (output / "opendataloader_convert_result.md").exists()
