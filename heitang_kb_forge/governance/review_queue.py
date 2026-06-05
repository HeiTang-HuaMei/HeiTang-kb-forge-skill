from pathlib import Path
import json


def make_governance_review_queue(package: Path, conflict_report: dict, staleness_report: dict) -> list[dict]:
    queue = []
    for conflict in conflict_report.get("conflicts", []):
        queue.append(
            {
                "review_id": f"conflict_{len(queue) + 1}",
                "reason": "conflict_detected",
                "status": "open",
                "chunk_ids": conflict.get("chunk_ids", []),
                "source": "governance",
            }
        )
    for chunk_id in staleness_report.get("stale_chunk_ids", []):
        queue.append(
            {
                "review_id": f"stale_{len(queue) + 1}",
                "reason": "stale_content",
                "status": "open",
                "chunk_ids": [chunk_id],
                "source": "governance",
            }
        )
    for asset in _load_jsonl(package / "multimodal_assets.jsonl"):
        if asset.get("review_required"):
            queue.append(
                {
                    "review_id": f"asset_{len(queue) + 1}",
                    "reason": "multimodal_review_required",
                    "status": "open",
                    "chunk_ids": [],
                    "source": asset.get("source_path"),
                }
            )
    return queue


def _load_jsonl(path: Path) -> list[dict]:
    if not path.exists():
        return []
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
