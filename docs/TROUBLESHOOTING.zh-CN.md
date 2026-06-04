# 故障排查

## Contract Check Failed

检查：

- `contract_check_result.json`
- `contract_check_report.md`

常见原因：

- 缺少 `manifest.json`
- 缺少 `chunks.jsonl`
- 缺少 `evidence_map.json`
- 启用了 multimodal 但缺少 `multimodal_assets.jsonl`

## 多模态资产需要复核

`review_required: true` 表示该 asset 是低置信或 fallback 结果，需要人工复核。它不会被当作可靠原文事实。

## 大文件或 OCR 太慢

使用：

```powershell
heitang-kb-forge build --input .\input --output .\output --progress-jsonl --profile fast --ocr-mode first-pages --max-ocr-pages 10 --ocr-cache --resume
```

查看：

- `progress_events.jsonl`
- `large_file_performance_report.md`
- `ocr_resume_report.md`
