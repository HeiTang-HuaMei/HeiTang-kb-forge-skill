# Campaign 2 Knowledge Supply Chain Acceptance Matrix

Verdict: `accepted`

Campaign 2 is accepted for sequence movement because it has real multi-file evidence across the DU -> KB -> Package -> Search -> Report Export chain. Report export is included as governed chain evidence; it is not used as a substitute for the whole campaign.

## Reviewed Runs

| Run | Role |
| --- | --- |
| `real_mixed_e2e_20260612_102508` | TXT/PDF/PNG/Markdown through batch import, DU, KB, package, and query |
| `office_table_e2e_20260612_105706` | XLSX/CSV/Markdown through preflight, DU, KB, package, verification, and methodology extraction |
| `report_export_20260612_135600` | Governed report export covering required stages and excluding logs/cache/raw input |

## Stage Verdicts

| Stage | Verdict | Evidence note |
| --- | --- | --- |
| `batch-import-documents` | accepted | Multi-file import evidence plus duplicate/unsupported failure isolation tests |
| `preflight-documents` | accepted | `document_preflight.json` and `backend_recommendation.json` consumed by DU |
| `select-document-backend` | accepted | Core selection via backend recommendations and runtime route consumption, not standalone CLI |
| `run-document-understanding` | accepted | Real mixed run success `4/4`; office/table run success `3/3` |
| `build-knowledge-base` | accepted | KB reports, source trace, quality reports, evidence maps, retrieval index |
| `build-knowledge-package` | accepted | Package manifest/report, contract pass, standard files present |
| `build-search-index` | accepted | Retrieval index generated and queried without vector DB |
| `export-knowledge-report` | accepted | Governed export command path exists and is covered by report export tests/artifacts |
| `export-workflow-report` | accepted | Workflow export manifest copied openable reports and excluded runtime streams |

## Guardrails

- A single CLI pass cannot replace campaign acceptance.
- Report export cannot replace Campaign 2 acceptance.
- The chain works without LLM.
- Keyword/structured retrieval works without vector DB.
- Full desktop UI workflow, Core Bridge acceptance, configuration, Full Gate, and EXE remain later campaigns.

## Transition

Campaign 2 can count as accepted. Campaign 3 is allowed next only because Campaign 1 is also accepted by the pre-campaign gate.

## Goal Drift Review

- Goal downgrade detected: `false`
- Goal still active: `true`
- Final target not downgraded: `true`
- Not goal complete: `true`
- Remaining gap: Campaign 3 and later campaigns remain incomplete.
