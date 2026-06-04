# Desktop App Guide

v1.2.3 freezes the short-term desktop UI information architecture.

The desktop UI is a presentation layer. The core remains a headless, agent-callable knowledge supply-chain Skill.

## What It Does

- wraps the existing `heitang-kb-forge` CLI
- supports build, batch, and pipeline workflows
- shows the command preview before execution
- keeps execution local
- provides a stable 11-page navigation shell
- reserves UI space for Knowledge Lifecycle, SQLite / Vector Store, Agent Connector, and Retrieval Runtime

## What It Does Not Do

- does not replace the Python CLI
- does not move core logic into React or Tauri
- does not call external APIs by itself
- does not write to a real vector database
- does not deploy a real Agent
- does not add a Web UI or remote scheduler
- does not create a UI-only package format

## Information Architecture

The desktop navigation is frozen around 11 pages:

1. Dashboard
2. Build Package
3. Batch Processing
4. Workspace
5. Lifecycle Update
6. Quality Gate
7. Package Detail
8. Ask Runtime
9. Publish Export
10. Planning Readiness
11. Settings

Future work should fill these pages rather than restructure navigation.

## v1.2.4 Polish Notes

v1.2.4 fixes UI linkage and hierarchy without changing the frozen page structure:

- TopBar, Sidebar, pages, and Settings share one locale source.
- Settings uses the current global locale and no longer shows a stale `zh-CN` value when English is selected.
- Readonly runtime information is visually distinct from editable configuration.
- Future-reserved storage, vector store, and Agent connector fields are marked as reserved.
- Desktop UI remains a presentation layer over the Skill / CLI / Pipeline.

## Run In Development

```powershell
.\packaging\desktop\dev_tauri.ps1
```

## Build Windows EXE

```powershell
.\packaging\desktop\build_tauri.ps1
```

The generated installer is produced by Tauri under `desktop\tauri\src-tauri\target` when the local Node.js and Rust toolchains are installed.
