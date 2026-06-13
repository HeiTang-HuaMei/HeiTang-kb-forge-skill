import json
from pathlib import Path

from heitang_kb_forge.parser_backends import docling_adapter, marker_adapter, opendataloader_adapter, surya_adapter
from heitang_kb_forge.parser_backends.document_backend_contract import (
    AdapterCapability,
    AdapterResult,
    AdapterSmokeReport,
    DocumentUnderstandingResult,
)
from heitang_kb_forge.parser_backends.quality import load_parse_run
from heitang_kb_forge.parser_backends.registry import list_backends, parse_sources_with_backend


ROOT = Path(__file__).resolve().parents[1]
SCHEMA_ROOT = ROOT / "heitang_kb_forge" / "schemas"
REQUIRED_CONTRACT_FIELDS = {
    "adapter_id",
    "adapter_name",
    "adapter_version",
    "adapter_type",
    "dependency_name",
    "optional_extra",
    "dependency_status",
    "runtime_status",
    "supported_inputs",
    "validated_inputs",
    "supported_outputs",
    "ocr_support",
    "layout_support",
    "table_support",
    "figure_support",
    "formula_support",
    "reading_order_support",
    "confidence",
    "warnings",
    "errors",
    "source_trace",
    "fallback_reason",
    "fallback_result",
    "repair_suggestion",
}


def _error_codes(payload):
    return {item["code"] for item in payload.get("errors", [])}


def test_document_backend_schema_files_are_valid_json_and_require_contract_fields():
    names = [
        "adapter_capability_schema.json",
        "adapter_result_schema.json",
        "adapter_error_schema.json",
        "adapter_smoke_report_schema.json",
        "document_understanding_result_schema.json",
    ]

    schemas = {name: json.loads((SCHEMA_ROOT / name).read_text(encoding="utf-8")) for name in names}

    capability_contract = schemas["adapter_capability_schema.json"]["$defs"]["contract"]
    assert REQUIRED_CONTRACT_FIELDS <= set(capability_contract["required"])
    assert schemas["adapter_result_schema.json"]["allOf"][1]["properties"]["status"]["enum"] == [
        "success",
        "partial",
        "skipped",
        "failed",
        "empty",
        "unsupported",
    ]
    assert "blocks" in schemas["document_understanding_result_schema.json"]["required"]


def test_contract_models_publish_json_schemas():
    assert AdapterCapability.model_json_schema()["title"] == "AdapterCapability"
    assert AdapterResult.model_json_schema()["title"] == "AdapterResult"
    assert AdapterSmokeReport.model_json_schema()["title"] == "AdapterSmokeReport"
    assert DocumentUnderstandingResult.model_json_schema()["title"] == "DocumentUnderstandingResult"


def test_backend_registry_exposes_truthful_capability_contracts(monkeypatch):
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: None)
    monkeypatch.setattr(marker_adapter, "find_spec", lambda name: None)
    monkeypatch.setattr(opendataloader_adapter.shutil, "which", lambda name: None)
    monkeypatch.setattr(surya_adapter.shutil, "which", lambda name: None)

    rows = {row["name"]: row for row in list_backends()}
    builtin = rows["builtin"]["capability_contract"]
    docling = rows["docling"]["capability_contract"]
    marker_row = rows["marker"]
    marker = rows["marker"]["capability_contract"]
    opendataloader = rows["opendataloader"]["capability_contract"]
    surya = rows["surya"]["capability_contract"]

    assert REQUIRED_CONTRACT_FIELDS <= set(builtin)
    assert builtin["integration_decision"] == "real_integration"
    assert builtin["dependency_status"] == "bundled"
    assert builtin["runtime_status"] == "ready"
    assert set(builtin["validated_inputs"]) <= set(builtin["supported_inputs"])
    assert docling["dependency_status"] == "missing"
    assert docling["runtime_status"] == "skipped"
    assert "optional_runtime_dependency_missing" in _error_codes(docling)
    assert set(docling["validated_inputs"]) == {".md", ".txt"}
    assert docling["layout_support"] == "unknown"
    assert marker["integration_decision"] == "real_integration"
    assert marker["runtime_status"] == "skipped"
    assert "optional_runtime_dependency_missing" in _error_codes(marker)
    assert marker_row["contract_status"] == "skipped"
    assert opendataloader["integration_decision"] == "real_integration"
    assert opendataloader["dependency_status"] == "missing"
    assert opendataloader["runtime_status"] == "skipped"
    assert opendataloader["validated_inputs"] == [".pdf"]
    assert "optional_runtime_dependency_missing" in _error_codes(opendataloader)
    assert surya["integration_decision"] == "needs_strengthening"
    assert surya["dependency_status"] == "missing"
    assert surya["runtime_status"] == "skipped"
    assert "optional_runtime_dependency_missing" in _error_codes(surya)


