import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_pre_v4_blocker_fix_report_is_honest_and_parseable():
    path = PROOF / "pre_v4_real_acceptance_blocker_fix_report.json"
    assert path.exists()
    report = json.loads(path.read_text(encoding="utf-8"))

    assert report["ready_for_v4_rc"] is False
    assert report["p0_remaining_count"] >= 0
    assert report["raw_inputs_committed"] is False
    assert report["full_extracted_chunks_committed"] is False
    assert report["api_keys_committed"] is False
    assert report["tests_require_real_llm_api_network"] is False
