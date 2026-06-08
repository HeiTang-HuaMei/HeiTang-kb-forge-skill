from tests.multi_source_helpers import make_multi_source_run, read_json


def test_thread_or_conversation_merge_preserves_chronological_order(tmp_path):
    output = make_multi_source_run(tmp_path)

    report = read_json(output / "thread_or_conversation_merge_report.json")
    thread = next(item for item in report["threads"] if item["thread_id"] == "thread-1")

    assert report["status"] == "pass"
    assert report["chronological_ordering"] is True
    assert thread["source_ids"] == ["thread-1-a", "thread-1-b"]
    assert thread["message_count"] == 2
