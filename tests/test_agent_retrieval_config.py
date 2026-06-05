from heitang_kb_forge.agent_package.retrieval_config import make_retrieval_config


def test_agent_retrieval_config_references_v17_files():
    config = make_retrieval_config()

    assert "retrieval_index.jsonl" in config
    assert "context_pack.json" in config
    assert "evidence_gate_result.json" in config
