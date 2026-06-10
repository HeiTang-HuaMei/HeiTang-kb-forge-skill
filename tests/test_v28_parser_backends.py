import json
import os
import sys
import types
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.parser_backends import docling_adapter, paddleocr_adapter, unstructured_adapter


ROOT = Path(__file__).resolve().parents[1]
PARSER_RUNTIME_ACCEPTANCE_REPORT = ROOT / "docs" / "audits" / "parser_runtime_acceptance" / "parser_runtime_acceptance_report.json"
P21_AUDIT_DIR = ROOT / "docs" / "audits" / "p2_1_parser_ocr_backends"

STANDARD_FILES = {
    "chunks.jsonl",
    "cards.jsonl",
    "qa_pairs.jsonl",
    "glossary.jsonl",
    "manifest.json",
    "ingest_report.md",
    "quality_report.json",
}

PARSER_FILES = {
    "parser_backend_result.json",
    "parser_backend_output.md",
    "parser_backend_output.json",
    "parse_quality_report.json",
    "parse_quality_report.md",
    "ocr_risk_report.json",
    "high_risk_pages.jsonl",
    "high_risk_parse_pages.jsonl",
    "high_risk_chunks.jsonl",
    "manual_review_queue.jsonl",
    "kb_trust_status.json",
    "trusted_kb_gate.json",
    "knowledge_reliability_report.json",
}


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def test_parser_backend_list_reports_builtin_docling_and_marker():
    result = CliRunner().invoke(app, ["parser-backend-list"])

    assert result.exit_code == 0, result.output
    assert "builtin: available" in result.output
    assert "docling:" in result.output
    assert "marker:" in result.output
    assert "paddleocr:" in result.output
    assert "unstructured:" in result.output


def test_backend_registry_exposes_runtime_supported_extensions():
    from heitang_kb_forge.parser_backends import list_backends

    rows = {row["name"]: row for row in list_backends()}

    assert ".pdf" in rows["docling"]["supported_extensions"]
    assert ".md" in rows["unstructured"]["supported_extensions"]
    assert ".txt" in rows["unstructured"]["supported_extensions"]
    assert ".png" in rows["paddleocr"]["supported_extensions"]
    assert rows["marker"]["supported_extensions"] == [".pdf"]


def test_parse_with_backend_builtin_writes_normalized_outputs(tmp_path):
    source = tmp_path / "input.md"
    output = tmp_path / "parse"
    source.write_text("# Title\n\nParser backend fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "builtin"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "success"
    assert payload["backend_name"] == "builtin"
    assert payload["records"][0]["status"] == "success"
    assert "Parser backend fixture" in payload["records"][0]["text"]
    assert (output / "parser_backend_output.md").exists()
    assert (output / "parser_backend_output.json").exists()


def test_parse_with_backend_unsupported_only_returns_warning(tmp_path):
    source = tmp_path / "input.bin"
    output = tmp_path / "parse"
    source.write_bytes(b"unsupported")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "builtin"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "warning"
    assert payload["source_count"] == 0
    assert "no_supported_sources" in payload["warnings"]


def test_optional_docling_backend_is_unavailable_without_crashing(tmp_path, monkeypatch):
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: None)
    source = tmp_path / "input.md"
    output = tmp_path / "docling"
    source.write_text("Docling optional fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "docling"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "unavailable"
    assert payload["backend_name"] == "docling"
    assert payload["records"][0]["status"] in {"unavailable", "disabled"}


def test_docling_backend_invokes_installed_runtime(tmp_path, monkeypatch):
    calls = []

    class FakeDocument:
        def export_to_markdown(self):
            return "# Parsed by Docling\n\nRuntime text."

    class FakeDocumentConverter:
        def convert(self, source):
            calls.append(source)
            return types.SimpleNamespace(document=FakeDocument())

    docling = types.ModuleType("docling")
    docling.__path__ = []
    converter = types.ModuleType("docling.document_converter")
    converter.DocumentConverter = FakeDocumentConverter
    monkeypatch.setitem(sys.modules, "docling", docling)
    monkeypatch.setitem(sys.modules, "docling.document_converter", converter)
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: object())

    source = tmp_path / "input.pdf"
    output = tmp_path / "docling"
    source.write_bytes(b"%PDF fake fixture")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "docling"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "success"
    assert calls == [str(source)]
    record = payload["records"][0]
    assert record["metadata"]["runtime_invoked"] is True
    assert "Parsed by Docling" in record["text"]


