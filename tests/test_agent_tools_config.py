from heitang_kb_forge.agent.generator import make_agent_template
from heitang_kb_forge.schemas.agent_schema import AgentOptions


def test_agent_template_tools_yaml_has_runtime_connector_schema(tmp_path):
    result = make_agent_template(
        output=tmp_path / "package",
        domain="general",
        mode="reference",
        source_count=1,
        chunk_count=1,
        quality_report={"quality_score": 90, "quality_level": "excellent"},
        cards=[],
        qa_pairs=[],
        glossary=[],
        rag_enabled=True,
        llm_assets_enabled=False,
        options=AgentOptions(enabled=True),
    )

    tools = result.tools
    assert "runtime_required:" in tools
    assert "input_schema:" in tools
    assert "output_schema:" in tools
    assert "safety_notes:" in tools
    assert "config: {}" in tools
    assert "knowledge_retrieval" in tools
    assert "citation_lookup" in tools
    assert "quality_check" in tools
    assert "human_handoff" in tools
    assert "product_lookup_placeholder" in tools
    assert "crm_lookup_placeholder" in tools
    assert "order_lookup_placeholder" in tools
    assert "Tool configuration only; no runtime execution is performed by KB Forge." in tools
