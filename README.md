# HeiTang KB Forge Skill

[中文说明](README.zh-CN.md) | English

`heitang-kb-forge-skill` is a local command-line tool for building a standardized knowledge base package from source documents.

HeiTang KB Forge Skill is a knowledge-base production foundation for Agent systems. It turns multi-format source materials into searchable, traceable, auditable, and reusable knowledge asset packages.

The project is intentionally offline: no Web UI, no vector database, and no external LLM.

## Features

- Python 3.11+
- Typer CLI
- Pydantic schemas
- UTF-8 output
- Stable reproducible `chunk_id`
- Markdown, TXT, text-based PDF, and text-based DOCX parsing
- Optional image OCR support for PNG, JPG, and JPEG
- Optional scanned PDF OCR fallback
- Structured table file ingestion for CSV, TSV, and XLSX
- DOCX embedded table extraction
- Opt-in LLM structured extraction
- Single-file `build`
- Numbered-file batch production with `batch`
- Offline knowledge asset quality enhancement for cards, QA pairs, and glossary terms
- Text-based PDF is parsed directly; scanned or image-based PDF can fall back to OCR when text extraction is empty or too short
- DOCX supports paragraph text extraction and embedded table extraction; merged cell semantic reconstruction is not supported
- Chunk validation for empty chunks, duplicate chunks, and missing fields

## Install

```bash
cd HeiTang-kb-forge-skill
python -m venv .venv
.venv\Scripts\activate
pip install -e ".[dev]"
```

Install optional OCR support for image inputs and scanned PDF fallback:

```bash
pip install -e ".[ocr]"
```

The OCR extra includes `pytesseract`, `Pillow`, and `pypdfium2`. A local Tesseract binary may still be required by your operating system.

XLSX support uses `openpyxl`, which is installed as a default dependency.

On macOS or Linux, activate with:

```bash
source .venv/bin/activate
```

## Run

Add `.md`, `.txt`, `.pdf`, text-based `.docx`, `.png`, `.jpg`, `.jpeg`, `.csv`, `.tsv`, or `.xlsx` files under `examples/input`, then run:

```bash
heitang-kb-forge build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

You can also run the module directly:

```bash
python -m heitang_kb_forge.cli build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

## Image OCR

v0.4.0 adds optional OCR input support for `.png`, `.jpg`, and `.jpeg` files.

OCR only extracts text from images. The extracted text continues through the existing clean, chunk, extractor, and quality pipeline. OCR dependencies are optional, so users without OCR support can continue using Markdown, TXT, text-based PDF, and text-based DOCX workflows.

## Scanned PDF OCR

v0.4.1 adds optional scanned PDF OCR fallback.

Text-based PDF extraction remains the first priority. OCR fallback only runs when extracted PDF text is empty or too short. OCR text continues through the existing clean, chunk, extractor, and quality pipeline. Page OCR text is joined with markers such as `[Page 1]` and `[Page 2]`.

PDF OCR uses the optional OCR dependency group:

- `pytesseract`
- `Pillow`
- `pypdfium2`

A local Tesseract binary may still be required.

OCR boundaries:

- No LLM integration.
- No vector database integration.
- No image semantic understanding.
- No layout reconstruction.
- No table reconstruction.
- No table structure recognition.
- No OCR correction.
- No PDF table extraction in v0.4.3.

## Table File Ingestion

v0.4.2 adds structured table file ingestion for `.csv`, `.tsv`, and `.xlsx` files.

The parser converts structured rows and columns into readable text. Converted text continues through the existing clean, chunk, extractor, and quality pipeline.

Table parsing behavior:

- CSV and TSV use UTF-8-SIG compatible reading.
- XLSX supports multiple sheets.
- Empty rows are skipped.
- The first row is treated as the header.
- Empty headers become `Column A`, `Column B`, and so on.
- Duplicate headers get suffixes, such as `Name 2`.

CSV row:

```text
书名,作者,ISBN,定价
产品经理入门,张三,123456,59
```

Converted text:

```text
Row 2. 书名: 产品经理入门. 作者: 张三. ISBN: 123456. 定价: 59.
```

XLSX converted text:

```text
Sheet: 商品列表. Row 2. 书名: 产品经理入门. 作者: 张三.
```

Table ingestion boundaries:

- No `.xls` support.
- No PDF embedded table extraction.
- No image table OCR.
- No scanned table structure recognition.
- No formula engine.
- No complex data analysis.
- No LLM integration.
- No vector database integration.

## DOCX Embedded Tables

v0.4.3 adds DOCX embedded table extraction while preserving paragraph text extraction.

DOCX tables are converted into readable text and continue through the existing clean, chunk, extractor, and quality pipeline.

Example converted row:

```text
Table 1. Row 2. Field A: Value A. Field B: Value B.
```

Boundaries:

- No semantic reconstruction for merged cells.
- No PDF table extraction in v0.4.3.
- No image table OCR.
- No scanned table structure recognition.

## LLM Structured Extraction

v0.5.0 adds opt-in LLM structured extraction. LLM extraction is disabled by default and only runs when `--llm` is provided.

LLM is an enhancement layer, not the only production path. Without `--llm`, the offline 7-file output remains unchanged. When enabled, LLM output is extra and does not overwrite offline `cards.jsonl`, `qa_pairs.jsonl`, or `glossary.jsonl`.