def test_unstructured_backend_invokes_partition_runtime(tmp_path, monkeypatch):
    calls = []

    def fake_partition(filename):
        calls.append(filename)
        return [types.SimpleNamespace(text="Unstructured element one."), types.SimpleNamespace(text="Element two.")]

    unstructured = types.ModuleType("unstructured")
    unstructured.__path__ = []
    partition_pkg = types.ModuleType("unstructured.partition")
    partition_pkg.__path__ = []
    auto = types.ModuleType("unstructured.partition.auto")
    auto.partition = fake_partition
    monkeypatch.setitem(sys.modules, "unstructured", unstructured)
    monkeypatch.setitem(sys.modules, "unstructured.partition", partition_pkg)
    monkeypatch.setitem(sys.modules, "unstructured.partition.auto", auto)
    monkeypatch.setattr(unstructured_adapter, "find_spec", lambda name: object())

    source = tmp_path / "input.md"
    output = tmp_path / "unstructured"
    source.write_text("fake markdown fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "unstructured"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "success"
    assert calls == [str(source)]
    record = payload["records"][0]
    assert record["metadata"]["runtime_invoked"] is True
    assert record["metadata"]["element_count"] == 2
    assert "Unstructured element one" in record["text"]


def test_paddleocr_backend_invokes_ocr_runtime(tmp_path, monkeypatch):
    calls = []
    monkeypatch.delenv("PADDLE_PDX_CACHE_HOME", raising=False)
    monkeypatch.delenv("MODELSCOPE_CACHE", raising=False)
    monkeypatch.delenv("HF_HOME", raising=False)
    monkeypatch.delenv("HF_HUB_CACHE", raising=False)
    monkeypatch.delenv("PADDLE_HOME", raising=False)

    class FakePaddleOCR:
        def __init__(self, **kwargs):
            calls.append(("init", kwargs))

        def ocr(self, source, cls=True):
            calls.append(("ocr", source, cls))
            return [[[None, ("Paddle OCR text", 0.96)]]]

    paddleocr = types.ModuleType("paddleocr")
    paddleocr.PaddleOCR = FakePaddleOCR
    monkeypatch.setitem(sys.modules, "paddleocr", paddleocr)
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: object())

    source = tmp_path / "scan.png"
    output = tmp_path / "paddleocr"
    source.write_bytes(b"fake png fixture")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "paddleocr"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "success"
    assert calls[0][0] == "init"
    assert calls[0][1]["device"] == "cpu"
    assert calls[0][1]["enable_mkldnn"] is False
    assert calls[0][1]["lang"] == "ch"
    assert calls[0][1]["use_doc_orientation_classify"] is False
    assert calls[0][1]["use_doc_unwarping"] is False
    assert calls[0][1]["use_textline_orientation"] is False
    assert calls[1] == ("ocr", str(source), True)
    record = payload["records"][0]
    assert record["metadata"]["runtime_invoked"] is True
    assert record["confidence"] == 0.96
    assert record["text"] == "Paddle OCR text"
    assert ".heitang_cache" in os.environ["PADDLE_PDX_CACHE_HOME"]
    assert ".heitang_cache" in os.environ["MODELSCOPE_CACHE"]
    assert ".heitang_cache" in os.environ["HF_HOME"]
    assert ".heitang_cache" in os.environ["HF_HUB_CACHE"]
    assert ".heitang_cache" in os.environ["PADDLE_HOME"]


