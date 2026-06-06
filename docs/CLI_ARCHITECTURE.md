# CLI Architecture

Current version: `2.9.0-alpha.1`

## Purpose

The CLI is the standard headless entrypoint for HeiTang KB Forge. It must remain usable by local users, config-driven runs, pipelines, desktop UI controllers, and Agent / Skill callers.

## Entry Point

`heitang_kb_forge/cli.py` is a small compatibility entrypoint. It must stay below 5 KB and preserve:

- `python -m heitang_kb_forge.cli`
- the `heitang-kb-forge` console script
- existing imports of `app`, `_build_package`, and `V21Options`

## Command Modules

Command-facing code belongs under `heitang_kb_forge/cli_commands/`.

Each module should stay below 30 KB:

- `build_commands.py`
- `batch_commands.py`
- `pipeline_commands.py`
- `quality_commands.py`
- `release_commands.py`
- `regression_commands.py`
- `platform_commands.py`
- `provider_commands.py`
- `workspace_commands.py`
- `skill_commands.py`
- `agent_commands.py`
- `rag_commands.py`
- `doctor_commands.py`
- parser backend reliability commands may stay in the compatibility runtime during v2.8, but future CLI convergence should move them into a dedicated parser command module.
- knowledge runtime commands may stay in the compatibility runtime during v2.9, but future CLI convergence should move them into a dedicated runtime or retrieval command module.

## Compatibility Runtime

`heitang_kb_forge/cli_runtime.py` preserves existing command behavior during the v2.5.1+ convergence checkpoints. It is not the long-term home for new commands.

Future command work must migrate behavior out of the compatibility runtime into the matching `cli_commands/*.py` module.

## Adding Commands

When adding or changing a command:

1. Put the Typer command function in the matching `cli_commands` module.
2. Keep business logic in domain modules, not in the CLI layer.
3. Register the command through the shared CLI app.
4. Add or update narrow CLI tests.
5. Keep `cli.py` below 5 KB.
6. Keep every `cli_commands/*.py` file below 30 KB.
7. Do not recreate `cli_commands/legacy.py`.

## Release Gate

`release-readiness` must fail if:

- versions are not aligned
- capability docs are missing
- CI workflows are missing
- README overclaims planned capabilities
- suspected secrets are present
- quickstart output is incomplete
- doctor output reports failure
- `cli_commands/legacy.py` exists and is oversized

## Boundaries

The CLI must not:

- call real LLM APIs by default
- call real platform runtimes
- publish to Xiaohongshu / XHS
- start a real MCP Server
- write to a real vector database
- depend on the desktop UI
- enable parser backend mode by default
- bypass trusted KB export gates for parser-backed draft packages

