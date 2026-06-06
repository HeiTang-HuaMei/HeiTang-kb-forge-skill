# Demo Script

## Goal

Run a 3-minute local offline demo for HeiTang KB Forge.

## Command

```powershell
python -m heitang_kb_forge.cli demo-e2e --output ./tmp_demo_e2e
```

## Files to open

```text
tmp_demo_e2e/demo_e2e_result.json
tmp_demo_e2e/portfolio_demo_report.md
tmp_demo_e2e/demo_evidence_pack/
tmp_demo_e2e/runtime_limitations.md
```

## Presenter flow

### 1. Explain the project

HeiTang KB Forge is an Agent knowledge supply-chain tool. It prepares governed knowledge assets before downstream Agent or RAG usage.

### 2. Run demo-e2e

The demo command runs a local offline workflow:

source input → knowledge package → quality gate → provider security audit → mock LLM quality assist → platform export → release readiness → portfolio report.

### 3. Open demo_e2e_result.json

Show the structured result. Explain that this is machine-readable and can be used by CI, release gates, or a UI.

### 4. Open portfolio_demo_report.md

Show the human-readable report. Explain that this is what a PM, reviewer, or interviewer can read.

### 5. Open demo_evidence_pack/

Show that the demo stores supporting artifacts instead of only claiming success.

### 6. Open runtime_limitations.md

Explain the boundaries: no real platform runtime, no default live provider, no MCP server, no real publishing.

## Cleanup

```powershell
Remove-Item -Recurse -Force ./tmp_demo_e2e -ErrorAction SilentlyContinue
```
