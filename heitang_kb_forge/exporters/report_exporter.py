from pathlib import Path

from heitang_kb_forge.schemas.manifest_schema import Manifest


def write_report(
    path: Path,
    manifest: Manifest,
    quality_report: dict | None = None,
    llm_summary: dict | None = None,
    rag_summary: dict | None = None,
) -> None:
    warning_lines = "\n".join(f"- {item}" for item in manifest.warnings) or "- None"
    quality_summary = _quality_summary(quality_report)
    llm_section = f"\n## LLM Summary\n\n{_llm_summary(llm_summary)}\n" if llm_summary else ""
    rag_section = f"\n## RAG Summary\n\n{_rag_summary(rag_summary)}\n" if rag_summary else ""
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