def test_paddleocr_backend_reads_callable_json_runtime_result(tmp_path, monkeypatch):
    class FakePaddleOCRResult:
        def json(self):
            return {"rec_texts": ["Callable JSON OCR text"], "rec_scores": [0.91]}

    class FakePaddleOCR:
        def __init__(self, **kwargs):
            pass

        def predict(self, input):
            return [FakePaddleOCRResult()]

    paddleocr = types.ModuleType("paddleocr")
    paddleocr.PaddleOCR = FakePaddleOCR
    monkeypatch.setitem(sys.modules, "paddleocr", paddleocr)
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: object())

    source = tmp_path / "scan.png"
    output = tmp_path / "paddleocr"
    source.write_bytes(b"fake png fixture")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "paddleocr"])

    assert result.exit_code == 0, result.output
    record = _json(output / "parser_backend_result.json")["records"][0]
    assert record["status"] == "success"
    assert record["text"] == "Callable JSON OCR text"
    assert record["confidence"] == 0.91


def test_docling_runtime_exception_has_stable_failure_metadata(tmp_path, monkeypatch):
    class FakeDocumentConverter:
        def convert(self, source):
            raise RuntimeError("fixture runtime failure")

    docling = types.ModuleType("docling")
    docling.__path__ = []
    converter = types.ModuleType("docling.document_converter")
    converter.DocumentConverter = FakeDocumentConverter
    monkeypatch.setitem(sys.modules, "docling", docling)
    monkeypatch.setitem(sys.modules, "docling.document_converter", converter)
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: object())

    source = tmp_path / "input.md"
    output = tmp_path / "docling_failure"
    source.write_text("Docling runtime exception fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "docling"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    record = payload["records"][0]
    assert payload["status"] == "warning"
    assert record["status"] == "failed"
    assert record["metadata"]["error_code"] == "backend_runtime_exception"
    assert record["metadata"]["fallback_result"] == "builtin_available"
    assert record["metadata"]["repair_suggestion"]
    assert record["metadata"]["audit_trace"]


def test_docling_empty_result_has_stable_failure_metadata(tmp_path, monkeypatch):
    class FakeDocument:
        def export_to_markdown(self):
            return ""

        def export_to_text(self):
            return ""

        text = ""

        def __str__(self):
            return ""

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

    source = tmp_path / "input.md"
    output = tmp_path / "docling_empty"
    source.write_text("", encoding="utf-8")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "docling"])

    assert result.exit_code == 0, result.output
    record = _json(output / "parser_backend_result.json")["records"][0]
    assert record["status"] == "empty"
    assert record["metadata"]["error_code"] == "empty_parse_result"
    assert record["metadata"]["fallback_result"] == "builtin_available"


