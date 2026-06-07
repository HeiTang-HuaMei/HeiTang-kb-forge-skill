import json
from pathlib import Path


PROOF = Path("docs/audits/local_acceptance/large_bilingual_run")


def test_real_input_privacy_redaction_excludes_forbidden_artifacts():
    report = json.loads((PROOF / "real_input_privacy_redaction_report.json").read_text(encoding="utf-8"))
    index = json.loads((PROOF / "real_input_artifact_index.json").read_text(encoding="utf-8"))

    assert report["raw_inputs_excluded_from_commit"] is True
    assert report["full_extracted_chunks_excluded_from_commit"] is True
    assert report["generated_documents_excluded_from_commit"] is True
    assert report["api_keys_written"] is False
    assert report["api_keys_committed"] is False
    assert index["raw_inputs_committed"] is False
    assert index["full_chunks_committed"] is False
    assert all("content" not in item for item in index["raw_input_index"])
