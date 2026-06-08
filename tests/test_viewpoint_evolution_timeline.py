from tests.multi_source_helpers import make_multi_source_run, read_json


def test_viewpoint_evolution_timeline_orders_events_by_time(tmp_path):
    output = make_multi_source_run(tmp_path)

    report = read_json(output / "viewpoint_evolution_timeline.json")
    times = [item["created_at"] for item in report["events"]]

    assert report["status"] == "pass"
    assert report["chronological_ordering"] is True
    assert times == sorted(times)
    assert all(item["citation_id"].startswith("msrc-") for item in report["events"])
