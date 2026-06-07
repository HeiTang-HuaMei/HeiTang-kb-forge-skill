import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_security_threat_model_gap_report_keeps_remaining_gaps_visible():
    report = json.loads((PROOF / "security_threat_model_gap_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["covered_boundaries"]["api_key_redaction"] == "tested"
    assert report["covered_boundaries"]["agent_kb_boundary"] == "fixed_and_tested"
    gap_ids = {item["id"] for item in report["gaps"]}
    assert "runtime_network_behavior_not_dynamic_proven" in gap_ids
    assert "BYO cloud security ready" in report["must_not_claim"]
