import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_optional_llm_provider_report_redacts_and_explains_visibility():
    report = json.loads((PROOF / "optional_llm_provider_acceptance_report.json").read_text(encoding="utf-8"))

    assert "HEITANG_LLM_API_KEY" in report["required_env_visibility"]
    assert report["api_key_value_written"] is False
    assert report["api_key_value_committed"] is False
    assert report["core_workflow_requires_llm"] is False
    assert report["tests_require_real_llm_api_network"] is False
    if report["status"] == "needs_review":
        assert "process environment isolation" in report["skip_reason"]
