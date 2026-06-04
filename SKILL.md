---
name: heitang-kb-forge-skill
description: Agent knowledge supply-chain Skill for producing standardized, auditable, retrievable knowledge packages.
---

# HeiTang KB Forge Skill

HeiTang KB Forge Skill is an Agent knowledge supply-chain pre-processing Skill.

It turns PDF, DOCX, Markdown, TXT, OCR image input, and structured table files into standardized, traceable, searchable, evaluable, and reusable knowledge asset packages.

## Input Types

- md
- txt
- pdf
- docx
- png
- jpg
- jpeg
- csv
- tsv
- xlsx

## Output Contract

Core package files:

- chunks.jsonl
- cards.jsonl
- qa_pairs.jsonl
- glossary.jsonl
- manifest.json
- quality_report.json
- ingest_report.md

Optional Agent / lifecycle / RAG / store files:

- rag_manifest.json
- source_registry.json
- store index
- retrieval_result.json
- answer.md
- tool_manifest.json
- mcp_server_config.yaml

## Recommended Agent Call Chain

```powershell
heitang-kb-forge build --input .\input --output .\output
heitang-kb-forge lifecycle-check --input .\input --package .\output --output .\lifecycle_check
heitang-kb-forge store import-package --db .\kb_forge_workspace.db --package .\output
heitang-kb-forge retrieve --package .\output --query "What is this package about?" --output .\retrieve
heitang-kb-forge ask --package .\output --query "Summarize this package." --citation-required --output .\ask
heitang-kb-forge tools export --output .\tools
heitang-kb-forge mcp export-config --output .\mcp
```

## Agent Boundaries

- Does not directly deploy Agents.
- Does not execute external business tools.
- Does not call CRM, product, or order systems.
- Does not require network access by default.
- Does not replace vector database services.
- Desktop UI is only a presentation layer; CLI and package files remain the standard interface.

## Error Handling Notes

- Missing OCR Python dependencies: install with `python -m pip install -e ".[ocr]"`.
- Missing Tesseract binary: install Tesseract OCR and add it to PATH.
- Missing `chi_sim`: install `chi_sim.traineddata` for Simplified Chinese OCR.
- Unsupported formats are ignored or recorded as failed batch items depending on command mode.
- Source lifecycle commands classify sources as changed, missing, new, or unchanged.

## Agent Integration Direction

HeiTang KB Forge is designed to be called by:

- OpenClaw
- Claude Code
- Codex
- Generic Agent frameworks
- MCP-ready workflows
