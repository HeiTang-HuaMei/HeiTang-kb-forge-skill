from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path

from heitang_kb_forge.document_generation.citations import Evidence, evidence_from_chunks
from heitang_kb_forge.parser_backends.trust_gate import read_kb_trust_status, trust_gate_result

GROUNDING_POLICIES = {"strict_grounded", "creative_grounded"}


@dataclass(frozen=True)
class DocumentPlan:
    package: Path
    title: str
    template: str
    grounding_policy: str
    trust_status: str
    trust_gate: dict
    review_required: bool
    chunks: list[dict]
    cards: list[dict]
    evidence: list[Evidence]
    warnings: list[str]


def plan_document_generation(
    package: Path,
    template: str,
    grounding_policy: str,
    title: str | None = None,
) -> DocumentPlan:
    if grounding_policy not in GROUNDING_POLICIES:
        raise ValueError(f"Unsupported grounding policy: {grounding_policy}")
    if not package.exists() or not package.is_dir():
        raise FileNotFoundError(f"Package not found: {package}")

    chunks = _read_jsonl(package / "chunks.jsonl")
    if not chunks:
        raise ValueError("Document generation requires a package with chunks.jsonl records")

    cards = _read_jsonl(package / "cards.jsonl")
    trust_status = read_kb_trust_status(package)
    trust_gate = _read_trust_gate(package) or trust_gate_result(trust_status, allow_untrusted=False)
    warnings = list(trust_gate.get("warnings") or [])
    blocked = trust_gate.get("blocked") is True or trust_gate.get("status") == "fail"

    if blocked and grounding_policy == "strict_grounded":
        raise ValueError(f"strict_grounded document generation blocked by trusted_kb_gate: {trust_status}")
    review_required = bool(blocked)
    if review_required:
        warnings.append("creative_grounded_generation_requires_human_review")

    evidence = evidence_from_chunks(chunks)
    if not evidence:
        raise ValueError("Document generation requires non-empty chunk text for citations")

    return DocumentPlan(
        package=package,
        title=title or _default_title(package),
        template=template,
        grounding_policy=grounding_policy,
        trust_status=trust_status,
        trust_gate=trust_gate,
        review_required=review_required,
        chunks=chunks,
        cards=cards,
        evidence=evidence,
        warnings=warnings,
    )


def _default_title(package: Path) -> str:
    manifest_path = package / "manifest.json"
    if manifest_path.exists():
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            domain = manifest.get("domain")
            mode = manifest.get("mode")
            if domain and mode:
                return f"{domain} {mode} document"
        except json.JSONDecodeError:
            pass
    return package.name.replace("_", " ").replace("-", " ").title()


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    rows = []
    for line in path.read_text(encoding="utf-8").splitlines():
        if line.strip():
            rows.append(json.loads(line))
    return rows


def _read_trust_gate(package: Path) -> dict | None:
    path = package / "trusted_kb_gate.json"
    if not path.exists():
        return None
    try:
        payload = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {"status": "fail", "blocked": True, "warnings": ["trusted_kb_gate_json_invalid"]}
    return payload if isinstance(payload, dict) else None
