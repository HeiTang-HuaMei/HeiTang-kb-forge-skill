from heitang_kb_forge.harness_adapter_spec import default_harness_adapter_specs, validate_harness_adapter_specs
from tests.v17_helpers import read_json


def test_harness_adapter_spec_accepts_local_contracts(tmp_path):
    report = validate_harness_adapter_specs(default_harness_adapter_specs(), tmp_path)

    persisted = read_json(tmp_path / "harness_adapter_spec_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert report.adapter_count == 4
    assert "codex_execution_harness" in report.allowed_capability_ids
    assert persisted["schema_version"] == "harness_adapter_spec.v1"
    assert persisted["boundary"]["ui_change"] == "not_required"
    assert persisted["boundary"]["runtime_change"] == "not_required"
    assert persisted["boundary"]["redis_service_packaging"] == "forbidden"
    assert persisted["boundary"]["vector_service_packaging"] == "forbidden"


def test_harness_adapter_spec_rejects_missing_required_fields():
    report = validate_harness_adapter_specs([{"adapter_id": "missing_contract"}])

    assert report.status == "failed"
    assert "entry_0:missing_or_invalid_capability_id" in report.failed_checks
    assert "entry_0:missing_or_invalid_input_contract" in report.failed_checks
    assert "entry_0:missing_or_invalid_output_contract" in report.failed_checks


def test_harness_adapter_spec_rejects_default_network_and_unknown_capability():
    spec = default_harness_adapter_specs()[0]
    spec["adapter_id"] = "bad_external_adapter"
    spec["capability_id"] = "unknown_harness"
    spec["execution_mode"] = "external_harness_runtime"
    spec["boundary"] = {
        "network": "required",
        "redis_service_packaging": "allowed",
        "vector_service_packaging": "allowed",
    }

    report = validate_harness_adapter_specs([spec])

    assert report.status == "failed"
    assert "bad_external_adapter:unknown_capability_id" in report.failed_checks
    assert "bad_external_adapter:unknown_execution_mode" in report.failed_checks
    assert "bad_external_adapter:default_network_forbidden" in report.failed_checks
    assert "bad_external_adapter:redis_service_packaging_boundary_missing" in report.failed_checks
    assert "bad_external_adapter:vector_service_packaging_boundary_missing" in report.failed_checks
