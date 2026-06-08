from tests.structured_skill_helpers import make_structured_skill, read_json


def test_structured_skill_links_to_kb_rag_agent_and_multi_kb_contracts(tmp_path):
    package, skill = make_structured_skill(tmp_path)

    report = read_json(skill / "skill_agent_kb_compatibility_report.json")
    relation = report["relation"]

    assert report["status"] == "pass"
    assert relation["source_package_id"] == "pkg-test"
    assert relation["kb_id"] == "pkg-test"
    assert relation["skill_id"] == "structured-demo-skill"
    assert "kb_bound" in relation["supported_agent_modes"]
    assert "mother_agent" in relation["supported_agent_modes"]
    assert "vector_store_records.jsonl" in report["rag_index_metadata_files"]
    assert report["knowledge_package"].endswith(package.name)
    assert report["agent_package_generation_supported"] is True
    assert report["multi_kb_orchestration_supported"] is True
