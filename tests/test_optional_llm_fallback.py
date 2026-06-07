import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_optional_llm_fallback_keeps_core_usable_without_llm():
    report = json.loads((PROOF / "optional_llm_fallback_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "pass"
    assert report["core_workflow_usable_without_llm"] is True
    assert report["tests_require_real_llm_api_network"] is False
