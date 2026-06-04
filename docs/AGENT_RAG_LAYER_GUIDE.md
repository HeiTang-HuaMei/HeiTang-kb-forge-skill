# Agent RAG Layer Guide

HeiTang KB Forge v1.5.0 adds a local Agent RAG layer for package and store retrieval.

## Scope

The Agent RAG layer is local and provider-neutral. It reads existing package files or the local SQLite store and writes retrieval, citation, and answer artifacts.

It does not call embedding APIs, write to vector databases, or deploy Agents.

## Commands

```powershell
heitang-kb-forge retrieve --package .\output --query "What is this package about?" --top-k 5 --output .\rag_run
```

```powershell
heitang-kb-forge ask --package .\output --query "What is this package about?" --citation-required --output .\ask_run
```

```powershell
heitang-kb-forge retrieve --store .\kb_forge_workspace.db --query "refund policy" --agent-type customer_service_agent --output .\rag_run
```

## Outputs

- retrieval_result.json
- retrieval_trace.json
- citation_trace.json
- answer.md
- answer_report.json
- agent_rag_config.yaml

## Config

```yaml
agent_rag:
  enabled: true
  query: "What is this package about?"
  top_k: 5
  citation_required: true
  scope:
    agent_type: shopping_guide_agent
```

## Boundaries

- No network calls.
- No real vector database.
- No rerank service.
- No Agent deployment.
- Citations come from local package or store metadata.
