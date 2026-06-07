import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_scale_1500_readiness_is_synthetic_not_production_claim():
    report = json.loads((PROOF / "scale_1500_readiness_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["readiness"]["simulate_1500_books"] == "synthetic_only"
    assert report["readiness"]["simulate_1500_agents"] == "not_proven"
    assert "real 1500-book production workload proven" in report["must_not_claim"]
