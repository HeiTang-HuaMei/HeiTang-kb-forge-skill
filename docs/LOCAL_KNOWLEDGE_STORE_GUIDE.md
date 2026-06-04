# Local Knowledge Store Guide

HeiTang KB Forge v1.4.0 adds an optional local SQLite index for generated knowledge packages.

## Scope

The local store is an index layer. It does not replace the standard knowledge package files and does not write to external databases.

## Commands

```powershell
heitang-kb-forge store init --db .\kb_forge_workspace.db
heitang-kb-forge store import-package --db .\kb_forge_workspace.db --package .\output_sample
heitang-kb-forge store sync-workspace --db .\kb_forge_workspace.db --workspace .\workspace
heitang-kb-forge store list-packages --db .\kb_forge_workspace.db
heitang-kb-forge store query-packages --db .\kb_forge_workspace.db --domain product --agent-type shopping_guide_agent
heitang-kb-forge store package-status --db .\kb_forge_workspace.db --package-id xxx
heitang-kb-forge store export-index --db .\kb_forge_workspace.db --output .\store_export
```

## Config

```yaml
store:
  enabled: true
  db_path: ./kb_forge_workspace.db
  import_package: true
  export_index: true
```

## Export Files

- store_manifest.json
- store_package_index.jsonl
- store_source_index.jsonl
- store_chunk_index.jsonl
- store_status_report.md
- store_query_result.json

## Boundaries

- Uses local SQLite only.
- Does not replace JSONL / JSON package files.
- Does not call vector databases.
- Does not call external services.
