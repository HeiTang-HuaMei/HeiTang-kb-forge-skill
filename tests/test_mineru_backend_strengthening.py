import json
import subprocess
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parser_backends import mineru_adapter
from heitang_kb_forge.parser_backends.document_backend_contract import AdapterResult


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _install_fake_mineru_cli(monkeypatch):
    monkeypatch.setattr(mineru_adapter, "find_spec", lambda name: object())
    monkeypatch.setattr(mineru_adapter.shutil, "which", lambda name: "mineru")

    def fake_run(command, cwd, text, stdout, stderr, timeout):
        assert command[command.index("--backend") + 1] == "pipeline"
        assert command[command.index("--device") + 1] == "cpu"
        output_dir = Path(command[command.index("-o") + 1])
        source = Path(command[command.index("-p") + 1])
        output_dir.mkdir(parents=True, exist_ok=True)
        (output_dir / f"{source.stem}.md").write_text(
            "# MinerU document\n\nNormalized Markdown text.",
            encoding="utf-8",
        )
        (output_dir / f"{source.stem}_middle.json").write_text(
            json.dumps(
                {
                    "blocks": [
                        {"type": "title", "text": "MinerU document", "page": 1, "order": 1},
                        {"type": "table", "text": "Table metadata", "page": 1, "order": 2},
                        {"type": "figure", "text": "Figure metadata", "page": 1, "order": 3},
                        {"type": "formula", "text": "x=1", "page": 1, "order": 4},
                    ]
                }
            ),
            encoding="utf-8",
        )
        return subprocess.CompletedProcess(command, 0, stdout="ok", stderr="")

    monkeypatch.setattr(mineru_adapter.subprocess, "run", fake_run)


def test_mineru_check_requires_real_cli_even_when_package_is_importable(tmp_path, monkeypatch):
    monkeypatch.setattr(mineru_adapter, "find_spec", lambda name: object())
    monkeypatch.setattr(mineru_adapter.shutil, "which", lambda name: None)
    monkeypatch.setattr(mineru_adapter.sys, "executable", str(tmp_path / "python.exe"))

    available, reason = mineru_adapter.MinerUParserBackend().is_available()

    assert available is False
    assert "CLI" in reason


def test_check_mineru_backend_writes_decision_report_when_dependency_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(mineru_adapter, "find_spec", lambda name: None)
    monkeypatch.setattr(mineru_adapter.shutil, "which", lambda name: None)
    output = tmp_path / "check"

    result = CliRunner().invoke(app, ["check-mineru-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "mineru_integration_decision_report.json")
    assert payload["decision"] == "real_integration"
    assert payload["current_environment_status"] == "blocked_by_dependency"
    assert payload["dependency_status"] == "missing"
    assert payload["capabilities"]["pdf_parse"] is True
    assert payload["capabilities"]["layout_blocks"] is True
    assert payload["capabilities"]["markdown_json_normalization"] is True
    assert payload["capabilities"]["structured_skipped_when_missing"] is True
    assert payload["repair_suggestion"]
    assert (output / "mineru_integration_decision_report.md").exists()


def test_smoke_mineru_backend_without_input_reports_missing_dependency(tmp_path, monkeypatch):
    monkeypatch.setattr(mineru_adapter, "find_spec", lambda name: None)
    monkeypatch.setattr(mineru_adapter.shutil, "which", lambda name: None)
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-mineru-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "mineru_smoke_report.json")
    result_payload = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "blocked"
    assert payload["adapter_smoke_report"]["status"] == "skipped"
    assert result_payload["status"] == "skipped"
    assert {error["code"] for error in result_payload["errors"]} == {"optional_runtime_dependency_missing"}
    assert "no_supported_sources" not in payload["run"]["warnings"]
    assert (output / "mineru_smoke_report.md").exists()
    assert (output / "mineru_integration_decision_report.json").exists()


def test_smoke_mineru_backend_passes_with_runtime_fixture(tmp_path, monkeypatch):
    _install_fake_mineru_cli(monkeypatch)
    source = tmp_path / "document.pdf"
    source.write_bytes(b"%PDF fake fixture")
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-mineru-backend", "--input", str(source), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "mineru_smoke_report.json")
    adapter_result = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "pass"
    assert payload["adapter_smoke_report"]["status"] == "pass"
    assert adapter_result["status"] == "success"
    assert adapter_result["source_trace"][0]["page"] == 1
    assert payload["layout_blocks_supported"] is True
    assert payload["markdown_json_normalization_supported"] is True
    AdapterResult.model_validate(adapter_result)


def test_run_mineru_document_understanding_normalizes_markdown_and_json_metadata(tmp_path, monkeypatch):
    _install_fake_mineru_cli(monkeypatch)
    input_dir = tmp_path / "input"
    output = tmp_path / "run"
    input_dir.mkdir()
    (input_dir / "document.pdf").write_bytes(b"%PDF fake fixture")
    (input_dir / "scan.png").write_bytes(b"fake png fixture")
    (input_dir / "ignored.txt").write_text("not supported", encoding="utf-8")

    result = CliRunner().invoke(app, ["run-mineru-document-understanding", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "success"
    assert payload["source_count"] == 2
    assert {record["source_type"] for record in payload["records"]} == {"pdf", "png"}
    for record in payload["records"]:
        assert record["status"] == "success"
        assert "Normalized Markdown text" in record["text"]
        assert record["metadata"]["runtime_invoked"] is True
        assert record["metadata"]["layout_block_count"] == 4
        assert record["metadata"]["table_count"] == 1
        assert record["metadata"]["figure_count"] == 1
        assert record["metadata"]["formula_count"] == 1
        assert record["metadata"]["reading_order_available"] is True
        adapter_result = record["adapter_result"]
        assert adapter_result["status"] == "success"
        assert adapter_result["source_trace"][0]["command"] == "run-mineru-document-understanding"
        AdapterResult.model_validate(adapter_result)
    report = _json(output / "mineru_document_understanding_result.json")
    assert report["status"] == "success"
    assert report["layout_blocks_reported"] is True
    decision = _json(output / "mineru_integration_decision_report.json")
    assert decision["run_status"] == "success"
    assert (output / "mineru_document_understanding_result.md").exists()
