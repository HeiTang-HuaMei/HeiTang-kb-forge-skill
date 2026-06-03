from datetime import datetime, timezone
from pathlib import Path

from heitang_kb_forge.agent.templates import AGENT_DESCRIPTIONS, AGENT_OUTPUT_FILES, validate_agent_type
from heitang_kb_forge.schemas.agent_schema import AgentOptions, AgentTemplateResult, EvalCase
from heitang_kb_forge.schemas.card_schema import KnowledgeCard
from heitang_kb_forge.schemas.qa_schema import QAPair


def make_agent_template(
    *,
    output: Path,
    domain: str,
    mode: str,
    source_count: int,
    chunk_count: int,
    quality_report: dict,
    cards: list[KnowledgeCard],
    qa_pairs: list[QAPair],
    glossary: list[dict],
    rag_enabled: bool,
    llm_assets_enabled: bool,
    options: AgentOptions,
) -> AgentTemplateResult:
    validate_agent_type(options.agent_type)
    agent_name = options.agent_name or _default_agent_name(output)
    description = AGENT_DESCRIPTIONS[options.agent_type]
    created_at = datetime.now(timezone.utc).isoformat()
    eval_cases = _make_eval_cases(options.agent_type, qa_pairs, cards, glossary)

    return AgentTemplateResult(
        output_files=list(AGENT_OUTPUT_FILES),
        agent_profile=_agent_profile(
            agent_name,
            options,
            description,
            domain,
            mode,
            source_count,
            chunk_count,
            quality_report,
            rag_enabled,
            llm_assets_enabled,
            created_at,
        ),
        system_prompt=_system_prompt(options.agent_type, description, options.language),
        retrieval_config=_retrieval_config(rag_enabled),
        tools=_tools_yaml(),
        eval_cases=eval_cases,
    )


def _agent_profile(
    agent_name: str,
    options: AgentOptions,
    description: str,
    domain: str,
    mode: str,
    source_count: int,
    chunk_count: int,
    quality_report: dict,
    rag_enabled: bool,
    llm_assets_enabled: bool,
    created_at: str,
) -> str:
    return f"""agent_name: {agent_name}
agent_type: {options.agent_type}
language: {options.language}
domain: {domain}
mode: {mode}
description: {description}
knowledge_package_version: 0.7.0
source_count: {source_count}
chunk_count: {chunk_count}
quality_score: {quality_report.get("quality_score")}
quality_level: {quality_report.get("quality_level")}
rag_enabled: {_yaml_bool(rag_enabled)}
llm_assets_enabled: {_yaml_bool(llm_assets_enabled)}
created_at: {created_at}
"""


def _system_prompt(agent_type: str, description: str, language: str) -> str:
    return f"""# System Prompt

You are a {description}.

Agent type: {agent_type}
Language: {language}

## Operating Rules

- 只能基于知识库和检索结果回答。
- 必须引用 citation。
- 知识不足时说明不足，不编造。
- 明确回答边界。

## Role Focus

{_role_focus(agent_type)}
"""


def _role_focus(agent_type: str) -> str:
    focuses = {
        "generic_agent": "Provide grounded answers from the knowledge package.",
        "product_manager_agent": "Focus on requirements, PRD thinking, competitors, metrics, and user scenarios.",
        "shopping_guide_agent": "Focus on product knowledge, selling points, suitable users, recommendation reasons, and comparisons.",
        "education_tutor_agent": "Focus on explanations, learning paths, review guidance, mistakes, and practice suggestions.",
        "customer_service_agent": "Focus on FAQ, policies, processes, after-sales guidance, and clear boundaries.",
        "interview_coach_agent": "Focus on mock interviews, follow-up questions, scoring, and answer improvement.",
        "operations_agent": "Focus on user tags, outreach strategy, campaign operations, and conversion paths.",
    }
    return focuses[agent_type]


