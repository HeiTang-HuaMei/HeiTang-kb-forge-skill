# Config Examples

This directory contains configuration examples for the planned config-driven execution layer.

These files are preparation materials for future configuration-file-driven execution.

## Files

### kb_forge.build.yaml

Example configuration for a single build task.

It describes:

- input path
- output path
- domain
- mode
- LLM options
- RAG export options
- Agent Template options
- Demo Report options

Planned future PowerShell usage:

    python -m heitang_kb_forge.cli run --config .\examples\configs\kb_forge.build.yaml

### kb_forge.batch.yaml

Example configuration for a batch task.

It describes:

- batch input path
- batch output path
- merge_same_sequence option
- RAG export options
- Agent Template options
- Demo Report options

Planned future PowerShell usage:

    python -m heitang_kb_forge.cli run --config .\examples\configs\kb_forge.batch.yaml

## Current Status

These files are examples only.

The run --config command is not implemented yet. Existing commands still use direct CLI flags.

Current PowerShell examples:

    python -m heitang_kb_forge.cli build --input .\examples\demo_product_manager_agent\input --output .\tmp_output

    python -m heitang_kb_forge.cli batch --input .\input --output .\output

## Non-goals

These examples do not implement:

- config inheritance
- environment variable interpolation
- remote config loading
- multi-step pipeline DAG
- Web UI
