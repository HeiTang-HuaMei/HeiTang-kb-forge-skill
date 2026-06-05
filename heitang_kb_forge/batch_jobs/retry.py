from pathlib import Path

from heitang_kb_forge.batch_jobs.item_status import load_item_statuses
from heitang_kb_forge.exporters.jsonl_exporter import write_jsonl


def retry_failed_items(batch_job: Path, retry_only_failed: bool = True) -> tuple[list[dict], str]:
    output = batch_job.parent
    status_path = output / "batch_item_status.jsonl"
    statuses = load_item_statuses(status_path)
    retryable = [item for item in statuses if item.get("status") == "failed"] if retry_only_failed else statuses
    updated = []
    for item in statuses:
        record = dict(item)
        if item in retryable:
            record["retry_count"] = int(record.get("retry_count", 0)) + 1
            record["status"] = "failed"
            record["error_message"] = record.get("error_message") or "Retry recorded; source rebuild is not re-run in v2.3 minimal recovery."
        updated.append(record)
    if updated:
        write_jsonl(status_path, updated)
    report = "# Batch Retry Report\n\n"
    report += f"- Batch job: {batch_job}\n"
    report += f"- Retry only failed: {retry_only_failed}\n"
    report += f"- Retry candidates: {len(retryable)}\n"
    (output / "batch_retry_report.md").write_text(report, encoding="utf-8")
    return updated, report
