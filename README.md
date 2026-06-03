# HeiTang KB Forge Skill

[中文说明](README.zh-CN.md) | English

`heitang-kb-forge-skill` is a local command-line tool for building a standardized knowledge base package from source documents.

The project is intentionally offline: no Web UI, no vector database, and no external LLM.

## Features

- Python 3.11+
- Typer CLI
- Pydantic schemas
- UTF-8 output
- Stable reproducible `chunk_id`
- Markdown, TXT, text-based PDF, and text-based DOCX parsing
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
