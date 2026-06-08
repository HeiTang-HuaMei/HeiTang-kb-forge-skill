from tests.multi_source_helpers import make_multi_source_run, read_json


def test_topic_cluster_report_uses_deterministic_local_clustering(tmp_path):
    output = make_multi_source_run(tmp_path)

    report = read_json(output / "topic_cluster_report.json")
    topics = {item["topic"] for item in report["clusters"]}

    assert report["status"] == "pass"
    assert report["cluster_count"] >= 2
    assert report["deterministic_local_path"] == "keyword_frequency_topic_assignment"
    assert {"local_privacy_boundary", "skill_agent_supply_chain", "opencli_bridge_boundary"} & topics
    assert report["tests_require_real_llm_api_network"] is False
