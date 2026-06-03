# HeiTang KB Forge Skill V0 Baseline

## Status

V0 baseline passed.

## Verified Capabilities

* Markdown/TXT input can be processed through the CLI build command.
* Standard knowledge-base package files are generated.
* chunks.jsonl contains valid JSON records.
* manifest.json contains valid JSON metadata.
* Project-level AGENTS.md is present.
* karpathy-guidelines Skill is present.

## Output Contract

The build command generates:

* chunks.jsonl
* cards.jsonl
* qa_pairs.jsonl
* glossary.jsonl
* manifest.json
* ingest_report.md

## Validation Commands

Executed:

* python -m pytest
* heitang-kb-forge build --input ./examples/input --output ./examples/output --domain education --mode teaching

Latest result:

* pytest: 6 passed
* CLI build: passed

## Current Non-Scope

Not implemented in V0:

* Full PDF parsing
* Full DOCX parsing
* Vector database integration
* External LLM extraction
* Web UI
* Agent orchestration

## Next Recommended Step

Before adding PDF/DOCX, improve V0 schema stability and validation quality only if needed. Otherwise start V1 with PDF/DOCX parser placeholders or lightweight parsing behind tests.
