from pathlib import Path
from typing import Any

from heitang_kb_forge.schemas.eval_schema import DemoManifest, DemoResult, EvalSummary

DEMO_OUTPUT_FILES = [
    "demo_report.md",
    "demo_manifest.json",
    "eval_summary.json",
]


def make_demo_report(
    *,
    package_path: Path,
    domain: str,
    mode: str,
    source_count: int,
    chunks: list[Any],
    cards: list[Any],
    qa_pairs: list[Any],
    glossary: list[Any],
    quality_report: dict,
    rag_export_enabled: bool,
    agent_template_enabled: bool,
    eval_cases: list[Any] | None = None,
) -> DemoResult:
    eval_cases = eval_cases or []
    warnings = _make_warnings(
        quality_report,
        cards,
        qa_pairs,
        glossary,
        rag_export_enabled,
        agent_template_enabled,
        eval_cases,
    )
    failures = _make_failures(chunks, quality_report)
    final_status = "fail" if failures else "warning" if warnings else "pass"
    all_warnings = failures + warnings
    eval_summary = _make_eval_summary(eval_cases, final_status, all_warnings)
    demo_manifest = DemoManifest(
        package_path=str(package_path).replace("\\", "/"),
        domain=domain,
        mode=mode,
        source_count=source_count,
        chunk_count=len(chunks),
        quality_score=quality_report.get("quality_score"),
        quality_level=quality_report.get("quality_level"),
        rag_export_enabled=rag_export_enabled,
        agent_template_enabled=agent_template_enabled,
        eval_cases_count=len(eval_cases),
        final_status=final_status,
        warnings=all_warnings,
    )
    return DemoResult(
        output_files=DEMO_OUTPUT_FILES,
        demo_report=_render_demo_report(
            demo_manifest,
            eval_summary,
            cards,
            qa_pairs,
            glossary,
        ),
        demo_manifest=demo_manifest,
        eval_summary=eval_summary,
    )


def _make_warnings(
    quality_report: dict,
    cards: list[Any],
    qa_pairs: list[Any],
    glossary: list[Any],
    rag_export_enabled: bool,
    agent_template_enabled: bool,
    eval_cases: list[Any],
) -> list[str]:
    warnings: list[str] = []
    if (quality_report.get("quality_score") or 0) < 60:
        warnings.append("Quality score is below 60")
    if not cards:
        warnings.append("No cards generated")
    if not qa_pairs:
        warnings.append("No QA pairs generated")
    if not glossary:
        warnings.append("No glossary terms generated")
    if not rag_export_enabled:
        warnings.append("RAG export is not enabled")
    if not agent_template_enabled:
        warnings.append("Agent Template is not enabled")
    if not eval_cases:
        warnings.append("No eval cases generated")
    return warnings


def _make_failures(chunks: list[Any], quality_report: dict | None) -> list[str]:
    failures: list[str] = []
    if quality_report is None:
        failures.append("quality_report.json is missing")
    if not chunks:
        failures.append("chunk_count is 0")
    return failures


def _make_eval_summary(eval_cases: list[Any], status: str, warnings: list[str]) -> EvalSummary:
    required_citation_count = sum(1 for item in eval_cases if _get_value(item, "required_citation"))
    source_path_count = sum(1 for item in eval_cases if _get_value(item, "source_path"))
    chunk_id_count = sum(1 for item in eval_cases if _get_value(item, "chunk_id"))
    total = len(eval_cases)
    return EvalSummary(
        eval_cases_file="eval_cases.jsonl" if total else None,
        eval_cases_count=total,
        required_citation_count=required_citation_count,
        source_path_coverage=_coverage(source_path_count, total),
        chunk_id_coverage=_coverage(chunk_id_count, total),
        status=status,
        warnings=warnings,
    )


def _coverage(count: int, total: int) -> float:
    return round(count / total, 4) if total else 0.0


def _get_value(item: Any, key: str) -> Any:
    if isinstance(item, dict):
        return item.get(key)
    return getattr(item, key, None)


def _render_demo_report(
    demo_manifest: DemoManifest,
    eval_summary: EvalSummary,
    cards: list[Any],
    qa_pairs: list[Any],
    glossary: list[Any],
) -> str:
    warnings = "\n".join(f"- {warning}" for warning in demo_manifest.warnings) or "- None"
    return f"""# HeiTang KB Forge Demo Report

## Package Summary

- Domain: {demo_manifest.domain}
- Mode: {demo_manifest.mode}
- Sources: {demo_manifest.source_count}
- Chunks: {demo_manifest.chunk_count}

## Quality Summary

- Quality score: {demo_manifest.quality_score}
- Quality level: {demo_manifest.quality_level}
- Warnings:
{warnings}

## Asset Coverage

- Cards: {len(cards)}
- QA pairs: {len(qa_pairs)}
- Glossary terms: {len(glossary)}

## RAG Export Status

- Enabled: {demo_manifest.rag_export_enabled}

## Agent Template Status

- Enabled: {demo_manifest.agent_template_enabled}

## Eval Case Summary

- Eval cases: {eval_summary.eval_cases_count}
- Required citations: {eval_summary.required_citation_count}
- Source path coverage: {eval_summary.source_path_coverage}
- Chunk ID coverage: {eval_summary.chunk_id_coverage}

## Readiness Checklist

- Critical files present: {demo_manifest.final_status != "fail"}
- Chunks available: {demo_manifest.chunk_count > 0}
- Quality report available: {demo_manifest.quality_score is not None}
- RAG export ready: {demo_manifest.rag_export_enabled}
- Agent template ready: {demo_manifest.agent_template_enabled}

## Final Status

{demo_manifest.final_status}
"""
