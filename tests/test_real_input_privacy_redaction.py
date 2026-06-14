from tests.v4_2_baseline_evidence import load_baseline_report



def test_real_input_privacy_redaction_excludes_forbidden_artifacts():
    report = load_baseline_report("real_input_privacy_redaction_report.json")
    index = load_baseline_report("real_input_artifact_index.json")

    assert report["raw_inputs_excluded_from_commit"] is True
    assert report["full_extracted_chunks_excluded_from_commit"] is True
    assert report["generated_documents_excluded_from_commit"] is True
    assert report["api_keys_written"] is False
    assert report["api_keys_committed"] is False
    assert index["raw_inputs_committed"] is False
    assert index["full_chunks_committed"] is False
    assert all("content" not in item for item in index["raw_input_index"])
