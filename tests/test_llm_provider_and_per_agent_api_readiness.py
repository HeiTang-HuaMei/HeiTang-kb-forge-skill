import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_llm_provider_and_per_agent_api_readiness_is_optional_and_redacted():
    report = json.loads((PROOF / "llm_provider_and_per_agent_api_readiness_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert report["core_usable_without_llm_provider"] is True
    assert report["tests_require_real_llm_api_network"] is False
    assert report["api_keys_committed"] is False
    assert report["api_keys_printed"] is False
    assert report["per_agent_api_mapping"]["status"] == "partial"
