from tests.multi_source_helpers import make_multi_source_run, read_json


def test_source_citation_map_links_every_normalized_source(tmp_path):
    output = make_multi_source_run(tmp_path)

    citation_map = read_json(output / "source_citation_map.json")
    inventory = read_json(output / "multi_source_inventory.json")

    assert citation_map["status"] == "pass"
    assert citation_map["source_citations_missing"] is False
    assert len(citation_map["citations"]) == inventory["source_count"]
    assert {item["citation_id"] for item in citation_map["citations"]} == {item["citation_id"] for item in inventory["sources"]}
