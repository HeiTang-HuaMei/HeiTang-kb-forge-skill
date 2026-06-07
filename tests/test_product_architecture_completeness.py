import json
from pathlib import Path

from tests.final_audit_helpers import load_json, run_audit


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_product_architecture_completeness_report_covers_required_layers():
    report = json.loads((PROOF / "product_architecture_completeness_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "blocked"
    assert report["tests_require_real_llm_api_network"] is False
    layers = {item["layer"]: item for item in report["layers"]}
    assert set(layers) == {
        "input",
        "knowledge_package",
        "rag_vector_index",
        "lifecycle",
        "scale",
        "agent",
        "ui",
        "storage_security",
    }
    assert layers["input"]["items"]["large_pdf"] == "proven"
    assert layers["input"]["items"]["scanned_pdf_ocr"] == "needs_review_limited_ocr"
    assert layers["rag_vector_index"]["blocker_id"] == "rag_vector_index_industrial_readiness_unproven"
    assert layers["ui"]["classification"] == "contract_viewer_only"
    assert layers["storage_security"]["items"]["byo_cloud_database"] == "future_or_disabled"
    assert "full user-operable Workbench" in report["must_not_claim"]


def test_product_architecture_gate_summary_exposes_required_gate_fields():
    report = json.loads((PROOF / "product_architecture_completeness_report.json").read_text(encoding="utf-8"))
    summary = report["gate_summary"]

    for key in [
        "product_architecture_completeness",
        "rag_vector_index_readiness",
        "ui_full_operation_readiness",
        "lifecycle_update_readiness",
        "scale_1500_kb_agent_readiness",
    ]:
        assert key in summary

    assert summary["product_architecture_completeness"]["status"] == "blocked"
    assert summary["rag_vector_index_readiness"]["blocks_v4"] is True
    assert summary["ui_full_operation_readiness"]["classification"] == "contract_viewer_only"
    assert summary["lifecycle_update_readiness"]["status"] == "needs_review"
    assert summary["scale_1500_kb_agent_readiness"]["status"] == "needs_review"


def test_final_gate_exposes_all_product_architecture_readiness_fields(tmp_path):
    output, _ = run_audit(
        tmp_path,
        core_validation={"status": "pass"},
        ui_validation={"status": "pass"},
        ci_status={"status": "pass"},
    )
    gate = load_json(output, "final_v4_rc_gate_report.json")

    for key in [
        "product_architecture_completeness",
        "rag_vector_index_readiness",
        "multi_format_parser_readiness",
        "agent_runtime_truth",
        "lifecycle_update_readiness",
        "llm_provider_readiness",
        "per_agent_api_mapping_readiness",
        "storage_backend_readiness",
        "security_privacy_threat_model_readiness",
        "ui_full_operation_readiness",
        "scale_1500_readiness",
    ]:
        assert key in gate

    assert gate["ready_for_v4_rc"] is False
    assert gate["rag_vector_index_readiness"]["status"] == "blocked"
