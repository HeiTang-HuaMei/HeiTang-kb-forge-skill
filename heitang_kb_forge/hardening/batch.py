BATCH_HARDENING_OUTPUT_FILES = ["batch_run_summary.json", "batch_run_report.md", "failed_items.jsonl", "retry_manifest.json"]


def make_batch_hardening_outputs(batch_manifest: dict) -> tuple[dict, str, list[dict], dict]:
    items = batch_manifest.get("items", [])
    failed = [item for item in items if item.get("status") == "failed"]
    warning = [item for item in items if item.get("status") == "warning"]
    skipped = [item for item in items if item.get("status") == "skipped"]
    summary = {
        "batch_run_summary_version": "1.2.1",
        "total_items": len(items),
        "succeeded": sum(1 for item in items if item.get("status") == "success"),
        "failed": len(failed),
        "warning": len(warning),
        "skipped": len(skipped),
        "continue_on_error": batch_manifest.get("continue_on_error", True),
        "fail_fast": batch_manifest.get("fail_fast", False),
    }
    retry_manifest = {
        "retry_manifest_version": "1.2.1",
        "items": [
            {
                "source_path": item.get("source_path") or item.get("source_paths"),
                "error_reason": item.get("error_reason") or item.get("error"),
                "output_path": item.get("output_path"),
            }
            for item in failed
        ],
        "manual_retry_hint": "Re-run batch with the listed source files or source groups.",
    }
    return summary, _report(summary, failed), failed, retry_manifest


def _report(summary: dict, failed: list[dict]) -> str:
    rows = "\n".join(
        f"| {item.get('sequence_id')} | {item.get('name') or item.get('group_name')} | {item.get('error_reason') or item.get('error')} |"
        for item in failed
    ) or "| - | - | - |"
    return f"""# Batch Run Report

## Summary

- Total items: {summary['total_items']}
- Succeeded: {summary['succeeded']}
- Failed: {summary['failed']}
- Warning: {summary['warning']}
- Skipped: {summary['skipped']}
- Continue on error: {summary['continue_on_error']}
- Fail fast: {summary['fail_fast']}

## Failed Items

| Sequence | Name | Error |
| --- | --- | --- |
{rows}
"""
