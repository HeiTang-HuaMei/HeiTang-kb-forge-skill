# 大文件性能

v1.6.2 把进度可视化和大文件 / OCR 提速合并为同一层能力。

```powershell
heitang-kb-forge build --input .\input --output .\output --profile fast --progress-jsonl
heitang-kb-forge build --input .\input --output .\output --ocr-mode selected-pages --ocr-pages 1,3-5
heitang-kb-forge build --input .\input --output .\output --ocr-cache --resume
```

可用输出：

- `pdf_preflight_report.json`
- `pdf_page_classification.jsonl`
- `ocr_cache_manifest.json`
- `ocr_failed_pages.jsonl`
- `ocr_resume_report.md`
- `large_file_performance_report.md`

OCR 仍然只负责提取文字，不做图片语义理解、表格结构还原、版面还原或 OCR 纠错。
