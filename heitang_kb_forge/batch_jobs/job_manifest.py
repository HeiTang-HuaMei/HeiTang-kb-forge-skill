from pathlib import Path
from datetime import datetime, timezone

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.schemas.batch_job_schema import BatchItemStatus, BatchJobManifest


def build_job_outputs(
    *,
    items: list[dict],
    input_root: Path,
    output_root: Path,
    profile: str = "production",
    retry_enabled: bool = True,
    resume_enabled: bool = True,
) -> tuple[BatchJobManifest, list[BatchItemStatus]]:
    now = datetime.now(timezone.utc).isoformat()
    statuses = [
        BatchItemStatus(
            item_id=item.get("sequence_id") or item.get("name") or f"item-{index}",
            source_path=item.get("source_path") or ", ".join(item.get("source_paths", [])),
            output_path=item.get("output_path", ""),
            status=item.get("status", "failed"),
            error_type="error" if item.get("error") else "",
            error_message=item.get("error") or "",
            started_at=now,
            finished_at=now,
            retry_count=int(item.get("retry_count", 0)),
            outputs=item.get("files", []),
        )
        for index, item in enumerate(items, start=1)
    ]
    success_count = sum(1 for item in statuses if item.status == "success")
    failed_count = sum(1 for item in statuses if item.status == "failed")
    partial_count = sum(1 for item in statuses if item.status == "partial")
    manifest = BatchJobManifest(
        batch_id=f"batch-{now}",
        created_at=now,
        input_root=str(input_root).replace("\\", "/"),
        output_root=str(output_root).replace("\\", "/"),
        total_items=len(statuses),
        success_count=success_count,
        failed_count=failed_count,
        skipped_count=sum(1 for item in statuses if item.status == "skipped"),
        partial_count=partial_count,
        profile=profile,
        resume_enabled=resume_enabled,
        retry_enabled=retry_enabled,
        status="failed" if success_count == 0 and failed_count else ("partial" if failed_count or partial_count else "success"),
    )
    return manifest, statuses


def write_job_outputs(output: Path, manifest: BatchJobManifest, statuses: list[BatchItemStatus]) -> None:
    write_json(output / "batch_job_manifest.json", manifest)
    write_jsonl(output / "batch_item_status.jsonl", statuses)
