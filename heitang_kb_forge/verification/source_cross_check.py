from __future__ import annotations

import json
import re
from pathlib import Path


def load_verification_sources(package: Path, verification_sources: list[Path] | None = None) -> list[dict]:
    rows: list[dict] = []
    for path in verification_sources or []:
        rows.extend(_load_source_file(path))
    for source_file in ["chunks.jsonl", "cards.jsonl", "qa_pairs.jsonl"]:
        for row in _read_jsonl(package / source_file):
            text = str(row.get("text") or row.get("summary") or row.get("answer") or "")
            if text:
                rows.append(
                    {
                        "source_id": row.get("chunk_id") or f"{source_file}_{len(rows) + 1}",
                        "source_path": row.get("source_path", source_file),
                        "text": text,
                        "date": row.get("date") or row.get("metadata", {}).get("date") if isinstance(row.get("metadata"), dict) else None,
                        "trusted_source": True,
                    }
                )
    return rows


def cross_check_claims(claims: list[dict], sources: list[dict]) -> dict:
    results = []
    for claim in claims:
        best = _best_source(claim, sources)
        comparison = _comparison(claim.get("claim_text", ""), best.get("text", "") if best else "")
        results.append(
            {
                "claim_id": claim["claim_id"],
                "claim_text": claim["claim_text"],
                "source_id": best.get("source_id", "") if best else "",
                "source_path": best.get("source_path", "") if best else "",
                "comparison": comparison,
                "agreement_score": _agreement_score(comparison),
                "matched_text": best.get("text", "")[:500] if best else "",
            }
        )
    return {
        "source_cross_check_version": "3.8.0-alpha.1",
        "status": "pass" if results else "warning",
        "claim_count": len(claims),
        "verification_source_count": len(sources),
        "results": results,
        "tests_require_real_llm_api_network": False,
    }


def _best_source(claim: dict, sources: list[dict]) -> dict:
    claim_tokens = set(_tokens(claim.get("claim_text", "")))
    best_score = -1
    best = {}
    for source in sources:
        tokens = set(_tokens(source.get("text", "")))
        score = len(claim_tokens & tokens)
        if score > best_score:
            best_score = score
            best = source
    return best


def _comparison(claim: str, evidence: str) -> str:
    if not evidence:
        return "missing_external_evidence"
    claim_tokens = set(_tokens(claim))
    evidence_tokens = set(_tokens(evidence))
    if not claim_tokens:
        return "missing_external_evidence"
    overlap = len(claim_tokens & evidence_tokens) / len(claim_tokens)
    if _negation_mismatch(claim, evidence) or _number_mismatch(claim, evidence):
        return "contradiction"
    if overlap >= 0.75:
        return "agreement"
    if overlap >= 0.35:
        return "partial_agreement"
    return "missing_external_evidence"


def _agreement_score(comparison: str) -> float:
    return {"agreement": 1.0, "partial_agreement": 0.6, "missing_external_evidence": 0.2, "contradiction": 0.0}.get(comparison, 0.0)


def _negation_mismatch(left: str, right: str) -> bool:
    neg = {"not", "never", "no", "不", "不是", "没有"}
    return bool(set(_tokens(left)) & neg) != bool(set(_tokens(right)) & neg)


def _number_mismatch(left: str, right: str) -> bool:
    left_numbers = re.findall(r"\d+(?:\.\d+)?", left)
    right_numbers = re.findall(r"\d+(?:\.\d+)?", right)
    return bool(left_numbers and right_numbers and left_numbers[0] != right_numbers[0])


def _load_source_file(path: Path) -> list[dict]:
    if not path.exists():
        raise FileNotFoundError(f"Verification source not found: {path}")
    if path.suffix.lower() == ".jsonl":
        return _read_jsonl(path)
    if path.suffix.lower() == ".json":
        payload = json.loads(path.read_text(encoding="utf-8"))
        if isinstance(payload, list):
            return payload
        if isinstance(payload, dict) and isinstance(payload.get("sources"), list):
            return payload["sources"]
    return [{"source_id": path.stem, "source_path": str(path).replace("\\", "/"), "text": path.read_text(encoding="utf-8")}]


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _tokens(value: str) -> list[str]:
    return [token.lower() for token in re.findall(r"[\w\u4e00-\u9fff]+", str(value)) if len(token) > 1]
