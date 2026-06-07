import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_agent_runtime_truth_separates_local_runtime_from_full_tool_loop():
    report = json.loads((PROOF / "agent_runtime_capability_truth_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert report["tests_require_real_llm_api_network"] is False
    assert report["capabilities"]["kb_bound_agent"] == "fixed_and_tested"
    assert report["capabilities"]["kb_boundary"] == "fixed_and_tested"
    assert report["capabilities"]["full_tool_calling_agent_loop"] == "not_implemented"
    assert "full autonomous Agent Runtime" in report["must_not_claim"]
