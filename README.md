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
- Single-file `build`
- Numbered-file batch production with `batch`
- Offline knowledge asset quality enhancement for cards, QA pairs, and glossary terms
- PDF/DOCX support is limited to text extraction; OCR, images, and complex table reconstruction are not supported
- Chunk validation for empty chunks, duplicate chunks, and missing fields

## Install

```bash
cd HeiTang-kb-forge-skill
python -m venv .venv
.venv\Scripts\activate
pip install -e ".[dev]"
```

On macOS or Linux, activate with:

```bash
source .venv/bin/activate
```

## Run

Add `.md`, `.txt`, text-based `.pdf`, or text-based `.docx` files under `examples/input`, then run:

```bash
heitang-kb-forge build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

You can also run the module directly:

```bash
python -m heitang_kb_forge.cli build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

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