def test_parser_runtime_acceptance_reports_dependency_gated_blocked_status(tmp_path, monkeypatch):
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: None)
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: None)
    monkeypatch.setattr(unstructured_adapter, "find_spec", lambda name: None)
    input_dir = tmp_path / "input"
    output = tmp_path / "acceptance"
    input_dir.mkdir()
    (input_dir / "input.pdf").write_bytes(b"%PDF fake fixture")
    (input_dir / "input.md").write_text("fake markdown fixture", encoding="utf-8")
    (input_dir / "scan.png").write_bytes(b"fake png fixture")

    result = CliRunner().invoke(app, ["parser-runtime-acceptance", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_runtime_acceptance_report.json")
    assert payload["status"] == "blocked"
    assert payload["live_runtime_completion_proven"] is False
    assert payload["blocked_count"] == 3
    assert payload["default_core_parser_changed"] is False
    assert payload["external_runtime_bundled"] is False
    assert payload["provider_network_api_required"] is False
    for entry in payload["entries"]:
        assert entry["status"] == "blocked"
        assert entry["blocked_reason"] == "optional_runtime_dependency_missing"
        assert entry["dependency_available"] is False
        assert entry["runtime_invoked"] is False
    assert (output / "parser_runtime_acceptance_report.md").exists()


def test_parser_backend_registry_matrix_inspect_and_smoke_cli_write_stable_outputs(tmp_path):
    registry_output = tmp_path / "registry"
    matrix_output = tmp_path / "matrix"
    inspect_output = tmp_path / "inspect"
    smoke_output = tmp_path / "smoke"

    registry = CliRunner().invoke(app, ["parser-backend-registry", "--output", str(registry_output)])
    matrix = CliRunner().invoke(app, ["parser-backend-matrix", "--output", str(matrix_output)])
    inspect = CliRunner().invoke(app, ["parser-backend-inspect", "builtin", "--output", str(inspect_output)])
    smoke = CliRunner().invoke(app, ["parser-backend-smoke", "--backend", "builtin", "--output", str(smoke_output)])

    assert registry.exit_code == 0, registry.output
    assert matrix.exit_code == 0, matrix.output
    assert inspect.exit_code == 0, inspect.output
    assert smoke.exit_code == 0, smoke.output
    assert _json(registry_output / "parser_backend_registry.json")["schema_version"] == "p2.1.parser_backend_registry.v1"
    matrix_payload = _json(matrix_output / "parser_backend_matrix.json")
    assert matrix_payload["schema_version"] == "p2.1.parser_backend_matrix.v1"
    assert {backend["backend_id"] for backend in matrix_payload["backends"]} == {"builtin", "docling", "paddleocr", "unstructured"}
    assert all(backend["static_workbench_executable"] is False for backend in matrix_payload["backends"])
    assert _json(inspect_output / "parser_backend_inspect_builtin.json")["status"] == "available"
    assert _json(smoke_output / "parser_backend_smoke_builtin.json")["status"] == "pass"
    for path in [
        registry_output / "parser_backend_registry.md",
        matrix_output / "parser_backend_matrix.md",
        inspect_output / "parser_backend_inspect_builtin.md",
        smoke_output / "parser_backend_smoke_builtin.md",
    ]:
        assert path.exists()


def test_parser_backend_inspect_missing_optional_dependency_reports_blocked(tmp_path, monkeypatch):
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: None)
    output = tmp_path / "inspect_docling"

    result = CliRunner().invoke(app, ["parser-backend-inspect", "docling", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_inspect_docling.json")
    assert payload["status"] == "blocked_by_dependency"
    assert payload["error_code"] == "optional_runtime_dependency_missing"
    assert payload["fallback_result"] == "builtin_available"
    assert payload["repair_suggestion"]


def test_parser_backend_inspect_invalid_backend_id_has_stable_failure(tmp_path):
    output = tmp_path / "inspect_invalid"

    result = CliRunner().invoke(app, ["parser-backend-inspect", "not-a-backend", "--output", str(output)])

    assert result.exit_code == 1
    payload = _json(output / "parser_backend_inspect_not-a-backend.json")
    assert payload["status"] == "fail"
    assert payload["error_code"] == "invalid_backend_id"
    assert payload["fallback_result"] == "builtin_available"
    assert payload["workbench_visible_status"] == "not_ready"


def test_parser_backend_smoke_unsupported_file_type_reports_fallback(tmp_path):
    source = tmp_path / "input.bin"
    output = tmp_path / "unsupported_smoke"
    source.write_bytes(b"unsupported")

    result = CliRunner().invoke(app, ["parser-backend-smoke", "--backend", "builtin", "--input", str(source), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_smoke_builtin.json")
    assert payload["status"] == "warning"
    assert payload["run"]["error_code"] == "unsupported_file_type"
    assert payload["run"]["fallback_result"] == "builtin_available_when_supported"
    assert payload["run"]["repair_suggestion"]


def test_parser_backend_release_evidence_cli_writes_complete_system(tmp_path):
    output = tmp_path / "release_evidence"

    result = CliRunner().invoke(app, ["parser-backend-release-evidence", "--output", str(output)])

    assert result.exit_code == 0, result.output
    required = [
        "p2_1_baseline_lock_report.json",
        "p2_1_baseline_lock_report.md",
        "p2_1_acceptance_report.json",
        "p2_1_acceptance_report.md",
        "backend_status_schema.json",
        "parser_backend_matrix.json",
        "parser_backend_matrix.md",
        "parser_backend_status_report.md",
        "backend_capability_boundaries.md",
        "live_acceptance_replay.md",
        "failure_mode_report.json",
        "failure_mode_report.md",
        "fresh_clone_reproducibility_report.json",
        "fresh_clone_reproducibility_report.md",
        "evidence_index.json",
        "evidence_index.md",
    ]
    for name in required:
        assert (output / name).exists(), name
    schema = _json(output / "backend_status_schema.json")
    failure = _json(output / "failure_mode_report.json")
    matrix = _json(output / "parser_backend_matrix.json")
    assert schema["schema_version"] == "p2.1.backend_status.schema.v1"
    assert failure["status"] == "pass"
    assert failure["fallback_preserved"] is True
    assert {case["case_id"] for case in failure["cases"]} >= {
        "missing_backend_dependency",
        "invalid_backend_id",
        "unsupported_file_type",
        "runtime_exception",
        "empty_result",
    }
    assert matrix["known_limitation_report_path"].endswith("backend_capability_boundaries.md")


def test_parser_runtime_acceptance_reports_dependency_missing_before_source_shape(tmp_path, monkeypatch):
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: None)
    source = tmp_path / "input.md"
    output = tmp_path / "acceptance"
    source.write_text("No PaddleOCR-supported source here.", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "parser-runtime-acceptance",
            "--input",
            str(source),
            "--output",
            str(output),
            "--backends",
            "paddleocr",
        ],
    )

    assert result.exit_code == 0, result.output
    entry = _json(output / "parser_runtime_acceptance_report.json")["entries"][0]
    assert entry["status"] == "blocked"
    assert entry["blocked_reason"] == "optional_runtime_dependency_missing"
    assert entry["source_count"] == 0


def test_parser_runtime_acceptance_passes_when_all_runtime_backends_invoke(tmp_path, monkeypatch):
    class FakeDocument:
        def export_to_markdown(self):
            return "Docling runtime acceptance text."

    class FakeDocumentConverter:
        def convert(self, source):
            return types.SimpleNamespace(document=FakeDocument())

    def fake_partition(filename):
        return [types.SimpleNamespace(text=f"Unstructured runtime text for {filename}.")]

    class FakePaddleOCR:
        def __init__(self, **kwargs):
            pass

        def ocr(self, source, cls=True):
            return [[[None, (f"PaddleOCR runtime text for {source}", 0.97)]]]

    docling = types.ModuleType("docling")
    docling.__path__ = []
    converter = types.ModuleType("docling.document_converter")
    converter.DocumentConverter = FakeDocumentConverter
    unstructured = types.ModuleType("unstructured")
    unstructured.__path__ = []
    partition_pkg = types.ModuleType("unstructured.partition")
    partition_pkg.__path__ = []
    auto = types.ModuleType("unstructured.partition.auto")
    auto.partition = fake_partition
    paddleocr = types.ModuleType("paddleocr")
    paddleocr.PaddleOCR = FakePaddleOCR
    monkeypatch.setitem(sys.modules, "docling", docling)
    monkeypatch.setitem(sys.modules, "docling.document_converter", converter)
    monkeypatch.setitem(sys.modules, "unstructured", unstructured)
    monkeypatch.setitem(sys.modules, "unstructured.partition", partition_pkg)
    monkeypatch.setitem(sys.modules, "unstructured.partition.auto", auto)
    monkeypatch.setitem(sys.modules, "paddleocr", paddleocr)
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: object())
    monkeypatch.setattr(paddleocr_adapter, "find_spec", lambda name: object())
    monkeypatch.setattr(unstructured_adapter, "find_spec", lambda name: object())

    input_dir = tmp_path / "input"
    output = tmp_path / "acceptance"
    input_dir.mkdir()
    (input_dir / "input.pdf").write_bytes(b"%PDF fake fixture")
    (input_dir / "input.md").write_text("fake markdown fixture", encoding="utf-8")
    (input_dir / "scan.png").write_bytes(b"fake png fixture")

    result = CliRunner().invoke(app, ["parser-runtime-acceptance", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_runtime_acceptance_report.json")
    assert payload["status"] == "pass"
    assert payload["live_runtime_completion_proven"] is True
    assert payload["pass_count"] == 3
    assert payload["blocked_count"] == 0
    assert {entry["backend_name"] for entry in payload["entries"]} == {"docling", "paddleocr", "unstructured"}
    for entry in payload["entries"]:
        assert entry["status"] == "pass"
        assert entry["dependency_available"] is True
        assert entry["runtime_invoked"] is True
        assert entry["runtime_invoked_count"] == entry["source_count"]
        assert entry["text_length"] > 0


def test_committed_parser_runtime_acceptance_report_proves_optional_runtime_backends():
    payload = _json(PARSER_RUNTIME_ACCEPTANCE_REPORT)

    assert payload["status"] == "pass"
    assert payload["live_runtime_completion_proven"] is True
    assert payload["required_backends"] == ["docling", "paddleocr", "unstructured"]
    assert payload["default_core_parser_changed"] is False
    assert payload["external_runtime_bundled"] is False
    assert payload["provider_network_api_required"] is False
    entries = {entry["backend_name"]: entry for entry in payload["entries"]}
    assert set(entries) == {"docling", "paddleocr", "unstructured"}
    for entry in entries.values():
        assert entry["status"] == "pass"
        assert entry["dependency_available"] is True
        assert entry["runtime_invoked"] is True
        assert entry["text_length"] > 0
        assert "text" not in entry
    assert entries["unstructured"]["supported_extensions"] == [".md", ".txt"]


def test_committed_p21_release_evidence_is_internally_consistent():
    matrix = _json(P21_AUDIT_DIR / "parser_backend_matrix.json")
    schema = _json(P21_AUDIT_DIR / "backend_status_schema.json")
    failure = _json(P21_AUDIT_DIR / "failure_mode_report.json")
    evidence = _json(P21_AUDIT_DIR / "evidence_index.json")

    required_fields = set(schema["required_backend_fields"])
    for backend in matrix["backends"]:
        assert required_fields <= set(backend)
        assert backend["static_workbench_executable"] is False
    unstructured = {backend["backend_id"]: backend for backend in matrix["backends"]}["unstructured"]
    assert unstructured["validated_stable_surface"] == [".md", ".txt"]
    assert any("future hardening" in item for item in unstructured["known_limitations"])
    assert failure["crash_only_failures_allowed"] is False
    artifact_paths = {item["path"] for item in evidence["artifacts"]}
    assert "docs/audits/p2_1_parser_ocr_backends/parser_backend_matrix.json" in artifact_paths
    assert "docs/audits/p2_1_parser_ocr_backends/backend_capability_boundaries.md" in artifact_paths


def test_audit_index_links_p21_release_artifacts():
    text = (ROOT / "docs" / "audits" / "index.md").read_text(encoding="utf-8")

    for marker in [
        "p2_1_parser_ocr_backends/parser_backend_matrix.json",
        "p2_1_parser_ocr_backends/parser_backend_status_report.md",
        "p2_1_parser_ocr_backends/backend_capability_boundaries.md",
        "p2_1_parser_ocr_backends/live_acceptance_replay.md",
        "p2_1_parser_ocr_backends/failure_mode_report.json",
    ]:
        assert marker in text


def test_parse_compare_records_optional_backend_differences(tmp_path):
    source = tmp_path / "input.pdf"
    output = tmp_path / "compare"
    source.write_bytes(b"%PDF fake fixture")

    result = CliRunner().invoke(app, ["parse-compare", "--input", str(source), "--output", str(output), "--backends", "builtin,docling,marker"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parse_compare_result.json")
    assert payload["status"] == "warning"
    assert payload["backends"] == ["builtin", "docling", "marker"]
    assert "docling" in payload["unavailable_backends"]
    assert "marker" in payload["unavailable_backends"]
    assert (output / "parse_compare_report.md").exists()


def test_default_build_keeps_standard_output_without_parser_files(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Default build parser backend remains off.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    for file_name in STANDARD_FILES:
        assert (output / file_name).exists()
    for file_name in PARSER_FILES:
        assert not (output / file_name).exists()
    manifest = _json(output / "manifest.json")
    assert "parser_backend_enabled" not in manifest


def test_build_with_builtin_backend_writes_reliability_outputs_and_draft_metadata(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Parser backend build fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output), "--parser-backend", "builtin"])

    assert result.exit_code == 0, result.output
    for file_name in STANDARD_FILES | PARSER_FILES:
        assert (output / file_name).exists()
    manifest = _json(output / "manifest.json")
    assert manifest["parser_backend_enabled"] is True
    assert manifest["parser_backend"] == "builtin"
    assert manifest["kb_trust_status"] == "draft_knowledge_package"
    assert manifest["trusted_kb_gate_status"] == "fail"
    chunk = _jsonl(output / "chunks.jsonl")[0]
    assert chunk["metadata"]["parser_backend"] == "builtin"
    assert chunk["metadata"]["kb_trust_status"] == "draft_knowledge_package"
    assert chunk["metadata"]["parse_confidence"] == 0.95
    gate = _json(output / "trusted_kb_gate.json")
    assert gate["status"] == "fail"
    assert gate["blocked"] is True


def test_parse_quality_gate_writes_trust_status_and_review_outputs(tmp_path):
    source = tmp_path / "input.md"
    parse_output = tmp_path / "parse"
    quality_output = tmp_path / "quality"
    source.write_text("Quality gate parser backend fixture.", encoding="utf-8")
    parse_result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(parse_output), "--backend", "builtin"])
    assert parse_result.exit_code == 0, parse_result.output

    result = CliRunner().invoke(app, ["parse-quality-gate", "--input", str(parse_output), "--output", str(quality_output)])

    assert result.exit_code == 0, result.output
    quality = _json(quality_output / "parse_quality_report.json")
    assert quality["kb_trust_status"] == "draft_knowledge_package"
    assert quality["trusted_kb_gate_status"] == "fail"
    assert (quality_output / "manual_review_queue.jsonl").exists()
    reliability = _json(quality_output / "knowledge_reliability_report.json")
    assert reliability["status"] == "fail"


def test_corrected_text_reimport_promotes_non_empty_text_and_keeps_empty_text_draft(tmp_path):
    corrected = tmp_path / "corrected"
    reviewed_output = tmp_path / "reviewed"
    empty_output = tmp_path / "empty"
    corrected.mkdir()
    (corrected / "fixed.md").write_text("Reviewed corrected parser text.", encoding="utf-8")

    reviewed = CliRunner().invoke(app, ["parse-reimport-corrected-text", "--corrected-text", str(corrected), "--output", str(reviewed_output)])

    assert reviewed.exit_code == 0, reviewed.output
    assert _json(reviewed_output / "parser_backend_result.json")["kb_trust_status"] == "reviewed_knowledge_base"
    assert _json(reviewed_output / "trusted_kb_gate.json")["status"] == "pass"
    assert _json(reviewed_output / "before_after_quality_diff.json")["status"] == "pass"

    empty_file = tmp_path / "empty.md"
    empty_file.write_text("", encoding="utf-8")
    empty = CliRunner().invoke(app, ["parse-reimport-corrected-text", "--corrected-text", str(empty_file), "--output", str(empty_output)])

    assert empty.exit_code == 0, empty.output
    assert _json(empty_output / "parser_backend_result.json")["kb_trust_status"] == "draft_knowledge_package"
    assert _json(empty_output / "trusted_kb_gate.json")["status"] == "fail"


def test_trusted_kb_gate_blocks_draft_allows_explicit_untrusted_and_keeps_legacy_compatible(tmp_path):
    draft = tmp_path / "draft"
    gate = tmp_path / "gate"
    allow_gate = tmp_path / "allow_gate"
    unknown = tmp_path / "unknown"
    legacy = tmp_path / "legacy"
    for path in [draft, unknown, legacy]:
        path.mkdir()
    write_json(draft / "kb_trust_status.json", {"kb_trust_status": "draft_knowledge_package"})
    write_json(unknown / "kb_trust_status.json", {"kb_trust_status": "surprise_status"})

    result = CliRunner().invoke(app, ["trusted-kb-gate", "--package", str(draft), "--output", str(gate)])
    assert result.exit_code == 1, result.output
    assert _json(gate / "trusted_kb_gate.json")["blocked"] is True

    allow = CliRunner().invoke(app, ["trusted-kb-gate", "--package", str(draft), "--output", str(allow_gate), "--allow-untrusted"])
    assert allow.exit_code == 0, allow.output
    allow_payload = _json(allow_gate / "trusted_kb_gate.json")
    assert allow_payload["status"] == "pass"
    assert allow_payload["trusted"] is False

    unknown_result = CliRunner().invoke(app, ["trusted-kb-gate", "--package", str(unknown), "--output", str(tmp_path / "unknown_gate")])
    assert unknown_result.exit_code == 1, unknown_result.output

    legacy_result = CliRunner().invoke(app, ["trusted-kb-gate", "--package", str(legacy), "--output", str(tmp_path / "legacy_gate")])
    assert legacy_result.exit_code == 0, legacy_result.output


def test_generate_skill_blocks_draft_parser_package_unless_allowed(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    skill = tmp_path / "skill"
    allowed_skill = tmp_path / "allowed_skill"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Skill export gate parser backend fixture.", encoding="utf-8")
    build = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--parser-backend", "builtin"])
    assert build.exit_code == 0, build.output

    blocked = CliRunner().invoke(app, ["generate-skill", "--package", str(package), "--output", str(skill)])
    assert blocked.exit_code != 0
    assert not (skill / "skill_manifest.yaml").exists()

    allowed = CliRunner().invoke(app, ["generate-skill", "--package", str(package), "--output", str(allowed_skill), "--allow-untrusted"])
    assert allowed.exit_code == 0, allowed.output
    manifest = (allowed_skill / "skill_manifest.yaml").read_text(encoding="utf-8")
    assert "kb_trust_status: draft_knowledge_package" in manifest


def test_config_skill_generation_blocks_parser_draft_unless_allow_untrusted(tmp_path):
    input_dir = tmp_path / "input"
    blocked_output = tmp_path / "blocked"
    allowed_output = tmp_path / "allowed"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Config skill trust gate fixture.", encoding="utf-8")
    blocked_config = tmp_path / "blocked.yaml"
    allowed_config = tmp_path / "allowed.yaml"
    blocked_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {blocked_output.as_posix()}
domain: parser_backend
mode: reliability
parser_backend:
  use_for_build: true
  default: builtin
skill:
  enabled: true
""",
        encoding="utf-8",
    )
    allowed_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {allowed_output.as_posix()}
domain: parser_backend
mode: reliability
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
skill:
  enabled: true
""",
        encoding="utf-8",
    )

    blocked = CliRunner().invoke(app, ["run", "--config", str(blocked_config)])
    assert blocked.exit_code != 0
    assert not (blocked_output / "skill_package" / "skill_manifest.yaml").exists()

    allowed = CliRunner().invoke(app, ["run", "--config", str(allowed_config)])
    assert allowed.exit_code == 0, allowed.output
    assert (allowed_output / "skill_package" / "skill_manifest.yaml").exists()


def test_pipeline_reports_parser_backend_gate_failure_and_allow_untrusted_success(tmp_path):
    input_dir = tmp_path / "input"
    fail_output = tmp_path / "pipeline_fail"
    pass_output = tmp_path / "pipeline_pass"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline parser backend fixture.", encoding="utf-8")
    fail_config = tmp_path / "fail.yaml"
    pass_config = tmp_path / "pass.yaml"
    fail_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {fail_output.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
""",
        encoding="utf-8",
    )
    pass_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {pass_output.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
""",
        encoding="utf-8",
    )

    failed = CliRunner().invoke(app, ["pipeline", "--config", str(fail_config)])
    assert failed.exit_code == 0, failed.output
    failed_manifest = _json(fail_output / "pipeline_manifest.json")
    failed_stages = {stage["name"]: stage for stage in failed_manifest["stages"]}
    assert failed_stages["parser_backend_parse"]["status"] == "success"
    assert failed_stages["trusted_kb_gate"]["status"] == "failed"
    assert failed_stages["knowledge_reliability_report"]["status"] == "failed"
    assert failed_manifest["final_status"] == "fail"

    passed = CliRunner().invoke(app, ["pipeline", "--config", str(pass_config)])
    assert passed.exit_code == 0, passed.output
    passed_manifest = _json(pass_output / "pipeline_manifest.json")
    passed_stages = {stage["name"]: stage for stage in passed_manifest["stages"]}
    assert passed_stages["trusted_kb_gate"]["status"] == "success"
    assert passed_stages["knowledge_reliability_report"]["status"] == "success"
    assert passed_manifest["final_status"] == "pass"
