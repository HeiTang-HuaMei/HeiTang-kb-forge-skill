# Batch Operations

v2.3 adds industrial batch observability without changing the default knowledge package contract.

Key outputs:

- `batch_job_manifest.json`
- `batch_item_status.jsonl`
- `batch_failure_report.md`
- `batch_performance_report.md`
- `batch_quality_summary.json`
- `batch_contract_summary.json`
- `batch_governance_summary.json`

Use:

```powershell
python -m heitang_kb_forge.cli batch-run --input .\sources --output .\batch_output --profile production --worker-pool --max-workers 4
```

The batch layer is local and does not call LLM, embedding, vector database, SaaS, or Agent runtime services.
