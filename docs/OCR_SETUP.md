# OCR Setup

OCR is optional. Markdown, TXT, text-based PDF, DOCX, CSV, TSV, and XLSX flows do not require OCR.

## Python OCR Dependencies

If `pypdfium2` is missing:

```powershell
python -m pip install -e ".[ocr]"
```

If `pytesseract` is missing:

```powershell
python -m pip install -e ".[ocr]"
```

If `Pillow` / `PIL` is missing:

```powershell
python -m pip install -e ".[ocr]"
```

## Tesseract Binary

If you see `tesseract is not installed or not in PATH`, install Tesseract OCR for Windows and add the installation directory to PATH.

After installation:

```powershell
tesseract --version
tesseract --list-langs
```

## Simplified Chinese OCR

Chinese OCR requires `chi_sim.traineddata`.

If `chi_sim` is missing from:

```powershell
tesseract --list-langs
```

install the Simplified Chinese traineddata file into the Tesseract `tessdata` directory.

## Scanned PDF Boundaries

- Text-based PDF parsing is tried first.
- OCR fallback is used only when PDF text extraction is empty or too short.
- OCR quality is not guaranteed.
- OCR does not perform layout reconstruction, table recognition, semantic image understanding, or correction.
- OCR output enters the same clean / chunk / extractor / quality pipeline as other text.

## v1.6.2 OCR Performance Options

For large scanned PDFs, use progress and OCR controls together:

```powershell
heitang-kb-forge build --input .\input --output .\output --progress-jsonl --profile fast --ocr-mode first-pages --max-ocr-pages 10 --ocr-cache --resume
```

Useful options:

- `--ocr-mode off|auto|first-pages|selected-pages|full`
- `--ocr-pages 1,3-5`
- `--ocr-workers 4`
- `--ocr-timeout-per-page 120`
- `--ocr-scale 1.5`
- `--ocr-cache`
- `--resume`

Performance outputs include `pdf_preflight_report.json`, `pdf_page_classification.jsonl`, `ocr_failed_pages.jsonl`, `ocr_resume_report.md`, and `large_file_performance_report.md`.
