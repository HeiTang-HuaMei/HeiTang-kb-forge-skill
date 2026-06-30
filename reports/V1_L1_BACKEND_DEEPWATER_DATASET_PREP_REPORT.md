# V1 L1 Backend Deepwater Dataset Preparation Report

Generated: 2026-06-30

## 1. Scope

This report records Phase 1 dataset and workspace preparation for L1 backend deepwater acceptance.

It does not modify product code, does not modify `capability_chain_status.json`, does not push, does not tag, and does not publish a release.

## 2. Output Paths

Dataset root:

`output/v1_l1_backend_deepwater/test_dataset/`

Workspace root:

`output/v1_l1_backend_deepwater/workspaces/`

Dataset manifest:

`output/v1_l1_backend_deepwater/test_dataset/dataset_manifest.json`

RAG/citation assertions:

`output/v1_l1_backend_deepwater/test_dataset/rag_citation_assertions.json`

## 3. Dataset Coverage

| Required dataset item | Status |
| --- | --- |
| Small Chinese Markdown document | present |
| Small English Markdown document | present |
| TXT document | present |
| CSV / TSV table | present |
| XLSX table | present |
| PDF / DOCX | present; raw PDF fixtures retained as evidence, with expected PDF xref spacing classified during whitespace audit |
| Duplicate file names | present |
| Near-duplicate files | present |
| Empty file / damaged file | present |
| Heading hierarchy, quote, numbering, table | present |
| Controlled facts for RAG hit/miss tests | present |
| Controlled citation assertions | present |

## 4. Manifest and Reproducibility

Each dataset case has:

- case id
- relative path
- file kind
- size
- SHA256
- expected behavior

Case count:

`14`

The dataset is written under `output/` and does not touch real user data.

## 5. Gate Result

Phase 1 result:

pass

Allowed next phase:

Phase 2 - Core Import / Build Chain Deep Test

## 6. Current State

`continue_to_next_phase`
