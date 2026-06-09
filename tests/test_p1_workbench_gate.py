from heitang_kb_forge.workbench import make_p1_workbench_bundle, make_p1_workbench_smoke


def test_p1_workbench_gate_is_honest_and_not_v4_rc():
    gate = make_p1_workbench_bundle().p1_gate_report

    assert gate.core_contract_ready is True
    assert gate.ui_full_operation_pending is True
    assert gate.p1_full_operation_gate_status == "blocked"
    assert gate.not_v4_0_workbench_rc is True
    assert gate.dashboard_readable is True
    assert gate.reports_readable is True
    assert gate.gate_page_readable is True


def test_p1_workbench_smoke_reports_blocked_gate_without_real_operations():
    result = make_p1_workbench_smoke()

    assert result["status"] == "pass"
    assert result["executes_real_operation"] is False
    assert result["core_contract_ready"] is True
    assert result["ui_full_operation_pending"] is True
    assert result["p1_full_operation_gate_status"] == "blocked"
    assert result["not_v4_0_workbench_rc"] is True


def test_external_parser_and_ocr_backends_are_not_marked_ready():
    candidates = {candidate.provider_id: candidate for candidate in make_p1_workbench_bundle().provider_schema.candidates}

    for provider_id in ["opendataloader", "paddleocr", "mineru"]:
        candidate = candidates[provider_id]
        assert candidate.status == "planned_adapter"
        assert candidate.ready is False
        assert candidate.blocked_reason


def test_external_provider_requires_explicit_user_config():
    schema = make_p1_workbench_bundle().provider_schema

    assert schema.network_required_by_default is False
    assert schema.redaction_required is True
    assert any(candidate.provider_id == "external_llm" and candidate.requires_explicit_user_config for candidate in schema.candidates)
