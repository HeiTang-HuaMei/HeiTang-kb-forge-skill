# AIGC Book Content Pipeline

HeiTang KB Forge Skill can support an AIGC book and content production workflow by turning source material into governed knowledge assets before generation starts. The goal is not to let a model freely invent content; the goal is to make every generated draft traceable to local evidence, package reports, and reusable Skill or Agent assets.

## 1. Import Source Material

Inputs can include manuscripts, editorial notes, reference books, policy files, product documents, tables, Markdown drafts, DOCX files, text PDFs, image/OCR routes, EPUB, HTML, ZIP packages, and mixed local folders.

Core output at this stage:

- source inventory
- parser and OCR risk reports
- format support and parse quality evidence
- local privacy boundary reports

OpenDataLoader, PaddleOCR, and MinerU are external backend candidates / planned adapters only. Current completed parser capability remains the verified internal parser, bounded best-effort OCR, and local PDF token reduction.

## 2. Turn Sources Into Knowledge Assets

The Core builds a standard knowledge package instead of passing raw documents directly into generation.

Key outputs:

- `manifest.json`
- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `quality_report.json`
- `ingest_report.md`

These outputs let editors and Agents inspect what entered the knowledge base, where evidence came from, and which source items need review.

## 3. Use RAG For Verification

The pipeline can separate answering retrieval from validation retrieval. That matters for AIGC book production because chapter drafts, claims, definitions, examples, and summaries need evidence checks before publication.

Useful Core paths:

- query rewrite
- retrieval planning
- local JSON vector query
- hybrid retrieval
- rerank
- evidence selection
- claim verification
- contradiction detection
- freshness check
- no-answer handling

The expected result is a generated content workflow that can say: this statement is supported, this source conflicts, this answer should be refused, or this topic needs editorial review.

## 4. Generate Structured Skills

Book or package material can become a structured Skill package. This is useful when a publisher, course team, operations team, or product team wants repeatable content workflows rather than one-off prompts.

Typical Skill outputs:

- `SKILL.md`
- manifests
- prompts
- test prompts
- Skill graph
- token budget reports
- installability checks
- runtime profiles for Codex, Claude Code, OpenClaw, and generic local integrations

## 5. Generate Agent Packages

The same knowledge package can support standalone or KB-bound Agent package generation.

Core can produce:

- Agent profile
- system prompt
- soul / policy files
- KB binding
- tool configuration
- memory policy
- provider mapping contract
- local runtime trace
- retry, timeout, and non-zero-exit reports
- mother/child orchestration contracts

Full autonomous tool-calling Agent runtime is not claimed. The current Core provides local deterministic runtime smoke, contracts, and boundary reports.

## 6. Produce Documents

The pipeline can produce grounded content artifacts for editorial review or downstream packaging.

Document outputs include:

- Markdown
- DOCX
- PDF
- PPTX
- manual / user guide style outputs
- evidence appendix
- openability checks

## Honesty Boundary

- Core pre-v4 RC readiness is complete for the latest Core P0 proof.
- UI full-operation is not complete.
- Stable `v4.1.0` is the current Parser/OCR release line after P2.1 hardening; `v4.0.0` remains an untouched historical stable tag.
- Core tests do not require real LLM/API/network calls.
- Real user secrets, raw private input, local provider profiles, and local configs must not be committed.

See [Current Truth](CURRENT_TRUTH.md), [Capability Matrix](CAPABILITY_MATRIX.md), and [Final Product Architecture Truth](FINAL_PRODUCT_ARCHITECTURE_TRUTH.md).
