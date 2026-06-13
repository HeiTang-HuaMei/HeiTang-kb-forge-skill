import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MATRIX_PATH = ROOT / "artifacts" / "audits" / "backend_remediation_acceptance_review" / "backend_remediation_acceptance_matrix.json"
SUMMARY_PATH = ROOT / "artifacts" / "audits" / "backend_remediation_acceptance_review" / "run_summary.md"


def _matrix() -> dict:
    return json.loads(MATRIX_PATH.read_text(encoding="utf-8"))


def _by_id() -> dict[str, dict]:
    return {item["adapter_id"]: item for item in _matrix()["backends"]}


def test_campaign_1_acceptance_matrix_exists_and_is_accepted():
    matrix = _matrix()

    assert matrix["verdict"] == "accepted"
    assert matrix["summary"]["campaign_1_acceptance_verdict"] == "accepted"
    assert matrix["summary"]["can_enter_campaign_2"] is True
    assert matrix["summary"]["can_enter_campaign_3_from_campaign_1_alone"] is False
    assert SUMMARY_PATH.exists()


def test_campaign_1_reviews_all_required_backends():
    expected = {
        "paddleocr",
        "mineru",
        "docling",
        "marker",
        "opendataloader",
        "surya",
        "unstructured",
        "builtin",
    }

    assert set(_by_id()) == expected


def test_structured_skipped_and_dependency_missing_do_not_count_as_real_integration():
    matrix = _matrix()
    rules = matrix["non_substitution_rules"]

    assert rules["structured_skipped_counts_as_real_integration"] is False
    assert rules["dependency_missing_counts_as_real_integration"] is False
    assert rules["planned_adapter_counts_as_real_adapter"] is False
    for backend in matrix["backends"]:
        assert backend["structured_skipped_only_fallback"] is True
        if backend["dependency_status_after_remediation"] == "missing":
            assert backend["integration_decision"] != "real_integration"


def test_surya_is_accepted_only_as_non_primary_benchmark_reference():
    surya = _by_id()["surya"]

    assert surya["integration_decision"] == "needs_strengthening"
    assert surya["dependency_status_after_remediation"] == "missing"
    assert surya["runtime_check_status"] == "skipped"
    assert surya["smoke_status"] == "blocked"
    assert surya["can_count_as_campaign_1_accepted"] is True
    assert "non-primary" in surya["accepted_boundary"]
    assert "not as real runtime parser integration" in surya["accepted_boundary"]


def test_unstructured_and_fallback_boundaries_do_not_claim_full_du_backend():
    backends = _by_id()

    assert "not a full OCR/layout/table/formula Document Understanding backend" in backends["unstructured"]["remaining_gap"]
    assert "not a full Document Understanding backend" in backends["builtin"]["remaining_gap"]
    assert backends["builtin"]["dependency_status_after_remediation"] == "bundled"
    assert backends["builtin"]["remediation_attempted"] is False


def test_primary_backends_have_remediation_or_runtime_evidence():
    backends = _by_id()
    for adapter_id in ["paddleocr", "mineru", "docling", "marker", "opendataloader", "unstructured"]:
        backend = backends[adapter_id]
        assert backend["remediation_attempted"] is True
        assert backend["dependency_status_after_remediation"] == "available"
        assert backend["integration_decision"] == "real_integration"
        assert backend["smoke_status"] in {"pass", "passed"}
        assert backend["real_run_status"] == "pass"
        assert backend["integration_decision_report_path"]
        assert backend["ui_impact_note_path"]
        assert backend["core_bridge_action_allowlist_status"] in {"allowlisted", "benchmark_check_only"}