Example:

```bash
heitang-kb-forge build --input ./input.md --output ./output --llm --llm-provider fake --llm-model fake-model
```

The fake provider is available for local testing and does not access the network.

With `--llm`, these extra files are generated:

- `llm_cards.jsonl`
- `llm_qa_pairs.jsonl`
- `llm_glossary.jsonl`
- `frameworks.jsonl`
- `case_cards.jsonl`
- `metrics.jsonl`

LLM records include:

- `source_path`
- `chunk_id`
- `citation`
- `confidence`
- `llm_provider`
- `llm_model`
- `token_usage`
- `cache_key`

LLM failure behavior:

- By default, LLM failure falls back to the offline path and keeps the build successful.
- With `--llm-strict`, LLM failure fails the current build, batch item, or merge group.

Security boundaries:

- API keys are not written to output files, cache, or reports.
- Tests use the fake provider and do not access the network.

Not included yet:

- No RAG export.
- No vector database integration.
- No Agent Template.
- No Web UI.

## Batch

v0.2.0 adds batch production for numbered source files:

```bash
heitang-kb-forge batch --input ./input --output ./output --domain education --mode teaching
```

Example input:

```text
input/
  001_会员系统.pdf
  002_AI伴学.docx
  003_产品经理面试.md
```

Example output:

```text
output/
  001_会员系统/
  002_AI伴学/
  003_产品经理面试/
  batch_manifest.json
  batch_report.md
```

Each successful knowledge-base package contains:

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `ingest_report.md`

Batch rules:

- Only files whose names start with `number_` are processed, for example `001_会员系统.md`.
- Files that do not match the numbering rule are not included in the batch.
- A single file failure does not interrupt the whole batch.
- Unsupported extensions are recorded as `failed`.

### Same-Sequence Merge

v0.2.1 adds optional same-sequence merging for batch production.

The default batch behavior is unchanged. This command still creates one independent output directory per numbered file, for example `output/001_会员系统/`:

```bash
heitang-kb-forge batch --input ./input --output ./output --domain education --mode teaching
```

To merge multiple files with the same numeric prefix into one package, pass `--merge-same-sequence`:

```bash
heitang-kb-forge batch --input ./input --output ./output --domain education --mode teaching --merge-same-sequence
```

Merge input example:

```text
input/
  001_教材.pdf
  001_目录.docx
  001_作者简介.txt
  001_营销卖点.md
  002_AI伴学方案.docx
  002_AI伴学FAQ.md
```

Merge output example:

```text
output/
  001/
    chunks.jsonl
    cards.jsonl
    qa_pairs.jsonl
    glossary.jsonl
    manifest.json
    ingest_report.md
  002/
    chunks.jsonl
    cards.jsonl
    qa_pairs.jsonl
    glossary.jsonl
    manifest.json
    ingest_report.md
  batch_manifest.json
  batch_report.md
```

Merge rules:

- Files are merged only when `--merge-same-sequence` is provided.
- Files are grouped by the leading number in the filename.
- `001_教材.pdf` and `001_目录.docx` are built into the same `output/001/` package.
- Files inside each group are processed in filename order.
- If a group contains an unsupported extension, that group is recorded as `failed`.
- One failed group does not affect other groups.
- Non-numbered files are not included in the batch.

Common use cases:

- Multiple source files for one book.
- Course material packages.
- Product material packages.
- Project material packages.
- Multi-document knowledge-base preparation before Agent construction.

## Output

The output directory contains:

- `chunks.jsonl`: normalized text chunks with stable IDs and source metadata
- `cards.jsonl`: knowledge cards derived from chunks
- `qa_pairs.jsonl`: basic QA pairs derived from chunks
- `glossary.jsonl`: English and Chinese glossary term candidates
- `manifest.json`: package metadata and counts
- `ingest_report.md`: human-readable ingest summary and warnings
- `quality_report.json`: machine-readable quality summary

## Knowledge Asset Quality

v0.3.0 upgrades the standard knowledge-base package into a higher-quality Agent knowledge asset package while remaining fully offline and rule-based.

`cards.jsonl` quality improvements:

- Filters empty `title` and empty `summary` records.
- Deduplicates cards.
- Adds `card_type`.
- Adds `tags`.
- Adds `citation`.

`qa_pairs.jsonl` quality improvements:

- Filters empty `question` and empty `answer` records.
- Deduplicates QA pairs.
- Generates questions that are closer to real user questions.
- Keeps answers derived from chunk text.
- Adds `qa_type`.
- Adds `citation`.

`glossary.jsonl` quality improvements:

- Supports English term candidates.
- Supports Chinese term candidates.
- Deduplicates terms.
- Filters overly short content, punctuation-only content, numeric-only content, and generic stop words.
- Adds `source_path`.
- Adds `chunk_id`.
- Adds `citation`.

v0.3.0 does not add LLM extraction, OCR, vector database integration, or new default output files.

## Validation

The validator checks:

- empty chunk text
- duplicate chunk text
- missing required chunk fields
- Pydantic schema validity

## Test

```bash
pytest
```

## License

MIT License. See LICENSE for details.