def _retrieval_config(rag_enabled: bool) -> str:
    if rag_enabled:
        source_files = """embedding_input_file: embedding_input.jsonl
retrieval_metadata_file: retrieval_metadata.jsonl
citation_map_file: citation_map.json
fallback_asset_files: []"""
    else:
        source_files = """embedding_input_file: null
retrieval_metadata_file: null
citation_map_file: null
fallback_asset_files:
  - chunks.jsonl
  - cards.jsonl
  - qa_pairs.jsonl
  - glossary.jsonl
note: Use --rag-export to generate standardized RAG input files."""
    return f"""retrieval_mode: basic
{source_files}
top_k: 5
asset_types:
  - chunk
  - card
  - qa_pair
  - glossary
require_citation: true
fallback_when_no_context: say_insufficient_context
rerank_enabled: false
hybrid_search_enabled: false
"""


def _tools_yaml() -> str:
    tools = [
        ("knowledge_retrieval", "knowledge_retrieval", "Retrieve relevant knowledge package records.", True),
        ("citation_lookup", "citation_lookup", "Look up citations and source references.", True),
        ("quality_check", "quality_check", "Check quality level and package warnings.", True),
        ("human_handoff", "human_handoff", "Escalate when knowledge is insufficient or out of scope.", False),
        ("product_lookup_placeholder", "product_lookup_placeholder", "Placeholder for product catalog lookup.", True),
        ("crm_lookup_placeholder", "crm_lookup_placeholder", "Placeholder for CRM lookup.", True),
        ("order_lookup_placeholder", "order_lookup_placeholder", "Placeholder for order lookup.", True),
    ]
    lines = ["tools:"]
    for name, tool_type, description, runtime_required in tools:
        lines.extend(
            [
                f"  - name: {name}",
                f"    type: {tool_type}",
                f"    description: {description}",
                "    enabled: true",
                f"    runtime_required: {_yaml_bool(runtime_required)}",
                "    input_schema:",
                "      type: object",
                "      properties: {}",
                "    output_schema:",
                "      type: object",
                "      properties: {}",
                "    safety_notes:",
                "      - Tool configuration only; no runtime execution is performed by KB Forge.",
                "    config: {}",
            ]
        )
    return "\n".join(lines) + "\n"


def _make_eval_cases(agent_type: str, qa_pairs: list[QAPair], cards: list[KnowledgeCard], glossary: list[dict]) -> list[EvalCase]:
    cases: list[EvalCase] = []
    for pair in qa_pairs[:3]:
        cases.append(
            EvalCase(
                eval_id=f"eval_{len(cases) + 1}",
                question=pair.question,
                expected_behavior="Answer using the knowledge package and cite the source.",
                required_citation=pair.citation or _citation(pair.source_path, pair.chunk_id),
                source_path=pair.source_path,
                chunk_id=pair.chunk_id,
                agent_type=agent_type,
            )
        )
    for card in cards:
        if len(cases) >= 3:
            break
        cases.append(
            EvalCase(
                eval_id=f"eval_{len(cases) + 1}",
                question=f"What should the agent know about {card.title}?",
                expected_behavior="Explain the knowledge card and cite the source.",
                required_citation=card.citation or _citation(card.source_path, card.chunk_id),
                source_path=card.source_path,
                chunk_id=card.chunk_id,
                agent_type=agent_type,
            )
        )
    for item in glossary:
        if len(cases) >= 3:
            break
        term = str(item.get("term", "")).strip()
        if not term:
            continue
        cases.append(
            EvalCase(
                eval_id=f"eval_{len(cases) + 1}",
                question=f"What does {term} mean?",
                expected_behavior="Define the term using the knowledge package and cite the source.",
                required_citation=str(item.get("citation") or _citation(str(item.get("source_path", "")), str(item.get("chunk_id", "")))),
                source_path=str(item.get("source_path", "")),
                chunk_id=str(item.get("chunk_id", "")),
                agent_type=agent_type,
            )
        )
    return cases


def _default_agent_name(output: Path) -> str:
    return f"{output.name or 'knowledge'}_agent"


def _citation(source_path: str, chunk_id: str) -> str:
    return f"{source_path}#chunk={chunk_id}"


def _yaml_bool(value: bool) -> str:
    return "true" if value else "false"
