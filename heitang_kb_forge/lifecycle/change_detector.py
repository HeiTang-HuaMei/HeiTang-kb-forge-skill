from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.lifecycle.source_registry import registry_by_relative_path
from heitang_kb_forge.schemas.lifecycle_schema import SourceChangeReport, SourceRecord, SourceRegistry


LIFECYCLE_OUTPUT_FILES = [
    "source_registry.json",
    "source_change_report.md",
    "changed_sources.jsonl",
    "missing_sources.jsonl",
    "new_sources.jsonl",
    "incremental_update_report.md",
    "reused_chunks.jsonl",
    "rebuilt_chunks.jsonl",
    "removed_chunks.jsonl",
    "stale_chunks.jsonl",
    "removed_source_impact_report.md",
    "update_quality_gate_report.json",
    "quality_regression_report.md",
    "failed_sources.jsonl",
    "retry_manifest.json",
    "retry_report.md",
]


def load_source_registry(package: Path | None) -> SourceRegistry | None:
    if not package:
        return None
    path = package / "source_registry.json"
    if not path.exists():
        return None
    return SourceRegistry.model_validate(json.loads(path.read_text(encoding="utf-8")))


def detect_source_changes(
    previous: SourceRegistry | None,
    current: SourceRegistry,
) -> tuple[SourceChangeReport, list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]], list[dict[str, Any]]]:
    previous_by_path = registry_by_relative_path(previous)
    current_by_path = registry_by_relative_path(current)
    changed: list[dict[str, Any]] = []
    missing: list[dict[str, Any]] = []
    new: list[dict[str, Any]] = []
    unchanged: list[dict[str, Any]] = []

    for relative_path, record in current_by_path.items():
        old = previous_by_path.get(relative_path)
        if not old:
            new.append(_source_item(record, "new"))
        elif old.content_hash != record.content_hash:
            changed.append(_source_item(record, "changed", previous_hash=old.content_hash))
        else:
            unchanged.append(_source_item(record, "unchanged"))

    for relative_path, record in previous_by_path.items():
        if relative_path not in current_by_path:
            missing.append(_source_item(record, "missing"))

    warnings = [] if previous else ["Previous source registry missing; treating all current sources as new."]
    report = SourceChangeReport(
        previous_source_count=len(previous_by_path),
        current_source_count=len(current_by_path),
        changed_count=len(changed),
        missing_count=len(missing),
        new_count=len(new),
        unchanged_count=len(unchanged),
        warnings=warnings,
    )
    return report, changed, missing, new, unchanged


def make_incremental_outputs(
    *,
    output: Path,
    previous_package: Path | None,
    changed_sources: list[dict[str, Any]],
    missing_sources: list[dict[str, Any]],
    new_sources: list[dict[str, Any]],
    unchanged_sources: list[dict[str, Any]],
    update_mode: str,
    missing_source_policy: str,
) -> dict[str, Any]:
    current_chunks = _read_jsonl(output / "chunks.jsonl")
    previous_chunks = _read_jsonl(previous_package / "chunks.jsonl") if previous_package else []
    changed_names = {_name(item) for item in changed_sources + new_sources}
    missing_names = {_name(item) for item in missing_sources}
    unchanged_names = {_name(item) for item in unchanged_sources}

    if not previous_chunks:
        rebuilt_chunks = current_chunks
        reused_chunks: list[dict[str, Any]] = []
    else:
        rebuilt_chunks = [chunk for chunk in current_chunks if _chunk_source_name(chunk) in changed_names]
        reused_chunks = [chunk for chunk in previous_chunks if _chunk_source_name(chunk) in unchanged_names]

    removed_chunks = [chunk for chunk in previous_chunks if _chunk_source_name(chunk) in missing_names]
    stale_chunks = removed_chunks if missing_source_policy == "mark_stale" else []
    failed_sources: list[dict[str, Any]] = []
    retry_manifest = {
        "retry_manifest_version": "1.3.0",
        "failed_source_count": 0,
        "failed_sources": [],
        "retry_items": [],
    }
    return {
        "reused_chunks": reused_chunks,
        "rebuilt_chunks": rebuilt_chunks,
        "removed_chunks": removed_chunks,
        "stale_chunks": stale_chunks,
        "failed_sources": failed_sources,
        "retry_manifest": retry_manifest,
        "incremental_report": _incremental_report(
            update_mode,
            missing_source_policy,
            len(reused_chunks),
            len(rebuilt_chunks),
            len(removed_chunks),
            len(stale_chunks),
        ),
        "removed_source_impact_report": _removed_source_impact_report(missing_sources, removed_chunks),
        "retry_report": "# Retry Report\n\n- Failed sources: 0\n",
    }


