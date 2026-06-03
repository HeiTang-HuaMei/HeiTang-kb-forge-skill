# HeiTang KB Forge Skill V1 Baseline

## Status

V1 parser layer passed.

## Supported Input Formats

* Markdown
* TXT
* text-based PDF
* text-based DOCX

## Output Contract

The build command generates:

* chunks.jsonl
* cards.jsonl
* qa_pairs.jsonl
* glossary.jsonl
* manifest.json
* ingest_report.md

## Verified Tests

* V0 output contract
* PDF parser unit + CLI integration
* DOCX parser unit + CLI integration
* all-format build integration

## Known Boundaries

* OCR is not supported.
* Image content parsing is not supported.
* Complex table structure reconstruction is not supported.
* LLM extraction is not supported.
* Vector database integration is not supported.
