# Project Architecture Overview

## Architecture layers

```text
[1] Ingestion Layer
    PDF / DOCX / Markdown / TXT / CSV / XLSX / images

[2] Knowledge Package Layer
    chunks / cards / QA / glossary / manifest

[3] Quality and Evidence Layer
    quality gate / evidence gate / release blockers / regression

[4] Provider Governance Layer
    provider registry / security audit / redaction / fallback / cost guard

[5] Export Layer
    Agent package / Skill package / platform export / mock publishing

[6] Demo-E2E Layer
    portfolio report / evidence pack / runtime limitations
```

## Why default offline matters

The tool handles knowledge assets and provider configuration. A safe default prevents accidental network calls, API key leaks, and fake claims of real platform execution.

## Where real LLM fits

Real LLM calls are optional. The provider governance layer defines env-only keys, redacted audit, fallback behavior, cost guard, and explicit live smoke.

## Current role of demo-e2e

The demo-e2e layer proves that the project can run a complete local portfolio workflow without requiring external services.
