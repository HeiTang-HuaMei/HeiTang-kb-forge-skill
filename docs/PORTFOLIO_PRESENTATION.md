# Portfolio Presentation: HeiTang KB Forge Skill

## Positioning

HeiTang KB Forge Skill is a local Agent knowledge supply-chain base.

It prepares governed knowledge assets for downstream RAG Agents, recommendation Agents, education Agents, customer service Agents, and product-manager Agents.

## Why it matters

Agent projects need reliable knowledge before they need more UI or more prompts.

The project focuses on:

- ingestion
- standardization
- quality gate
- evidence
- provider governance
- export
- demo evidence

## Version evolution

### v2.5.1

Release engineering, CI, CLI convergence, capability status, version matrix, and release checklist.

### v2.6

Real LLM provider governance, domestic / international provider registry, security audit, fallback, cost guard, and optional live smoke.

### v2.7

Minimal end-to-end demo and portfolio report.

## Architecture

```text
Source Materials
  ↓
Ingestion / Parsing
  ↓
Knowledge Package
  ↓
Quality / Evidence
  ↓
Provider Governance
  ↓
Agent / Skill Export
  ↓
Demo E2E Report + Evidence Pack
```

## Demo workflow

```text
build
→ quality-gate
→ provider-security-audit
→ llm-quality-gate-assist
→ export-platform
→ release-readiness
→ portfolio_demo_report
```

## Current limitations

- No full runtime compatibility claim.
- No real platform publishing.
- No MCP server auto-start.
- No SaaS / permissions / multi-tenant system.
- Live LLM usage is optional and not required for CI.

## Roadmap

Next valuable steps:

- runtime compatibility evidence
- domain Skill templates
- productized entry points
- team collaboration design
