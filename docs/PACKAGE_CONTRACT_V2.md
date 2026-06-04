# Knowledge Package Contract v2

Contract v2 makes package structure checkable for downstream Skills, RAG pipelines, and Agent workflows.

## Enable During Build

```powershell
heitang-kb-forge build --input .\input --output .\output --contract-version v2 --check-contract
```

## Check Existing Package

```powershell
heitang-kb-forge check-contract --package .\output --contract-version v2
```

## Contract Outputs

- `evidence_map.json`
- `source_inventory.json`
- `quality_report.md`
- `contract_check_result.json`
- `contract_check_report.md`

## Status

- `pass`: required files and readable package structure exist.
- `warning`: optional v2 fields are incomplete but the package is readable.
- `fail`: required files are missing or core JSON/JSONL files are unreadable.

Contract v2 is opt-in and does not force old packages to migrate.
