from __future__ import annotations

import json
from pathlib import Path

from heitang_kb_forge.contracts.package_contract_v2 import AGENT_FILES, MANIFEST_FIELDS, MULTIMODAL_FILES, RAG_FILES, REQUIRED_FILES
from heitang_kb_forge.schemas.package_contract_schema import ContractCheckResult


def check_package_contract(package: Path, *, strict: bool = False) -> ContractCheckResult:
    missing_required = [name for name in REQUIRED_FILES if not (package / name).exists()]
    warnings: list[str] = []
    errors: list[str] = []
    missing_manifest_fields: list[str] = []
    invalid_chunk_fields: list[str] = []
    invalid_evidence_fields: list[str] = []
    missing_conditional: list[str] = []

    manifest = _read_json(package / "manifest.json", errors, "manifest.json")
    chunks = _read_jsonl(package / "chunks.jsonl", errors, "chunks.jsonl")
    evidence = _read_json(package / "evidence_map.json", errors, "evidence_map.json")
    if isinstance(manifest, dict):
        missing_manifest_fields = [field for field in MANIFEST_FIELDS if field not in manifest]
        if missing_manifest_fields:
            warnings.append("Manifest is missing optional Contract v2 fields.")
        if manifest.get("multimodal_status") in {"completed", "partial", "failed"}:
            missing_conditional.extend(name for name in MULTIMODAL_FILES if not (package / name).exists())
        if manifest.get("rag_export_enabled") or manifest.get("rag_status") in {"completed", "partial", "failed"}:
            missing_conditional.extend(name for name in RAG_FILES if not (package / name).exists())
        if manifest.get("agent_template_enabled") or manifest.get("agent_template_status") in {"completed", "partial", "failed"}:
            missing_conditional.extend(name for name in AGENT_FILES if not (package / name).exists())
        if manifest.get("progress_status") == "completed" and not (package / "progress_events.jsonl").exists():
            missing_conditional.append("progress_events.jsonl")
    for index, chunk in enumerate(chunks):
        if not isinstance(chunk, dict):
            invalid_chunk_fields.append(f"line {index + 1}: not an object")
            continue
        if not (chunk.get("chunk_id") and (chunk.get("text") or chunk.get("content"))):
            invalid_chunk_fields.append(f"line {index + 1}: missing chunk_id or text/content")
    if not isinstance(evidence, dict):
        invalid_evidence_fields.append("evidence_map.json must be an object")

    if missing_required or missing_conditional or errors or invalid_chunk_fields or invalid_evidence_fields:
        status = "fail"
    elif strict and missing_manifest_fields:
        status = "fail"
    elif missing_manifest_fields or warnings:
        status = "warning"
    else:
        status = "pass"
    return ContractCheckResult(
        status=status,
        missing_required_files=missing_required,
        missing_conditional_files=sorted(set(missing_conditional)),
        missing_manifest_fields=missing_manifest_fields,
        invalid_chunk_fields=invalid_chunk_fields,
        invalid_evidence_fields=invalid_evidence_fields,
        warnings=warnings,
        errors=errors,
    )


def _read_json(path: Path, errors: list[str], label: str):
    if not path.exists():
        return None
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        errors.append(f"{label} is not readable JSON: {exc}")
        return None


def _read_jsonl(path: Path, errors: list[str], label: str) -> list[dict]:
    if not path.exists():
        return []
    rows = []
    try:
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                rows.append(json.loads(line))
    except Exception as exc:
        errors.append(f"{label} is not readable JSONL: {exc}")
    return rows
