import json
import sys
import types

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.parser_backends import unstructured_adapter
from heitang_kb_forge.parser_backends.document_backend_contract import AdapterResult


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _install_fake_unstructured(monkeypatch):
    def fake_partition(filename):
        return [
            types.SimpleNamespace(text="Unstructured stable text."),
            types.SimpleNamespace(text="Second element."),
        ]

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


def test_fallback_parser_contract_limits_builtin_to_basic_text_contract(tmp_path):
    output = tmp_path / "fallback"

    result = CliRunner().invoke(app, ["fallback-parser-contract", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "fallback_parser_contract.json")
    assert payload["adapter_id"] == "builtin"
    assert payload["adapter_type"] == "fallback_parser"
    assert payload["decision"] == "real_integration"
    assert payload["default_install_available"] is True
    assert payload["handles_basic_text_documents"] is True
    assert payload["validated_stable_surface"] == [".md", ".txt"]
    assert payload["primary_document_understanding_backend"] is False
    assert payload["full_layout_support"] is False
    assert payload["full_ocr_support"] is False
    assert payload["formula_recognition_support"] is False
    assert payload["contract_capabilities"]["layout_support"] == "unsupported"
    assert payload["contract_capabilities"]["formula_support"] == "unsupported"
    assert (output / "fallback_parser_contract.md").exists()


def test_check_unstructured_backend_writes_decision_remediation_and_ui_note(tmp_path, monkeypatch):
    monkeypatch.setattr(unstructured_adapter, "find_spec", lambda name: None)
    output = tmp_path / "check"

    result = CliRunner().invoke(app, ["check-unstructured-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "unstructured_integration_decision_report.json")
    assert payload["decision"] == "real_integration"
    assert payload["current_environment_status"] == "blocked_by_dependency"
    assert payload["dependency_status"] == "missing"
    assert payload["capabilities"]["basic_text_documents"] is True
    assert payload["capabilities"]["full_document_understanding_backend"] is False
    assert payload["capabilities"]["structured_skipped_when_missing"] is True
    assert payload["commands"]["fallback_contract"] == "fallback-parser-contract"
    remediation = _json(output / "unstructured_dependency_remediation_report.json")
    assert remediation["adapter_name"] == "unstructured"
    assert remediation["missing_dependencies"] == ["unstructured"]
    assert remediation["install_attempted"] is False
    assert remediation["post_install_check_result"] == "blocked_by_dependency"
    assert remediation["final_decision"] == "needs_strengthening"
    ui_note = _json(output / "unstructured_ui_impact_note.json")
    assert ui_note["ui_status"] == "dependency_missing"
    assert ui_note["web_execution_enabled"] is False
    assert ui_note["web_blocked_reason"] == "web_local_cli_unsupported"
    assert (output / "fallback_parser_contract.md").exists()
    assert (output / "unstructured_integration_decision_report.md").exists()
    assert (output / "unstructured_dependency_remediation_report.md").exists()
    assert (output / "unstructured_ui_impact_note.md").exists()


def test_smoke_unstructured_backend_missing_dependency_is_structured_skipped(tmp_path, monkeypatch):
    monkeypatch.setattr(unstructured_adapter, "find_spec", lambda name: None)
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-unstructured-backend", "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "unstructured_smoke_report.json")
    result_payload = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "blocked"
    assert payload["adapter_smoke_report"]["status"] == "skipped"
    assert result_payload["status"] == "skipped"
    assert result_payload["runtime_status"] == "skipped"
    assert {error["code"] for error in result_payload["errors"]} == {"optional_runtime_dependency_missing"}
    assert result_payload["fallback_result"] == "builtin_available"
    assert payload["full_document_understanding_backend"] is False
    assert payload["structured_skipped_when_missing"] is True
    remediation = _json(output / "unstructured_dependency_remediation_report.json")
    assert remediation["post_install_smoke_result"] == "blocked"
    assert remediation["final_decision"] == "needs_strengthening"
    assert "no_supported_sources" not in payload["run"]["warnings"]


def test_smoke_unstructured_backend_passes_with_md_runtime_fixture(tmp_path, monkeypatch):
    _install_fake_unstructured(monkeypatch)
    source = tmp_path / "input.md"
    source.write_text("# Fixture\n\nUnstructured should parse this.", encoding="utf-8")
    output = tmp_path / "smoke"

    result = CliRunner().invoke(app, ["smoke-unstructured-backend", "--input", str(source), "--output", str(output)])

    assert result.exit_code == 0, result.output
    payload = _json(output / "unstructured_smoke_report.json")
    adapter_result = payload["adapter_smoke_report"]["result"]
    assert payload["status"] == "pass"
    assert payload["adapter_smoke_report"]["status"] == "pass"
    assert payload["basic_text_documents_supported"] is True
    assert payload["validated_stable_surface"] == [".md", ".txt"]
    assert payload["layout_claimed_stable"] is False
    assert payload["ocr_claimed_stable"] is False
    assert adapter_result["status"] == "success"
    assert adapter_result["confidence"] == 0.86
    assert adapter_result["source_trace"][0]["command"] == "parser-backend-smoke --backend unstructured"
    remediation = _json(output / "unstructured_dependency_remediation_report.json")
    assert remediation["post_install_smoke_result"] == "pass"
    assert remediation["final_decision"] == "real_integration"
    AdapterResult.model_validate(adapter_result)
