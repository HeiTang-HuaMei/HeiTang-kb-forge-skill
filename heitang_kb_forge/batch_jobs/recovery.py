from pathlib import Path

from heitang_kb_forge.batch_jobs.item_status import load_item_statuses


def recoverable_items(batch_job: Path) -> list[dict]:
    return [item for item in load_item_statuses(batch_job.parent / "batch_item_status.jsonl") if item.get("status") != "success"]
