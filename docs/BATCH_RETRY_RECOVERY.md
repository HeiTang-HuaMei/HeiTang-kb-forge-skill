# Batch Retry And Recovery

v2.3 records failed batch items in `batch_item_status.jsonl` and supports a local retry record pass.

Use:

```powershell
python -m heitang_kb_forge.cli batch-retry --batch-job .\batch_output\batch_job_manifest.json --retry-only-failed
```

The retry command updates item retry counts and writes `batch_retry_report.md`. The minimal v2.3 recovery layer does not introduce a scheduler or background queue.
