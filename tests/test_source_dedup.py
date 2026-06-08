from tests.multi_source_helpers import make_multi_source_run, read_json


def test_source_dedup_removes_duplicate_normalized_text(tmp_path):
    output = make_multi_source_run(tmp_path)

    report = read_json(output / "source_dedup_report.json")

    assert report["status"] == "pass"
    assert report["input_count"] == 4
    assert report["deduped_count"] == 3
    assert report["duplicate_count"] == 1
    assert report["duplicates"][0]["reason"] == "same_normalized_text_hash"
