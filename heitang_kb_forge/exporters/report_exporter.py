from pathlib import Path

from heitang_kb_forge.schemas.manifest_schema import Manifest


def write_report(
    path: Path,
    manifest: Manifest,
    quality_report: dict | None = None,
    llm_summary: dict | None = None,
    rag_summary: dict | None = None,
    agent_summary: dict | None = None,
    demo_summary: dict | None = None,
    llm_quality_summary: dict | None = None,
    embedding_summary: dict | None = None,
    vector_summary: dict | None = None,
) -> None:
    warning_lines = "\n".join(f"- {item}" for item in manifest.warnings) or "- None"
    quality_summary = _quality_summary(quality_report)
    llm_section = f"\n## LLM Summary\n\n{_llm_summary(llm_summary)}\n" if llm_summary else ""
    rag_section = f"\n## RAG Summary\n\n{_rag_summary(rag_summary)}\n" if rag_summary else ""
    agent_section = f"\n## Agent Template Summary\n\n{_agent_summary(agent_summary)}\n" if agent_summary else ""
    demo_section = f"\n## Demo Summary\n\n{_demo_summary(demo_summary)}\n" if demo_summary else ""
    llm_quality_section = (
        f"\n## LLM Quality Summary\n\n{_llm_quality_summary(llm_quality_summary)}\n"
        if llm_quality_summary
        else ""
    )
    embedding_section = f"\n## Embedding Summary\n\n{_embedding_summary(embedding_summary)}\n" if embedding_summary else ""
    vector_section = f"\n## Vector Export Summary\n\n{_vector_summary(vector_summary)}\n" if vector_summary else ""
    content = f"""# KB Forge Ingest Report

## Summary

- Domain: {manifest.domain}
- Mode: {manifest.mode}
- Sources: {manifest.source_count}
- Chunks: {manifest.chunk_count}
- Cards: {manifest.card_count}
- QA pairs: {manifest.qa_pair_count}
- Glossary terms: {manifest.glossary_count}

## Quality Summary

{quality_summary}
{llm_section}
{rag_section}
{agent_section}
{demo_section}
{llm_quality_section}
{embedding_section}
{vector_section}

## Output Files

{chr(10).join(f"- {name}" for name in manifest.files)}

## Warnings

{warning_lines}
"""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def _quality_summary(quality_report: dict | None) -> str:
    if not quality_report:
        return "- Not available"
    warning_lines = "\n".join(f"  - {warning}" for warning in quality_report["warnings"]) or "  - None"
    return f"""- Chunks: {quality_report['chunk_count']}
- Cards: {quality_report['card_count']}
- QA pairs: {quality_report['qa_count']}
- Glossary terms: {quality_report['glossary_count']}
- Quality score: {quality_report['quality_score']}
- Quality level: {quality_report['quality_level']}
- Warnings:
{warning_lines}"""


def _llm_summary(llm_summary: dict | None) -> str:
    if not llm_summary:
        return "- Enabled: False"
    output_files = "\n".join(f"  - {name}" for name in llm_summary["output_files"]) or "  - None"
    return f"""- Enabled: {llm_summary['enabled']}
- Provider: {llm_summary['provider']}
- Model: {llm_summary['model']}
- Prompt profile: {llm_summary.get('prompt_profile') or 'None'}
- Output files:
{output_files}
- Warnings count: {llm_summary['warnings_count']}"""


def _rag_summary(rag_summary: dict | None) -> str:
    if not rag_summary:
        return "- Enabled: False"
    output_files = "\n".join(f"  - {name}" for name in rag_summary["output_files"]) or "  - None"
    counts = "\n".join(f"  - {key}: {value}" for key, value in rag_summary["asset_type_counts"].items()) or "  - None"
    return f"""- Enabled: {rag_summary['enabled']}
- Profile: {rag_summary['profile']}
- Include LLM: {rag_summary['include_llm']}
- Output files:
{output_files}
- Total records: {rag_summary['total_records']}
- Asset type counts:
{counts}"""


def _agent_summary(agent_summary: dict | None) -> str:
    if not agent_summary:
        return "- Enabled: False"
    output_files = "\n".join(f"  - {name}" for name in agent_summary["output_files"]) or "  - None"
    return f"""- Enabled: {agent_summary['enabled']}
- Agent type: {agent_summary['agent_type']}
- Agent name: {agent_summary['agent_name']}
- Language: {agent_summary['language']}
- Output files:
{output_files}"""


def _demo_summary(demo_summary: dict | None) -> str:
    if not demo_summary:
        return "- Enabled: False"
    output_files = "\n".join(f"  - {name}" for name in demo_summary["output_files"]) or "  - None"
    return f"""- Enabled: {demo_summary['enabled']}
- Final status: {demo_summary['final_status']}
- Quality score: {demo_summary['quality_score']}
- Quality level: {demo_summary['quality_level']}
- Warnings count: {demo_summary['warnings_count']}
- Output files:
{output_files}"""


def _llm_quality_summary(llm_quality_summary: dict | None) -> str:
    if not llm_quality_summary:
        return "- Enabled: False"
    output_files = "\n".join(f"  - {name}" for name in llm_quality_summary["output_files"]) or "  - None"
    return f"""- Enabled: {llm_quality_summary['enabled']}
- LLM quality score: {llm_quality_summary['llm_quality_score']}
- LLM quality level: {llm_quality_summary['llm_quality_level']}
- Warnings count: {llm_quality_summary['warnings_count']}
- Output files:
{output_files}"""


def _embedding_summary(embedding_summary: dict | None) -> str:
    if not embedding_summary:
        return "- Enabled: False"
    output_files = "\n".join(f"  - {name}" for name in embedding_summary["output_files"]) or "  - None"
    return f"""- Enabled: {embedding_summary['enabled']}
- Provider: {embedding_summary['provider']}
- Model: {embedding_summary['model']}
- Total records: {embedding_summary['total_records']}
- Warnings count: {embedding_summary['warnings_count']}
- Output files:
{output_files}"""


def _vector_summary(vector_summary: dict | None) -> str:
    if not vector_summary:
        return "- Enabled: False"
    output_files = "\n".join(f"  - {name}" for name in vector_summary["output_files"]) or "  - None"
    return f"""- Enabled: {vector_summary['enabled']}
- Store: {vector_summary['store']}
- Total records: {vector_summary['total_records']}
- Warnings count: {vector_summary['warnings_count']}
- Output files:
{output_files}"""
