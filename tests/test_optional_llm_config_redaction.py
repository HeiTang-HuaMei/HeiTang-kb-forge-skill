import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_optional_llm_config_redaction_never_records_values():
    report = json.loads((PROOF / "optional_llm_config_redaction_report.json").read_text(encoding="utf-8"))

    assert report["status"] == "pass"
    assert "HEITANG_LLM_API_KEY" in report["env_names_recorded"]
    assert report["env_values_recorded"] is False
    assert report["api_key_value_recorded"] is False
    assert report["tests_require_real_llm_api_network"] is False
