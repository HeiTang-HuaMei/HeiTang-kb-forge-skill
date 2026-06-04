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
