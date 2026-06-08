from tests.multi_source_helpers import make_multi_source_run, read_json


def test_multi_source_normalization_creates_standard_knowledge_asset_fields(tmp_path):
    output = make_multi_source_run(tmp_path)

    normalization = read_json(output / "source_normalization_report.json")
    inventory = read_json(output / "multi_source_inventory.json")

    assert normalization["status"] == "pass"
    assert normalization["raw_text_dump_only"] is False
    assert normalization["tests_require_real_llm_api_network"] is False
    assert {
        "source_id",
        "source_type",
        "ingestion_mode",
        "normalized_text",
        "citation_id",
        "compliance_status",
    } <= set(normalization["schema_fields"])
    assert inventory["status"] == "pass"
    assert inventory["source_count"] == normalization["normalized_count"]
    assert all(item["citation_id"].startswith("msrc-") for item in inventory["sources"])
