# Architecture

## Skill-first Architecture

HeiTang KB Forge is an Agent knowledge supply-chain Skill first. The desktop UI is a presentation layer.

Architecture priority:

```text
Core Skill / Python package
> CLI
> Config / Pipeline
> Agent-callable skill interface
> Desktop UI
```

The core remains headless and callable by OpenClaw, Claude Code, Codex, other Agent frameworks, local CLI users, future Agent Runtime / RAG Runtime, and the desktop UI.

## System Flow

```text
Documents
  -> HeiTang KB Forge Core Skill
  -> CLI / Config / Pipeline
  -> Standard Knowledge Package
  -> Quality Gate / Lifecycle / Export
  -> Agent / RAG / Desktop UI consumption
```

The desktop app is a consumer / controller. It does not own the core engine and does not introduce UI-private package formats.

## Pipeline

```text
source files
-> parser
-> cleaner
-> chunker
-> offline extractor
-> quality report
-> optional LLM
-> optional LLM quality
-> optional RAG export
-> optional embedding / vector export
-> optional Agent Template
-> optional validation / downstream export
```

## Parser Layer

Parsers return plain text. PDF, OCR, DOCX, and table-specific extraction converts structured or visual content into readable text before it enters the existing clean / chunk / extractor pipeline.

## Output Contract

The output contract stays Agent-friendly and file-first:

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `quality_report.json`
- `ingest_report.md`
- `rag_manifest.json`
- `embedding_input.jsonl`
- `retrieval_metadata.jsonl`
- `agent_profile.yaml`
- `retrieval_config.yaml`
- `tools.yaml`
- `eval_cases.jsonl`
- `quality_gate_report.json`
- `package_validation_report.json`
- `publish_manifest.json`

Future lifecycle, store, and connector outputs must remain standard files first. The UI only reads and displays them.

## Agent-callable Skill Direction

Future Skill interface structure is reserved:

```text
skills/
  heitang-kb-forge-skill/
    SKILL.md
    skill.json
    examples/
    prompts/
```

The external Skill capability surface should include:

- process multi-format documents
- generate standardized knowledge packages
- generate quality reports
- generate RAG export
- generate Agent Template
- generate downstream export
- run batch / pipeline workflows
- run lifecycle update
- run quality gate

## Runtime Boundary

Generated Agent Template, RAG, embedding, vector, and downstream files are handoff artifacts. They do not execute tools, deploy agents, write to external vector databases, or call external services by default.
