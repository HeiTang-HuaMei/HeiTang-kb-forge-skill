from tests.multi_source_helpers import make_multi_source_run, read_json


def test_concept_map_report_extracts_concepts_without_llm(tmp_path):
    output = make_multi_source_run(tmp_path)

    report = read_json(output / "concept_map_report.json")
    concepts = {item["concept"] for item in report["concepts"]}

    assert report["status"] == "pass"
    assert report["concept_extraction"] == "deterministic_local_keyword_phrase_extraction"
    assert {"local-first", "guide", "opencli"} <= concepts
    assert report["tests_require_real_llm_api_network"] is False
