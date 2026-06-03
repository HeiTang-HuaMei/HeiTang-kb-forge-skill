import json

from heitang_kb_forge.agent.generator import make_agent_template
from heitang_kb_forge.schemas.agent_schema import AgentOptions
from heitang_kb_forge.schemas.card_schema import KnowledgeCard
from heitang_kb_forge.schemas.qa_schema import QAPair


def test_agent_template_generates_profile_prompt_tools_and_eval_cases(tmp_path):
    result = make_agent_template(
        output=tmp_path / "package",
        domain="education",
        mode="teaching",
        source_count=1,
        chunk_count=1,
        quality_report={"quality_score": 90, "quality_level": "excellent"},
        cards=[_card()],
        qa_pairs=[_qa()],
        glossary=[_glossary()],
        rag_enabled=False,
        llm_assets_enabled=False,
        options=AgentOptions(enabled=True, agent_type="education_tutor_agent", agent_name="Tutor", language="zh-CN"),
    )

    assert "agent_name: Tutor" in result.agent_profile
    assert "agent_type: education_tutor_agent" in result.agent_profile
    assert "quality_score: 90" in result.agent_profile
    assert "rag_enabled: false" in result.agent_profile
    assert "知识讲解、学习路径、复习、错题、练习建议" in result.system_prompt
    assert "必须引用 citation" in result.system_prompt
    assert "knowledge_retrieval" in result.tools
    assert "citation_lookup" in result.tools
    assert result.eval_cases[0].required_citation
    assert result.eval_cases[0].source_path
    assert result.eval_cases[0].chunk_id


def test_agent_template_retrieval_config_uses_rag_files_when_enabled(tmp_path):
    result = make_agent_template(
        output=tmp_path / "package",
        domain="general",
        mode="reference",
        source_count=1,
        chunk_count=1,
        quality_report={"quality_score": 80, "quality_level": "good"},
        cards=[],
        qa_pairs=[],
        glossary=[],
        rag_enabled=True,
        llm_assets_enabled=True,
        options=AgentOptions(enabled=True),
    )

    assert "embedding_input_file: embedding_input.jsonl" in result.retrieval_config
    assert "retrieval_metadata_file: retrieval_metadata.jsonl" in result.retrieval_config
    assert "citation_map_file: citation_map.json" in result.retrieval_config
    assert "fallback_asset_files: []" in result.retrieval_config


def test_agent_template_retrieval_config_uses_base_assets_without_rag(tmp_path):
    result = make_agent_template(
        output=tmp_path / "package",
        domain="general",
        mode="reference",
        source_count=1,
        chunk_count=1,
        quality_report={"quality_score": 80, "quality_level": "good"},
        cards=[],
        qa_pairs=[],
        glossary=[],
        rag_enabled=False,
        llm_assets_enabled=False,
        options=AgentOptions(enabled=True),
    )

    assert "chunks.jsonl" in result.retrieval_config
    assert "cards.jsonl" in result.retrieval_config
    assert "Use --rag-export" in result.retrieval_config


def test_agent_template_prompts_differ_by_agent_type(tmp_path):
    base = dict(
        output=tmp_path / "package",
        domain="general",
        mode="reference",
        source_count=1,
        chunk_count=1,
        quality_report={"quality_score": 80, "quality_level": "good"},
        cards=[],
        qa_pairs=[],
        glossary=[],
        rag_enabled=False,
        llm_assets_enabled=False,
    )
    product = make_agent_template(**base, options=AgentOptions(enabled=True, agent_type="product_manager_agent"))
    shopping = make_agent_template(**base, options=AgentOptions(enabled=True, agent_type="shopping_guide_agent"))

    assert product.system_prompt != shopping.system_prompt
    assert "PRD" in product.system_prompt
    assert "recommendation reasons" in shopping.system_prompt


def test_agent_template_rejects_unsupported_agent_type(tmp_path):
    try:
        make_agent_template(
            output=tmp_path / "package",
            domain="general",
            mode="reference",
            source_count=1,
            chunk_count=1,
            quality_report={},
            cards=[],
            qa_pairs=[],
            glossary=[],
            rag_enabled=False,
            llm_assets_enabled=False,
            options=AgentOptions(enabled=True, agent_type="unknown_agent"),
        )
    except ValueError as exc:
        assert str(exc) == "Unsupported agent type: unknown_agent"
    else:
        raise AssertionError("Expected unsupported agent type error")


def test_eval_cases_are_json_serializable(tmp_path):
    result = make_agent_template(
        output=tmp_path / "package",
        domain="general",
        mode="reference",
        source_count=1,
        chunk_count=1,
        quality_report={"quality_score": 80, "quality_level": "good"},
        cards=[_card()],
        qa_pairs=[_qa()],
        glossary=[_glossary()],
        rag_enabled=False,
        llm_assets_enabled=False,
        options=AgentOptions(enabled=True),
    )

    payload = result.eval_cases[0].model_dump(mode="json")
    assert json.dumps(payload)
    assert payload["required_citation"]


def _card():
    return KnowledgeCard(
        card_id="card-a",
        chunk_id="chunk-a",
        title="Card title",
        summary="Card summary",
        source_path="source.md",
        domain="education",
        mode="teaching",
        citation="source.md#chunk=chunk-a",
    )


def _qa():
    return QAPair(
        qa_id="qa-a",
        chunk_id="chunk-a",
        question="What is the fixture?",
        answer="A fixture.",
        source_path="source.md",
        domain="education",
        mode="teaching",
        citation="source.md#chunk=chunk-a",
    )


def _glossary():
    return {
        "term": "Fixture",
        "definition": "A test item",
        "source_path": "source.md",
        "chunk_id": "chunk-a",
        "citation": "source.md#chunk=chunk-a",
    }
