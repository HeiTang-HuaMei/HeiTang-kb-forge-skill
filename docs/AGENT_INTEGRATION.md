# Agent Integration

HeiTang KB Forge is a Skill-first, CLI-first knowledge supply-chain component for Agent systems.

## OpenClaw

OpenClaw can use HeiTang KB Forge as an upstream Skill:

```text
documents -> heitang-kb-forge build -> standard package -> retrieve/ask/tools/mcp
```

The Agent receives documents, calls KB Forge, receives a standardized knowledge package, and uses package artifacts for retrieval, Q&A, planning, downstream export, or evaluation.

## Claude Code / Codex

Claude Code and Codex can call KB Forge as a local CLI Skill:

```powershell
python -m heitang_kb_forge.cli build --input .\input --output .\output
python -m heitang_kb_forge.cli retrieve --package .\output --query "What does this package contain?" --output .\retrieve
python -m heitang_kb_forge.cli tools export --output .\tools
```

## Generic Agent

A generic Agent can read:

- SKILL.md
- skill.json
- tool_manifest.json
- agent_tool_schema.json
- mcp_server_config.yaml

## Boundaries

- This project does not integrate with business systems.
- This project does not require network access by default.
- This project outputs knowledge assets and tool declarations.
- This project does not replace a complete Agent Runtime.
- Desktop UI is a local presentation layer, not the core engine.
