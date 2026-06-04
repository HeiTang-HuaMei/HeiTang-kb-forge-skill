# Large File Performance

v1.6.2 combines progress visibility with large-file and OCR acceleration controls.

## Fast Profile

```powershell
heitang-kb-forge build --input .\input --output .\output --profile fast --progress-jsonl
```

`fast` mode applies a conservative OCR page limit when no explicit `--max-ocr-pages` value is provided.

## OCR Page Selection

```powershell
heitang-kb-forge build --input .\input --output .\output --ocr-mode first-pages --max-ocr-pages 10
heitang-kb-forge build --input .\input --output .\output --ocr-mode selected-pages --ocr-pages 1,3-5
heitang-kb-forge build --input .\input --output .\output --ocr-mode off
```

Supported OCR modes:

- `auto`
- `off`
- `first-pages`
- `selected-pages`
- `full`

## OCR Cache and Resume

```powershell
heitang-kb-forge build --input .\input --output .\output --ocr-cache --resume
```

OCR cache stores page text under `.heitang_cache\ocr`. Resume reuses cached page text and reports failed pages in `ocr_resume_report.md`.

## Performance Outputs

When performance options are enabled, outputs can include:

- `pdf_preflight_report.json`
- `pdf_page_classification.jsonl`
- `ocr_cache_manifest.json`
- `ocr_failed_pages.jsonl`
- `ocr_resume_report.md`
- `large_file_performance_report.md`

## Config Example

```yaml
performance:
  profile: fast
  progress: true
  progress_jsonl: true
  ocr_mode: first-pages
  max_ocr_pages: 10
  ocr_lang: chi_sim+eng
  ocr_workers: 4
  ocr_cache: true
  resume: true
  ocr_scale: 1.5
```

## Boundaries

No embedding API is called. No vector database is written. OCR still only extracts text and does not perform semantic image understanding, table reconstruction, layout reconstruction, or OCR correction.
