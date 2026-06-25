from copy import deepcopy

from heitang_kb_forge.role_protocol import default_role_protocol, validate_role_protocol
from tests.v17_helpers import read_json


def test_role_protocol_accepts_default_contract(tmp_path):
    report = validate_role_protocol(default_role_protocol(), tmp_path)

    persisted = read_json(tmp_path / "role_protocol_basic_report.json")
    assert report.status == "passed"
    assert report.failed_checks == []
    assert report.required_roles == ["thinker", "worker", "verifier"]
    assert persisted["schema_version"] == "role_protocol_basic.v1"
    assert persisted["boundary"]["default_network"] == "forbidden"
    assert persisted["boundary"]["provider_api_call"] == "not_required"
    assert persisted["boundary"]["local_model_training"] == "forbidden"
    assert persisted["boundary"]["gpu_training"] == "forbidden"
    assert persisted["boundary"]["redis_service_packaging"] == "forbidden"
    assert persisted["boundary"]["vector_service_packaging"] == "forbidden"


def test_role_protocol_rejects_missing_required_role():
    protocol = default_role_protocol()
    protocol["roles"] = [role for role in protocol["roles"] if role["role_id"] != "verifier"]

    report = validate_role_protocol(protocol)

    assert report.status == "failed"
    assert "missing_required_role:verifier" in report.failed_checks
    assert "approval_rules:verifier_not_required" not in report.failed_checks


def test_role_protocol_rejects_thinker_tool_execution_and_worker_self_approval():
    protocol = default_role_protocol()
    thinker = protocol["roles"][0]
    worker = protocol["roles"][1]
    thinker["allowed_actions"].append("execute_tools")
    worker["forbidden_actions"].remove("approve_own_output")
    protocol["approval_rules"]["worker_self_approval"] = "allowed"

    report = validate_role_protocol(protocol)

    assert report.status == "failed"
    assert "thinker:thinker_tool_execution_forbidden" in report.failed_checks
    assert "worker:worker_self_approval_not_forbidden" in report.failed_checks
    assert "approval_rules:worker_self_approval_not_forbidden" in report.failed_checks
    assert "approval_rules:worker_can_self_approve" in report.failed_checks


def test_role_protocol_rejects_verifier_missing_evidence_checks():
    protocol = deepcopy(default_role_protocol())
    verifier = protocol["roles"][2]
    verifier["evidence_requirements"] = ["white_box"]

    report = validate_role_protocol(protocol)

    assert report.status == "failed"
    assert "verifier:verifier_missing_required_evidence_checks" in report.failed_checks


def test_role_protocol_rejects_boundary_drift():
    protocol = default_role_protocol()
    protocol["boundary"]["default_network"] = "required"
    protocol["boundary"]["provider_api_call"] = "required"
    protocol["boundary"]["local_model_training"] = "allowed"
    protocol["boundary"]["gpu_training"] = "allowed"
    protocol["boundary"]["redis_service_packaging"] = "allowed"
    protocol["boundary"]["vector_service_packaging"] = "allowed"

    report = validate_role_protocol(protocol)

    assert report.status == "failed"
    assert "boundary:default_network_forbidden" in report.failed_checks
    assert "boundary:provider_api_call_not_required" in report.failed_checks
    assert "boundary:local_model_training_forbidden" in report.failed_checks
    assert "boundary:gpu_training_forbidden" in report.failed_checks
    assert "boundary:redis_service_packaging_forbidden" in report.failed_checks
    assert "boundary:vector_service_packaging_forbidden" in report.failed_checks
