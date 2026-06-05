from pathlib import Path
from datetime import datetime, timezone
import json


def load_decisions(path: Path) -> dict[str, dict]:
    if not path.exists():
        return {}
    decisions: dict[str, dict] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if not line.strip():
            continue
        decision = json.loads(line)
        decisions[decision.get("item_id", "")] = decision
    return decisions


def default_decision(item_id: str, output_item_id: str) -> dict:
    return {
        "decision_id": f"decision-{item_id}",
        "item_id": item_id,
        "item_type": "chunk",
        "decision": "accept",
        "reason": "Included by default curation policy.",
        "reviewer": "system",
        "created_at": datetime.now(timezone.utc).isoformat(),
        "source_evidence_refs": [item_id],
        "output_item_id": output_item_id,
    }