def test_missing_dependency_is_serialized_as_structured_skipped(tmp_path, monkeypatch):
    monkeypatch.setattr(docling_adapter, "find_spec", lambda name: None)
    source = tmp_path / "input.pdf"
    source.write_bytes(b"%PDF fake fixture")

    payload = parse_sources_with_backend(source, "docling", "contract-test").to_dict()
    result = payload["records"][0]["adapter_result"]

    assert payload["status"] == "unavailable"
    assert result["status"] == "skipped"
    assert result["dependency_status"] == "missing"
    assert result["runtime_status"] == "skipped"
    assert "optional_runtime_dependency_missing" in _error_codes(result)
    assert result["fallback_reason"]
    assert result["fallback_result"] == "builtin_available"
    assert result["repair_suggestion"]


def test_marker_requires_real_cli_even_when_runtime_package_exists(tmp_path, monkeypatch):
    monkeypatch.setattr(marker_adapter, "find_spec", lambda name: object())
    monkeypatch.setattr(marker_adapter.shutil, "which", lambda name: None)
    monkeypatch.setattr(marker_adapter.sys, "executable", str(tmp_path / "python.exe"))
    source = tmp_path / "input.pdf"
    source.write_bytes(b"%PDF fake fixture")

    payload = parse_sources_with_backend(source, "marker", "contract-test").to_dict()
    contract = payload["adapter_contract"]
    result = payload["records"][0]["adapter_result"]

    assert contract["dependency_status"] == "missing"
    assert contract["runtime_status"] == "skipped"
    assert contract["integration_decision"] == "real_integration"
    assert "optional_runtime_dependency_missing" in _error_codes(contract)
    assert result["status"] == "skipped"
    assert "optional_runtime_dependency_missing" in _error_codes(result)


def test_marker_inspect_and_smoke_use_contract_without_historical_matrix_crash(tmp_path, monkeypatch):
    from heitang_kb_forge.parser_backends.release_hardening import inspect_backend_status, make_parser_backend_smoke

    monkeypatch.setattr(marker_adapter, "find_spec", lambda name: object())
    monkeypatch.setattr(marker_adapter.shutil, "which", lambda name: None)
    monkeypatch.setattr(marker_adapter.sys, "executable", str(tmp_path / "python.exe"))
    source = tmp_path / "input.pdf"
    source.write_bytes(b"%PDF fake fixture")

    inspect = inspect_backend_status("marker")
    smoke = make_parser_backend_smoke("marker", source)

    assert inspect["status"] == "blocked_by_dependency"
    assert inspect["error_code"] == "optional_runtime_dependency_missing"
    assert inspect["capability_contract"]["integration_decision"] == "real_integration"
    assert smoke["status"] == "blocked"
    assert smoke["adapter_smoke_report"]["status"] == "skipped"
    assert "optional_runtime_dependency_missing" in _error_codes(smoke["adapter_smoke_report"]["result"])


def test_smoke_without_supported_source_keeps_structured_run_error(tmp_path):
    from heitang_kb_forge.parser_backends.release_hardening import make_parser_backend_smoke

    source = tmp_path / "input.bin"
    source.write_bytes(b"unsupported")

    smoke = make_parser_backend_smoke("builtin", source)

    assert smoke["status"] == "warning"
    assert smoke["adapter_smoke_report"]["result"] is None
    assert "unsupported_file_type" in _error_codes(smoke["adapter_smoke_report"])
    assert smoke["adapter_smoke_report"]["repair_suggestion"]


def test_parser_backend_result_round_trips_with_contract(tmp_path):
    source = tmp_path / "input.md"
    source.write_text("Contract round trip.", encoding="utf-8")
    payload = parse_sources_with_backend(source, "builtin", "contract-test").to_dict()
    target = tmp_path / "parser_backend_result.json"
    target.write_text(json.dumps(payload), encoding="utf-8")

    loaded = load_parse_run(target)

    assert loaded is not None
    assert loaded.adapter_contract["adapter_id"] == "builtin"
    assert loaded.to_dict()["records"][0]["adapter_result"]["status"] == "success"


def test_legacy_parser_backend_result_without_contract_still_loads(tmp_path):
    target = tmp_path / "parser_backend_result.json"
    target.write_text(
        json.dumps(
            {
                "backend_name": "builtin",
                "backend_version": "2.8.0-alpha.1",
                "command": "legacy",
                "status": "success",
                "source_count": 1,
                "records": [
                    {
                        "source_path": "legacy.md",
                        "source_type": "md",
                        "backend_name": "builtin",
                        "backend_version": "2.8.0-alpha.1",
                        "command": "legacy",
                        "status": "success",
                        "text": "legacy text",
                        "warnings": [],
                        "confidence": 0.95,
                        "metadata": {"adapter": "builtin"},
                    }
                ],
            }
        ),
        encoding="utf-8",
    )

    loaded = load_parse_run(target)

    assert loaded is not None
    assert loaded.adapter_contract == {}
    assert "adapter_result" not in loaded.to_dict()["records"][0]