def make_update_quality_gate(output: Path, previous_package: Path | None) -> tuple[dict[str, Any], str]:
    current = _read_json(output / "quality_report.json")
    previous = _read_json(previous_package / "quality_report.json") if previous_package else {}
    current_score = int(current.get("quality_score", 0) or 0)
    previous_score = previous.get("quality_score")
    warnings: list[str] = []
    status = "pass"
    if current.get("chunk_count", 0) == 0:
        status = "fail"
        warnings.append("current_package_has_no_chunks")
    if previous_score is not None and current_score < int(previous_score) - 10:
        status = "fail"
        warnings.append("quality_score_regressed_more_than_10_points")
    report = {
        "update_quality_gate_version": "1.3.0",
        "status": status,
        "current_quality_score": current_score,
        "previous_quality_score": previous_score,
        "warnings": warnings,
    }
    markdown = "# Quality Regression Report\n\n"
    markdown += f"- Status: {status}\n"
    markdown += f"- Current quality score: {current_score}\n"
    markdown += f"- Previous quality score: {previous_score}\n"
    markdown += "- Warnings:\n" + ("\n".join(f"  - {item}" for item in warnings) if warnings else "  - None") + "\n"
    return report, markdown


def render_source_change_report(report: SourceChangeReport) -> str:
    warnings = "\n".join(f"- {warning}" for warning in report.warnings) or "- None"
    return f"""# Source Change Report

## Summary

- Previous sources: {report.previous_source_count}
- Current sources: {report.current_source_count}
- Changed sources: {report.changed_count}
- Missing sources: {report.missing_count}
- New sources: {report.new_count}
- Unchanged sources: {report.unchanged_count}

## Warnings

{warnings}
"""


def _source_item(record: SourceRecord, status: str, previous_hash: str | None = None) -> dict[str, Any]:
    payload = record.model_dump(mode="json")
    payload["status"] = status
    if previous_hash:
        payload["previous_content_hash"] = previous_hash
    return payload


def _read_json(path: Path) -> dict[str, Any]:
    if not path or not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    if not path or not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _chunk_source_name(chunk: dict[str, Any]) -> str:
    return Path(str(chunk.get("source_path", ""))).name


def _name(source: dict[str, Any]) -> str:
    return Path(str(source.get("source_path", source.get("source_name", "")))).name


def _incremental_report(
    update_mode: str,
    missing_source_policy: str,
    reused_count: int,
    rebuilt_count: int,
    removed_count: int,
    stale_count: int,
) -> str:
    return f"""# Incremental Update Report

## Summary

- Update mode: {update_mode}
- Missing source policy: {missing_source_policy}
- Reused chunks: {reused_count}
- Rebuilt chunks: {rebuilt_count}
- Removed chunks: {removed_count}
- Stale chunks: {stale_count}
"""


def _removed_source_impact_report(missing_sources: list[dict[str, Any]], removed_chunks: list[dict[str, Any]]) -> str:
    missing = "\n".join(f"- {item['relative_path']}" for item in missing_sources) or "- None"
    return f"""# Removed Source Impact Report

## Missing Sources

{missing}

## Impact

- Removed chunks: {len(removed_chunks)}
"""
