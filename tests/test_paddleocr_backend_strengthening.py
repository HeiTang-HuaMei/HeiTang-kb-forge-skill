import json
import sys
import types
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parser_backends import paddleocr_adapter
from heitang_kb_forge.parser_backends.document_backend_contract import AdapterResult


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _install_fake_paddleocr(monkeypatch, score=0.93):
    class FakePaddleOCR:
        def __init__(self, **kwargs):
            pass

        def ocr(self, source, cls=True):
            suffix = Path(source).suffix.lower().lstrip(".")
            return [[[None, (f"PaddleOCR {suffix} text", score)]]]

    paddleocr = types.ModuleType("paddleocr")
    paddleocr.PaddleOCR = FakePaddleOCR
    monkeypatch.setitem(sys.modules, "paddleocr", paddleocr)
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: object())


def test_check_paddleocr_backend_writes_decision_report_when_dependency_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: None)
    output = tmp_path / "check"

    result = CliRunner().invoke(app, ["check-paddleocr-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "paddleocr_integration_decision_report.json")
    assert payload["decision"] == "real_integration"
    assert payload["current_environment_status"] == "blocked_by_dependency"
    assert payload["dependency_status"] == "missing"
    assert payload["capabilities"]["image_ocr"] is True
    assert payload["capabilities"]["scanned_pdf_page_ocr"] is True
    assert payload["capabilities"]["structured_skipped_when_missing"] is True
    assert payload["repair_suggestion"]
    assert (output / "paddleocr_integration_decision_report.md").exists()


def test_smoke_paddleocr_backend_writes_structured_skipped_report_when_dependency_missing(tmp_path, monkeypatch):
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: None)
    source = tmp_path / "scan.png"
    source.write_bytes(b"fake png fixture")
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-paddleocr-backend", "--input", str(source), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "paddleocr_smoke_report.json")
    result_payload = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "blocked"
    assert payload["adapter_smoke_report"]["status"] == "skipped"
    assert result_payload["status"] == "skipped"
    assert result_payload["runtime_status"] == "skipped"
    assert {error["code"] for error in result_payload["errors"]} == {"optional_runtime_dependency_missing"}
    assert result_payload["fallback_result"] == "builtin_available"
    assert result_payload["repair_suggestion"]
    assert (output / "paddleocr_smoke_report.md").exists()
    assert (output / "paddleocr_integration_decision_report.json").exists()


def test_smoke_paddleocr_backend_without_input_still_reports_missing_dependency(tmp_path, monkeypatch):
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: None)
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-paddleocr-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "paddleocr_smoke_report.json")
    result_payload = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "blocked"
    assert result_payload["status"] == "skipped"
    assert {error["code"] for error in result_payload["errors"]} == {"optional_runtime_dependency_missing"}
    assert "no_supported_sources" not in payload["run"]["warnings"]


def test_smoke_paddleocr_backend_passes_with_runtime_fixture(tmp_path, monkeypatch):
    _install_fake_paddleocr(monkeypatch, score=0.88)
    source = tmp_path / "scan.png"
    source.write_bytes(b"fake png fixture")
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-paddleocr-backend", "--input", str(source), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "paddleocr_smoke_report.json")
    adapter_result = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "pass"
    assert payload["adapter_smoke_report"]["status"] == "pass"
    assert adapter_result["status"] == "success"
    assert adapter_result["confidence"] == 0.88
    assert adapter_result["source_trace"][0]["page"] == 1
    AdapterResult.model_validate(adapter_result)


def test_run_paddleocr_ocr_supports_image_and_pdf_with_confidence_and_source_trace(tmp_path, monkeypatch):
    _install_fake_paddleocr(monkeypatch, score=0.93)
    input_dir = tmp_path / "input"
    output = tmp_path / "run"
    input_dir.mkdir()
    (input_dir / "scan.png").write_bytes(b"fake png fixture")
    (input_dir / "scan.pdf").write_bytes(b"%PDF fake fixture")
    (input_dir / "ignored.txt").write_text("not an OCR source", encoding="utf-8")

    result = CliRunner().invoke(app, ["run-paddleocr-ocr", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    records = payload["records"]
    assert payload["status"] == "success"
    assert payload["source_count"] == 2
    assert {record["source_type"] for record in records} == {"pdf", "png"}
    for record in records:
        assert record["status"] == "success"
        assert record["confidence"] == 0.93
        assert record["metadata"]["runtime_invoked"] is True
        assert record["metadata"]["page"] == 1
        adapter_result = record["adapter_result"]
        assert adapter_result["status"] == "success"
        assert adapter_result["source_trace"][0]["page"] == 1
        assert adapter_result["source_trace"][0]["command"] == "run-paddleocr-ocr"
        AdapterResult.model_validate(adapter_result)
    report = _json(output / "paddleocr_ocr_result.json")
    assert report["status"] == "success"
    assert report["confidence_reported"] is True
    assert report["source_page_trace_reported"] is True
    decision = _json(output / "paddleocr_integration_decision_report.json")
    assert decision["run_status"] == "success"
    assert (output / "paddleocr_ocr_result.md").exists()
