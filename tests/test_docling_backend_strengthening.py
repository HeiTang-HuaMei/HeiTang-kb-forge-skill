import json
import sys
import types

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parser_backends import docling_adapter
from heitang_kb_forge.parser_backends.document_backend_contract import AdapterResult


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _install_fake_docling(monkeypatch, text="# Parsed by Docling\n\nRuntime text."):
    class FakeDocument:
        def export_to_markdown(self):
            return text

    class FakeDocumentConverter:
        def convert(self, source):
            return types.SimpleNamespace(document=FakeDocument())

    docling = types.ModuleType("docling")
    docling.__path__ = []
    converter = types.ModuleType("docling.document_converter")
    converter.DocumentConverter = FakeDocumentConverter
    monkeypatch.setitem(sys.modules, "docling", docling)
    monkeypatch.setitem(sys.modules, "docling.document_converter", converter)
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: object())


def test_check_docling_backend_writes_decision_report_when_dependency_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: None)
    output = tmp_path / "check"

    result = CliRunner().invoke(app, ["check-docling-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "docling_integration_decision_report.json")
    assert payload["decision"] == "real_integration"
    assert payload["current_environment_status"] == "blocked_by_dependency"
    assert payload["dependency_status"] == "missing"
    assert payload["capabilities"]["document_conversion"] is True
    assert payload["capabilities"]["markdown_normalization"] is True
    assert payload["capabilities"]["structured_skipped_when_missing"] is True
    assert payload["repair_suggestion"]
    assert (output / "docling_integration_decision_report.md").exists()


def test_smoke_docling_backend_without_input_reports_missing_dependency(tmp_path, monkeypatch):
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: None)
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-docling-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "docling_smoke_report.json")
    result_payload = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "blocked"
    assert payload["adapter_smoke_report"]["status"] == "skipped"
    assert result_payload["status"] == "skipped"
    assert {error["code"] for error in result_payload["errors"]} == {"optional_runtime_dependency_missing"}
    assert "no_supported_sources" not in payload["run"]["warnings"]
    assert (output / "docling_smoke_report.md").exists()
    assert (output / "docling_integration_decision_report.json").exists()


def test_smoke_docling_backend_passes_with_runtime_fixture(tmp_path, monkeypatch):
    _install_fake_docling(monkeypatch)
    source = tmp_path / "document.md"
    source.write_text("# input", encoding="utf-8")
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-docling-backend", "--input", str(source), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "docling_smoke_report.json")
    adapter_result = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "pass"
    assert payload["adapter_smoke_report"]["status"] == "pass"
    assert adapter_result["status"] == "success"
    assert payload["document_conversion_supported"] is True
    assert payload["markdown_normalization_supported"] is True
    AdapterResult.model_validate(adapter_result)


def test_run_docling_convert_writes_named_result_and_decision_report(tmp_path, monkeypatch):
    _install_fake_docling(monkeypatch)
    input_dir = tmp_path / "input"
    output = tmp_path / "run"
    input_dir.mkdir()
    (input_dir / "document.md").write_text("# input", encoding="utf-8")
    (input_dir / "ignored.bin").write_bytes(b"ignored")

    result = CliRunner().invoke(app, ["run-docling-convert", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "success"
    assert payload["source_count"] == 1
    record = payload["records"][0]
    assert "Parsed by Docling" in record["text"]
    assert record["metadata"]["runtime_invoked"] is True
    AdapterResult.model_validate(record["adapter_result"])
    report = _json(output / "docling_convert_result.json")
    assert report["status"] == "success"
    assert report["document_conversion_reported"] is True
    decision = _json(output / "docling_integration_decision_report.json")
    assert decision["run_status"] == "success"
    assert (output / "docling_convert_result.md").exists()
