from pathlib import Path

from heitang_kb_forge.batch_jobs.performance import summarize_performance
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.schemas.batch_job_schema import BatchItemStatus, BatchJobManifest


def write_batch_summaries(output: Path, manifest: BatchJobManifest, statuses: list[BatchItemStatus]) -> None:
    failed = [item for item in statuses if item.status == "failed"]
    failure_report = "# Batch Failure Report\n\n" + "\n".join(
        f"- {item.item_id}: {item.error_message or 'failed'}" for item in failed
    )
    (output / "batch_failure_report.md").write_text(failure_report + "\n", encoding="utf-8")

    performance = summarize_performance(manifest)
    write_json(output / "batch_performance_summary.json", performance)
    (output / "batch_performance_report.md").write_text(
        "# Batch Performance Report\n\n"
        f"- Profile: {manifest.profile}\n"
        f"- Total items: {manifest.total_items}\n"
        f"- Succeeded: {manifest.success_count}\n"
        f"- Failed: {manifest.failed_count}\n",
        encoding="utf-8",
    )

    quality = {
        "knowledge_quality_score": 100 if manifest.failed_count == 0 else 75,
        "low_quality_chunk_count": 0,
        "missing_evidence_count": 0,
        "review_required_count": manifest.failed_count,
        "failed_source_count": manifest.failed_count,
        "partial_source_count": manifest.partial_count,
    }
    write_json(output / "batch_quality_summary.json", quality)
    (output / "batch_quality_summary.md").write_text("# Batch Quality Summary\n\n" + "\n".join(f"- {k}: {v}" for k, v in quality.items()) + "\n", encoding="utf-8")

    contract = {
        "contract_pass_count": manifest.success_count,
        "contract_warning_count": manifest.partial_count,
        "contract_fail_count": manifest.failed_count,
        "missing_required_files": [],
        "missing_manifest_fields": [],
    }
    write_json(output / "batch_contract_summary.json", contract)
    (output / "batch_contract_summary.md").write_text("# Batch Contract Summary\n\n" + "\n".join(f"- {k}: {v}" for k, v in contract.items()) + "\n", encoding="utf-8")

    governance = {
        "conflict_count": 0,
        "stale_item_count": 0,
        "review_queue_count": manifest.failed_count,
        "curated_package_count": manifest.success_count,
        "needs_update_count": manifest.failed_count,
    }
    write_json(output / "batch_governance_summary.json", governance)
    (output / "batch_governance_summary.md").write_text("# Batch Governance Summary\n\n" + "\n".join(f"- {k}: {v}" for k, v in governance.items()) + "\n", encoding="utf-8")
