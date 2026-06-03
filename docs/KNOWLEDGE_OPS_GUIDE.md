# Knowledge Ops Guide

This guide explains the v1.2.0 Knowledge Ops & Governance Platform.

## Positioning

v1.2.0 focuses on local knowledge package operations and governance. It does not implement a database, remote registry, permission system, SaaS multi-tenancy, Tool Runtime, or real business integration.

## Workspace / Package Registry

The workspace registry manages multiple local knowledge packages.

Generated files:

- workspace_index.json
- package_registry.json
- package_status_report.md

PowerShell example:

    heitang-kb-forge workspace init --workspace .\workspace
    heitang-kb-forge workspace register --workspace .\workspace --package .\output_sample
    heitang-kb-forge workspace status --workspace .\workspace

## Refresh / Staleness Detection

Refresh check detects stale or risky packages and generates a refresh plan.

Generated files:

- source_freshness_report.md
- stale_sources.jsonl
- refresh_plan.json

PowerShell example:

    heitang-kb-forge refresh-check --workspace .\workspace

## Human Review / Curation Loop

Review and curation routes risky chunks, OCR-uncertain content, table best-effort content, or low-confidence LLM outputs into a review queue.

Generated files:

- review_queue.jsonl
- review_decisions.jsonl
- curated_chunks.jsonl
- curation_report.md

PowerShell example:

    heitang-kb-forge review-create --package .\output_sample --output .\review
    heitang-kb-forge review-apply --package .\output_sample --decisions .\review\review_decisions.jsonl --output .\curated_output

## Evaluation Dashboard Data

Evaluation dashboard export stores retrieval, answer, citation, and quality trend data for later dashboard use.

Generated files:

- retrieval_eval_results.json
- answer_eval_results.json
- citation_hit_report.md
- quality_trend_report.md

PowerShell example:

    heitang-kb-forge eval-record --package .\output_sample --eval-results .\eval_results.json --output .\eval_dashboard

## Publish / Export Profiles

Publish profiles generate local publish packages for downstream systems. They do not call external platform APIs.

Supported profiles:

- generic_rag
- langchain
- llamaindex
- openai_files
- dify_import
- fastgpt_import
- coze_knowledge

Generated files:

- export_profile.yaml
- publish_manifest.json
- publish_package/

PowerShell example:

    heitang-kb-forge publish --package .\output_sample --profile generic_rag --output .\publish_output

## Boundaries

v1.2.0 does not do Tool Runtime, permissions, SaaS, real business integration, CRM calls, product system calls, order system calls, or real external platform API calls.
