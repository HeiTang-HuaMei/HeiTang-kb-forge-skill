import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def _load(name: str) -> dict:
    return json.loads((PROOF / name).read_text(encoding="utf-8"))


def test_real_input_acceptance_manifest_is_redacted_and_parseable():
    manifest = _load("real_input_acceptance_manifest.json")

    assert manifest["input_file_count"] >= 1
    assert manifest["package_chunk_count"] >= 1
    assert manifest["raw_inputs_committed"] is False
    assert manifest["full_extracted_chunks_committed"] is False
    assert manifest["api_keys_committed"] is False
    assert manifest["tests_require_real_llm_api_network"] is False


def test_real_input_acceptance_report_records_blocked_truth():
    report = _load("real_input_acceptance_report.json")

    assert report["local_core_without_llm_status"] == "pass"
    assert report["ready_for_v4_rc"] is False
    assert report["overall_status"] in {"blocked", "needs_review", "pass"}
    assert report["blocker_count"] >= report["p0_count"]
