import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_optional_llm_process_environment_isolation_is_not_user_blame():
    report = json.loads((PROOF / "optional_llm_provider_acceptance_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "needs_review"
    assert "process environment isolation" in report["skip_reason"]
    assert "user did not configure" not in report["skip_reason"].lower()
    assert report["api_key_value_written"] is False
    assert report["tests_require_real_llm_api_network"] is False
