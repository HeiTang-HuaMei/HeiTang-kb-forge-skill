import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_skill_metadata_files_exist_and_are_agent_readable():
    skill_md = ROOT / "SKILL.md"
    skill_json = ROOT / "skill.json"

    assert skill_md.exists()
    assert skill_json.exists()
    text = skill_md.read_text(encoding="utf-8")
    metadata = json.loads(skill_json.read_text(encoding="utf-8"))
    assert "HeiTang KB Forge Skill" in text
    assert "Agent knowledge supply-chain" in text
    assert metadata["name"] == "heitang-kb-forge-skill"
    assert metadata["version"] == "4.1.0"
    assert metadata["entrypoints"]["cli"] == "heitang-kb-forge"
    assert "build_knowledge_package" in metadata["capabilities"]
    assert "agent_ask" in metadata["preview_capabilities"]
    assert "master_skill_learning" in metadata["experimental_capabilities"]
    assert "llm_live_smoke" in metadata["experimental_capabilities"]
    assert "provider_security_governance" in metadata["experimental_capabilities"]
    assert "minimal_e2e_demo" in metadata["experimental_capabilities"]
    assert "parser_backend_abstraction" in metadata["preview_capabilities"]
    assert "parse_quality_gate" in metadata["preview_capabilities"]
    assert "knowledge_reliability_gate" in metadata["preview_capabilities"]
    assert "knowledge_runtime_loop" in metadata["preview_capabilities"]
    assert "kb_index_query_answer" in metadata["preview_capabilities"]
    assert "product_hardening_release_readiness" in metadata["preview_capabilities"]
    assert "runtime_compatibility_hardening" in metadata["roadmap_capabilities"]
    assert metadata["network_required_by_default"] is False
    assert metadata["real_platform_publish_by_default"] is False
    assert metadata["stores_real_api_keys"] is False
    assert "chunks.jsonl" in metadata["output_contract"]

