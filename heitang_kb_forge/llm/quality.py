from collections import Counter
import re
from typing import Any

from heitang_kb_forge.llm.extractor import LLMOptions, OUTPUT_FILES
from heitang_kb_forge.schemas.llm_quality_schema import LLMQualityReport, LLMQualityResult

LLM_QUALITY_OUTPUT_FILES = ["llm_quality_report.json", "llm_quality_summary.md"]


def make_llm_quality_report(outputs: dict[str, list[dict]], options: LLMOptions) -> LLMQualityResult:
    records = [(asset_type, record) for asset_type, items in outputs.items() for record in items]
    total = len(records)
    asset_type_counts = Counter(asset_type for asset_type, _ in records)
    empty_output_count = sum(1 for _, record in records if not _record_text(record))
    missing_citation_count = _missing_count(records, "citation")
    missing_source_path_count = _missing_count(records, "source_path")
    missing_chunk_id_count = _missing_count(records, "chunk_id")
    missing_confidence_count = _missing_count(records, "confidence")
    missing_token_usage_count = _missing_count(records, "token_usage")
    missing_cache_key_count = _missing_count(records, "cache_key")
    duplicate_count = _duplicate_count(records)
    schema_warning_count = 0
    warnings = _warnings(
        total,
        empty_output_count,
        duplicate_count,
        missing_citation_count,
        missing_source_path_count,
        missing_chunk_id_count,
        asset_type_counts,
    )
    groundedness_proxy_score = _clamp(100 - 3 * (missing_citation_count + missing_source_path_count + missing_chunk_id_count))
    completeness_proxy_score = _clamp(100 - 5 * len([name for name in OUTPUT_FILES if asset_type_counts.get(name, 0) == 0]))
    metadata_coverage_score = _clamp(
        100 - 2 * (missing_confidence_count + missing_token_usage_count + missing_cache_key_count)
    )
    llm_quality_score = _clamp(
        100
        - 5 * empty_output_count
        - 3 * duplicate_count
        - 3 * (missing_citation_count + missing_source_path_count + missing_chunk_id_count)
        - 2 * (missing_confidence_count + missing_token_usage_count + missing_cache_key_count)
        - 2 * schema_warning_count
        - 5 * len([name for name in OUTPUT_FILES if asset_type_counts.get(name, 0) == 0])
    )
    report = LLMQualityReport(
        provider=options.provider,
        model=options.model,
        prompt_profile=options.prompt_profile.profile_name if options.prompt_profile else None,
        prompt_profile_hash=options.prompt_profile_hash,
        total_llm_records=total,
        asset_type_counts=dict(asset_type_counts),
        empty_output_count=empty_output_count,
        missing_citation_count=missing_citation_count,
        missing_source_path_count=missing_source_path_count,
        missing_chunk_id_count=missing_chunk_id_count,
        missing_confidence_count=missing_confidence_count,
        missing_token_usage_count=missing_token_usage_count,
        duplicate_count=duplicate_count,
        schema_warning_count=schema_warning_count,
        citation_coverage=_coverage(total - missing_citation_count, total),
        source_path_coverage=_coverage(total - missing_source_path_count, total),
        chunk_id_coverage=_coverage(total - missing_chunk_id_count, total),
        confidence_coverage=_coverage(total - missing_confidence_count, total),
        token_usage_coverage=_coverage(total - missing_token_usage_count, total),
        cache_key_coverage=_coverage(total - missing_cache_key_count, total),
        groundedness_proxy_score=groundedness_proxy_score,
        completeness_proxy_score=completeness_proxy_score,
        metadata_coverage_score=metadata_coverage_score,
        llm_quality_score=llm_quality_score,
        llm_quality_level=_quality_level(llm_quality_score),
        warnings=warnings,
    )
    return LLMQualityResult(
        output_files=LLM_QUALITY_OUTPUT_FILES,
        report=report,
        summary=_render_summary(report),
    )


def _missing_count(records: list[tuple[str, dict]], field: str) -> int:
    return sum(1 for _, record in records if record.get(field) in (None, "", [], {}))


def _duplicate_count(records: list[tuple[str, dict]]) -> int:
    seen: set[tuple[str, str]] = set()
    duplicates = 0
    for asset_type, record in records:
        key = (asset_type, _normalize(_record_text(record)))
        if not key[1]:
            continue
        if key in seen:
            duplicates += 1
        seen.add(key)
    return duplicates


def _record_text(record: dict) -> str:
    fields = [
        "title",
        "summary",
        "question",
        "answer",
        "term",
        "definition",
        "name",
        "case_summary",
    ]
    return " ".join(str(record.get(field, "")).strip() for field in fields if str(record.get(field, "")).strip())


def _normalize(value: str) -> str:
    return re.sub(r"\s+", " ", value.strip().lower())


def _coverage(count: int, total: int) -> float:
    return round(count / total, 4) if total else 0.0


def _clamp(value: int) -> int:
    return max(0, min(100, value))


def _quality_level(score: int) -> str:
    if score >= 90:
        return "excellent"
    if score >= 75:
        return "good"
    if score >= 60:
        return "warning"
    return "poor"


def _warnings(
    total: int,
    empty_output_count: int,
    duplicate_count: int,
    missing_citation_count: int,
    missing_source_path_count: int,
    missing_chunk_id_count: int,
    asset_type_counts: Counter,
) -> list[str]:
    warnings: list[str] = []
    if total == 0:
        warnings.append("No LLM records generated")
    if empty_output_count:
        warnings.append(f"Empty LLM outputs detected: {empty_output_count}")
    if duplicate_count:
        warnings.append(f"Duplicate LLM outputs detected: {duplicate_count}")
    if missing_citation_count or missing_source_path_count or missing_chunk_id_count:
        warnings.append("Some LLM records are missing source grounding metadata")
    missing_assets = [name for name in OUTPUT_FILES if asset_type_counts.get(name, 0) == 0]
    if missing_assets:
        warnings.append(f"Missing expected LLM asset types: {', '.join(missing_assets)}")
    return warnings


def _render_summary(report: LLMQualityReport) -> str:
    counts = "\n".join(f"- {key}: {value}" for key, value in report.asset_type_counts.items()) or "- None"
    warnings = "\n".join(f"- {warning}" for warning in report.warnings) or "- None"
    return f"""# LLM Quality Summary

## Provider / Model / Prompt Profile

- Provider: {report.provider}
- Model: {report.model}
- Prompt profile: {report.prompt_profile or 'None'}

## Asset Counts

- Total LLM records: {report.total_llm_records}
{counts}

## Metadata Coverage

- Source path coverage: {report.source_path_coverage}
- Chunk ID coverage: {report.chunk_id_coverage}
- Confidence coverage: {report.confidence_coverage}
- Token usage coverage: {report.token_usage_coverage}
- Cache key coverage: {report.cache_key_coverage}

## Citation Coverage

- Citation coverage: {report.citation_coverage}

## Duplicate And Empty Output Warnings

- Empty output count: {report.empty_output_count}
- Duplicate count: {report.duplicate_count}

## Quality Score

- LLM quality score: {report.llm_quality_score}
- LLM quality level: {report.llm_quality_level}
- Groundedness proxy score: {report.groundedness_proxy_score}
- Completeness proxy score: {report.completeness_proxy_score}
- Metadata coverage score: {report.metadata_coverage_score}

## Warnings

{warnings}

## Boundaries

- This is a rule-based proxy evaluation.
- No real semantic scoring.
- No LLM judge.
- No network call.
"""
