# 批量任务操作

v2.3 增加工业级批量任务观测能力，但不改变默认知识包输出契约。

关键输出：

- `batch_job_manifest.json`
- `batch_item_status.jsonl`
- `batch_failure_report.md`
- `batch_performance_report.md`
- `batch_quality_summary.json`
- `batch_contract_summary.json`
- `batch_governance_summary.json`

使用：

```powershell
python -m heitang_kb_forge.cli batch-run --input .\sources --output .\batch_output --profile production --worker-pool --max-workers 4
```

该批量层完全本地运行，不调用 LLM、embedding、向量库、SaaS 或真实 Agent Runtime。
