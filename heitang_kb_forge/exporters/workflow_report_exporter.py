from __future__ import annotations

import hashlib
import json
import re
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Iterable

import yaml


REPORT_EXPORT_SCHEMA_VERSION = "workflow_report_export.v1"
ALLOWED_REPORT_SUFFIXES = {".json", ".md", ".markdown", ".yaml", ".yml"}
RUNTIME_SUFFIXES = {".log", ".jsonl"}
EXCLUDED_DIR_NAMES = {
    "__pycache__",
    ".pytest_cache",
    ".venv",
    "venv",
    "node_modules",
    "input",
    "normalized_sources",
    "model_cache",
    "runtime_cache",
    "cache",
}
FULL_WORKFLOW_REQUIRED_STAGES = [
    "batch_import",
    "document_understanding",
    "knowledge_base",
    "knowledge_package",
    "knowledge_verification",
    "methodology",
    "skill_generation",
    "agent_binding",
    "external_evidence_verification",
]


def export_workflow_report_bundle(
    sources: Iterable[Path],
    output: Path,
    *,
    scope: str = "DU_KB_PACKAGE_SKILL_AGENT_VERIFICATION",
    run_id: str | None = None,
    required_stages: Iterable[str] | None = None,
) -> dict[str, Any]:
    source_roots = [Path(source).resolve() for source in sources]
    if not source_roots:
        raise ValueError("At least one --source directory is required.")
    for source in source_roots:
        if not source.is_dir():
            raise ValueError(f"Source must be a directory: {source}")

    output = output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    reports_dir = output / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)

    copied: list[dict[str, Any]] = []
    skipped: list[dict[str, Any]] = []
    source_labels = _source_labels(source_roots)
    stage_evidence = {stage: [] for stage in FULL_WORKFLOW_REQUIRED_STAGES}

    for source in source_roots:
        label = source_labels[str(source)]
        for path in sorted(source.rglob("*")):
            if not path.is_file():
                continue
            reason = _skip_reason(path, source)
            rel_path = path.relative_to(source).as_posix()
            if reason:
                skipped.append(_skipped_entry(label, rel_path, path, reason))
                continue
            target = reports_dir / label / rel_path
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, target)
            entry = _artifact_entry(label, rel_path, path, target, output)
            copied.append(entry)
            for stage in _stage_matches(label, rel_path, path.name):
                stage_evidence.setdefault(stage, []).append(entry["exported_path"])

    artifact_index = {
        "schema_version": "workflow_report_artifact_index.v1",
        "artifact_count": len(copied),
        "artifacts": copied,
        "skipped_file_count": len(skipped),
        "skipped_files": skipped,
        "governance": {
            "runtime_logs_excluded": all(item["reason"] != "" for item in skipped if item["suffix"] in RUNTIME_SUFFIXES),
            "progress_events_excluded": not any(
                item["relative_path"].endswith("progress_events.jsonl") and item["reason"] != "runtime_stream"
                for item in skipped
            ),
            "raw_input_dirs_excluded": True,
            "normalized_sources_excluded": True,
        },
    }
    (output / "artifact_index.json").write_text(
        json.dumps(artifact_index, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    openability = _openability_check(copied, output)
    (output / "openability_check.json").write_text(
        json.dumps(openability, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    required = list(required_stages) if required_stages is not None else list(FULL_WORKFLOW_REQUIRED_STAGES)
    coverage = {
        stage: {
            "covered": bool(stage_evidence.get(stage)),
            "evidence": stage_evidence.get(stage, []),
        }
        for stage in FULL_WORKFLOW_REQUIRED_STAGES
    }
    missing_required = [stage for stage in required if not coverage.get(stage, {}).get("covered")]
    status = "passed" if copied and openability["status"] == "passed" and not missing_required else "failed"
    created_at = datetime.now(timezone.utc).isoformat()
    manifest = {
        "schema_version": REPORT_EXPORT_SCHEMA_VERSION,
        "status": status,
        "run_id": run_id or _default_run_id(created_at),
        "created_at": created_at,
        "scope": scope,
        "source_roots": [str(source) for source in source_roots],
        "output_dir": str(output),
        "reports_dir": "reports",
        "artifact_index": "artifact_index.json",
        "openability_check": "openability_check.json",
        "summary": "workflow_report_export_summary.md",
        "copied_file_count": len(copied),
        "skipped_file_count": len(skipped),
        "skipped_runtime_file_count": sum(1 for item in skipped if item["suffix"] in RUNTIME_SUFFIXES),
        "required_stages": required,
        "missing_required_stages": missing_required,
        "stage_coverage": coverage,
        "document_output_governance": {
            "runtime_logs_excluded": True,
            "progress_events_excluded": True,
            "raw_runtime_streams_excluded": True,
            "cache_dirs_excluded": True,
            "entrypoints": [
                "workflow_report_export_manifest.json",
                "workflow_report_export_summary.md",
                "artifact_index.json",
                "openability_check.json",
            ],
        },
    }
    (output / "workflow_report_export_manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    (output / "workflow_report_export_summary.md").write_text(
        _summary_markdown(manifest, copied, skipped),
        encoding="utf-8",
    )
    return manifest


def _skip_reason(path: Path, source: Path) -> str | None:
    rel_parts = {part.lower() for part in path.relative_to(source).parts[:-1]}
    if rel_parts & EXCLUDED_DIR_NAMES:
        return "excluded_runtime_or_raw_dir"
    suffix = path.suffix.lower()
    if suffix in RUNTIME_SUFFIXES:
        return "runtime_stream"
    if suffix not in ALLOWED_REPORT_SUFFIXES:
        return "unsupported_report_suffix"
    return None


def _source_labels(sources: list[Path]) -> dict[str, str]:
    used: dict[str, int] = {}
    labels: dict[str, str] = {}
    for source in sources:
        base = _safe_label(source.name or "source")
        count = used.get(base, 0) + 1
        used[base] = count
        labels[str(source)] = base if count == 1 else f"{base}_{count}"
    return labels


def _safe_label(value: str) -> str:
    cleaned = re.sub(r"[^A-Za-z0-9_.-]+", "_", value.strip())
    return cleaned.strip("._") or "source"


def _sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def _artifact_entry(label: str, rel_path: str, source: Path, target: Path, output: Path) -> dict[str, Any]:
    return {
        "source_label": label,
        "relative_path": rel_path,
        "source_path": str(source),
        "exported_path": target.relative_to(output).as_posix(),
        "suffix": source.suffix.lower(),
        "size_bytes": source.stat().st_size,
        "sha256": _sha256(source),
        "artifact_type": _artifact_type(source.name),
    }


def _skipped_entry(label: str, rel_path: str, source: Path, reason: str) -> dict[str, Any]:
    return {
        "source_label": label,
        "relative_path": rel_path,
        "source_path": str(source),
        "suffix": source.suffix.lower(),
        "size_bytes": source.stat().st_size,
        "reason": reason,
    }


def _artifact_type(name: str) -> str:
    lower = name.lower()
    if "manifest" in lower:
        return "manifest"
    if "report" in lower:
        return "report"
    if "trace" in lower:
        return "trace"
    if "map" in lower:
        return "map"
    if "inventory" in lower:
        return "inventory"
    if "recommendation" in lower:
        return "recommendation"
    if "profile" in lower or "config" in lower:
        return "configuration"
    if lower in {"suite.json", "agent_profile.yaml"}:
        return "package_descriptor"
    return "report_artifact"


def _stage_matches(label: str, rel_path: str, name: str) -> set[str]:
    haystack = f"{label}/{rel_path}/{name}".lower()
    stages: set[str] = set()
    if "batch_import" in haystack or "document_preflight" in haystack or "backend_recommendation" in haystack:
        stages.add("batch_import")
    if "document_understanding" in haystack or "parser_backend_" in haystack:
        stages.add("document_understanding")
    if "knowledge_base" in haystack or "retrieval_manifest" in haystack or "evidence_map" in haystack:
        stages.add("knowledge_base")
    if "knowledge_package" in haystack or "artifact_inventory" in haystack:
        stages.add("knowledge_package")
    if "knowledge_verification" in haystack or "claim_verification_report" in haystack:
        stages.add("knowledge_verification")
    if "methodology" in haystack or "methodology_map" in haystack:
        stages.add("methodology")
    if "skill_generation" in haystack or "skill_plan" in haystack or "skill_suite" in haystack or "skill_pack" in haystack:
        stages.add("skill_generation")
    if "agent_binding" in haystack or "agent_package" in haystack or "local_agent_runtime" in haystack:
        stages.add("agent_binding")
    if "agent_output_verification" in haystack or "external_evidence" in haystack:
        stages.add("external_evidence_verification")
    return stages


def _openability_check(artifacts: list[dict[str, Any]], output: Path) -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    for artifact in artifacts:
        exported = output / artifact["exported_path"]
        suffix = artifact["suffix"]
        try:
            text = exported.read_text(encoding="utf-8-sig")
            if suffix == ".json":
                json.loads(text)
            elif suffix in {".yaml", ".yml"}:
                yaml.safe_load(text)
            elif suffix in {".md", ".markdown"} and not text.strip():
                raise ValueError("Markdown report is empty.")
            checks.append({"path": artifact["exported_path"], "status": "passed", "suffix": suffix})
        except Exception as exc:  # noqa: BLE001 - persisted diagnostic should capture parser failure.
            checks.append(
                {
                    "path": artifact["exported_path"],
                    "status": "failed",
                    "suffix": suffix,
                    "error": str(exc),
                }
            )
    failed = [item for item in checks if item["status"] != "passed"]
    return {
        "schema_version": "workflow_report_openability_check.v1",
        "status": "passed" if checks and not failed else "failed",
        "checked_count": len(checks),
        "failed_count": len(failed),
        "checks": checks,
    }


def _default_run_id(created_at: str) -> str:
    compact = re.sub(r"[^0-9]", "", created_at)[:14]
    return f"workflow_report_export_{compact}"


def _summary_markdown(manifest: dict[str, Any], copied: list[dict[str, Any]], skipped: list[dict[str, Any]]) -> str:
    coverage_lines = "\n".join(
        f"- {stage}: {'covered' if data['covered'] else 'missing'} ({len(data['evidence'])} artifacts)"
        for stage, data in manifest["stage_coverage"].items()
    )
    sample_lines = "\n".join(
        f"- `{item['exported_path']}`"
        for item in copied[:20]
    ) or "- None"
    return f"""# Workflow Report Export Summary

## Status

- Status: `{manifest['status']}`
- Run ID: `{manifest['run_id']}`
- Scope: `{manifest['scope']}`
- Copied report artifacts: {manifest['copied_file_count']}
- Skipped files: {manifest['skipped_file_count']}
- Skipped runtime files: {manifest['skipped_runtime_file_count']}
- Missing required stages: {', '.join(manifest['missing_required_stages']) or 'None'}

## Stage Coverage

{coverage_lines}

## Governance

- Runtime logs excluded: true
- Progress events excluded: true
- Raw runtime streams excluded: true
- Cache directories excluded: true
- Raw input and normalized source directories excluded: true

## Entry Points

- `workflow_report_export_manifest.json`
- `artifact_index.json`
- `openability_check.json`
- `reports/`

## Sample Artifacts

{sample_lines}

## Notes

This export proves only governed report export for the supplied workflow evidence. It does not prove desktop UI completion, configuration completion, Full Gate completion, EXE packaging, push, tag, or release.
"""
