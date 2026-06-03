# Examples

This directory contains portfolio-ready examples for HeiTang KB Forge Skill.

HeiTang KB Forge is an Agent-oriented knowledge supply chain foundation. These examples show how raw business materials can be transformed into:

- standardized knowledge packages
- quality reports
- RAG export files
- Agent Template files
- demo / eval reports

## Demo Packages

### demo_product_manager_agent

Shows how product requirements, user feedback, and metric definitions can become a Product Manager Agent knowledge base.

Run in PowerShell:

    .\examples\demo_product_manager_agent\run_demo.ps1

Main output sample:

- chunks.jsonl
- cards.jsonl
- qa_pairs.jsonl
- glossary.jsonl
- manifest.json
- quality_report.json
- ingest_report.md
- embedding_input.jsonl
- retrieval_metadata.jsonl
- citation_map.json
- rag_manifest.json
- agent_profile.yaml
- system_prompt.md
- retrieval_config.yaml
- tools.yaml
- eval_cases.jsonl
- demo_report.md
- demo_manifest.json
- eval_summary.json

### demo_shopping_guide_agent

Shows how product information, selling points, and FAQ materials can become a Shopping Guide Agent knowledge base.

Run in PowerShell:

    .\examples\demo_shopping_guide_agent\run_demo.ps1

### demo_education_tutor_agent

Shows how learning materials, mistake explanations, and learning paths can become an Education Tutor Agent knowledge base.

Run in PowerShell:

    .\examples\demo_education_tutor_agent\run_demo.ps1

## Config Examples

See:

- configs\kb_forge.build.yaml
- configs\kb_forge.batch.yaml

These files are preparation examples for future config-driven execution.

Planned future PowerShell usage:

    python -m heitang_kb_forge.cli run --config .\examples\configs\kb_forge.build.yaml

Current status:

The run --config command is not implemented yet.

## Prompt Profile Examples

See:

- prompt_profiles\product_manager.yaml
- prompt_profiles\shopping_guide.yaml
- prompt_profiles\education_tutor.yaml

These files are preparation examples for future LLM Prompt Profile support.

Current status:

Prompt profiles are examples only and are not wired into the LLM extractor yet.

## Notes

These examples do not call a real LLM, do not write to a vector database, and do not deploy a real Agent.
