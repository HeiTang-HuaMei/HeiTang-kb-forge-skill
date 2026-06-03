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

## Output

The output directory contains:

- `chunks.jsonl`: normalized text chunks with stable IDs and source metadata
- `cards.jsonl`: simple knowledge cards derived from chunks
- `qa_pairs.jsonl`: deterministic QA pairs derived from chunks
- `glossary.jsonl`: simple glossary candidates detected from capitalized terms
- `manifest.json`: package metadata and counts
- `ingest_report.md`: human-readable ingest summary and warnings

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
