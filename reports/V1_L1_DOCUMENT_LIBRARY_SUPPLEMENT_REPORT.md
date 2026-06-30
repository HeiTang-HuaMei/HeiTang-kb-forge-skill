# V1 L1 Document Library Supplement Report

Generated: 2026-06-30

## 1. Scope

This report confirms that Document Library evidence is based on real file import, parsing, splitting, failure recording, and trace artifacts.

## 2. Test Input

Dataset:

`output/v1_l1_backend_deepwater/workspaces/phase2_with_failure_input/`

Representative files:

- `01_cn_control.md`
- `02_en_control.md`
- `03_plain_fact.txt`
- `07_control.docx`
- `08_control.pdf`
- `corrupt.pdf`
- `empty.md`

## 3. Execution Path

Core build path:

`python -m heitang_kb_forge.cli build --input <dataset> --output <artifact> --rag-export --retrieval-index --evidence-gate --run-manifest --progress-jsonl --contract-version v2`

Existing L1 report:

`reports/V1_L1_BACKEND_DEEPWATER_IMPORT_BUILD_REPORT.md`

## 4. Evidence Paths

Primary artifact:

`output/v1_l1_backend_deepwater/import_build_artifacts/with_failure_files/`

Key files:

- `manifest.json`
- `source_trace.json`
- `source_inventory.json`
- `evidence_map.json`
- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `progress_events.jsonl`
- `error_report.json`

## 5. Observed Values

| Check | Result |
| --- | --- |
| Real file group imported | pass, `source_count = 7` |
| Successful parsed sources | pass, md/txt/docx/pdf sources produced chunks |
| Documents split | pass, `chunk_count = 5` |
| Abnormal file friendly failure record | pass, `error_report.json` records corrupt PDF failure |
| Empty file warning | pass, manifest warnings record empty source |
| `source_trace.json` | present |
| `manifest.json` | present |
| Catalog-equivalent inventory | present as `source_inventory.json` |
| `capability_chain_status.json` pollution | not observed |

## 6. Result

Status:

pass

Risk:

P0 = 0, P1 = 0, P2 = 0, P3 = 0

Fix required:

No.

## 7. Safety Checks

`capability_chain_status.json` diff:

empty

ready-claim scan:

clean / non-claim only after classification
