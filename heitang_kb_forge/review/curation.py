import json
from datetime import datetime, timezone
from pathlib import Path

REVIEW_OUTPUT_FILES = ["review_queue.jsonl", "review_decisions.jsonl", "curation_report.md"]


def create_review_queue(package: Path) -> tuple[list[dict], str]:
    chunks = _read_jsonl(package / "chunks.jsonl")
    risks = _read_jsonl(package / "risk_labels.jsonl")
    risk_by_chunk: dict[str, list[dict]] = {}
    for risk in risks:
        risk_by_chunk.setdefault(str(risk.get("chunk_id", "")), []).append(risk)
    queue = []
    for chunk in chunks:
        chunk_risks = risk_by_chunk.get(str(chunk.get("chunk_id", "")), [])
        if not chunk_risks and len(queue) >= 3:
            continue
        if chunk_risks or len(queue) < 3:
            queue.append(
                {
                    "review_id": f"review_{len(queue) + 1}",
                    "source_path": chunk.get("source_path", ""),
                    "chunk_id": chunk.get("chunk_id", ""),
                    "citation": f"{chunk.get('source_path', '')}#chunk={chunk.get('chunk_id', '')}",
                    "text": chunk.get("text", ""),
                    "risk_labels": [item.get("label") for item in chunk_risks],
                    "reason": "risk_label" if chunk_risks else "sample_review",
                    "suggested_action": "approve_or_revise",
                    "status": "pending",
                }
            )
    return queue, _review_report(queue)


def apply_review_decisions(package: Path, decisions: Path) -> tuple[list[dict], str]:
    chunks = _read_jsonl(package / "chunks.jsonl")
    decisions_by_id = {item["review_id"]: item for item in _read_jsonl(decisions)}
    curated = []
    for index, chunk in enumerate(chunks, start=1):
        decision = decisions_by_id.get(f"review_{index}")
        if decision and decision.get("decision") == "reject":
            continue
        if decision and decision.get("decision") == "revise" and decision.get("revised_text"):
            chunk = dict(chunk)
            chunk["text"] = decision["revised_text"]
            chunk.setdefault("metadata", {})["curated"] = True
        curated.append(chunk)
    return curated, _curation_report(curated, decisions_by_id)


def empty_decision_template(queue: list[dict]) -> list[dict]:
    now = datetime.now(timezone.utc).isoformat()
    return [
        {
            "review_id": item["review_id"],
            "decision": "approve",
            "revised_text": "",
            "reviewer": "",
            "reviewed_at": now,
            "notes": "",
        }
        for item in queue
    ]


def _read_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _review_report(queue: list[dict]) -> str:
    return f"# Review Queue Report\n\n- Review items: {len(queue)}\n"


def _curation_report(curated: list[dict], decisions: dict) -> str:
    return f"# Curation Report\n\n- Curated chunks: {len(curated)}\n- Decisions applied: {len(decisions)}\n"
