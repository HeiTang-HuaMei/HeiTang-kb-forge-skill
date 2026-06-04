# Installation

## Basic Install

```powershell
git clone https://github.com/HeiTang-HuaMei/HeiTang-kb-forge-skill.git
cd HeiTang-kb-forge-skill
python -m venv .venv
.\.venv\Scripts\activate
python -m pip install -e .
```

## Development Install

```powershell
python -m pip install -e ".[dev]"
```

## OCR / PDF Table Install

```powershell
python -m pip install -e ".[ocr,pdf-table]"
```

## Full Local Capability Install

```powershell
python -m pip install -e ".[dev,ocr,pdf-table]"
```

## Important OCR Notes

- The `ocr` extra installs Python packages only.
- Tesseract OCR itself is a system dependency and must be installed separately.
- Simplified Chinese OCR requires `chi_sim.traineddata`.
- Missing OCR dependencies do not affect Markdown, TXT, text-based PDF, DOCX, CSV, TSV, or XLSX flows.

## Verify Installation

```powershell
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
```
