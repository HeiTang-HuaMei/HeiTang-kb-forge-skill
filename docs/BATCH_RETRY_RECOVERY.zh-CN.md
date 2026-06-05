# 批量重试与恢复

v2.3 会在 `batch_item_status.jsonl` 中记录失败项，并提供本地重试记录能力。

使用：

```powershell
python -m heitang_kb_forge.cli batch-retry --batch-job .\batch_output\batch_job_manifest.json --retry-only-failed
```

该命令会更新 retry 计数并写出 `batch_retry_report.md`。v2.3 最小恢复层不引入调度器或后台队列。
