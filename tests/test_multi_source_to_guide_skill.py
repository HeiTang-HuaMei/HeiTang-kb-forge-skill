from tests.multi_source_helpers import make_multi_source_run, read_json


def test_multi_source_corpus_generates_cited_guide_skill_not_summary_only(tmp_path):
    output = make_multi_source_run(tmp_path)

    report = read_json(output / "multi_source_to_guide_skill_report.json")
    skill_path = output / "multi_source_guide_skill" / "SKILL.md"
    skill_text = skill_path.read_text(encoding="utf-8")

    assert report["status"] == "pass"
    assert report["guide_skill_is_summary_only"] is False
    assert report["uses_normalized_sources"] is True
    assert report["uses_source_citations"] is True
    assert report["can_feed_kb_package"] is True
    assert report["can_feed_guide_skill"] is True
    assert report["can_feed_structured_skill"] is True
    assert report["can_feed_agent_bound_knowledge"] is True
    assert "source_citation_map.json" in skill_text
    assert "Do not use it as a scraper, crawler, or platform login tool." in skill_text
