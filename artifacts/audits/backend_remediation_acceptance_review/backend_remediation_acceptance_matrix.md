# Campaign 1 Backend Remediation Acceptance Matrix

Verdict: `accepted`

Campaign 1 is accepted for sequence movement because every required backend has an explicit decision and evidence. This does not mean every backend is a primary runtime backend, and it does not prove EXE bundling.

| Backend | Decision | Runtime/check/smoke | Accepted boundary |
| --- | --- | --- | --- |
| PaddleOCR | `real_integration` | dependency `available`, runtime `ready`, smoke `pass`, real run `pass` | OCR runtime for `.pdf` and `.png`; optional dependency, not EXE bundled |
| MinerU | `real_integration` | dependency `available`, runtime `ready`, smoke `pass`, real run `pass` | DU runtime for `.pdf` and `.png`; table/figure/formula quality remains runtime-dependent |
| Docling | `real_integration` | dependency `available`, runtime `ready`, smoke `pass`, real run `pass` | Optional runtime proven on `.md` and `.txt`; broader formats require revalidation |
| Marker | `real_integration` | dependency `available`, runtime `available`, smoke `passed`, real run `pass` | PDF markdown/layout runtime, no `--use_llm`, workspace-local cache; license and EXE bundling separate |
| OpenDataLoader | `real_integration` | dependency `available`, runtime `ready`, smoke `pass`, real run `pass` | PDF markdown/json conversion; project-local Java remediation |
| Surya | `needs_strengthening` | dependency `missing`, runtime `skipped`, smoke `blocked` | Accepted only as non-primary benchmark/reference boundary |
| Unstructured | `real_integration` | dependency `available`, runtime `ready`, smoke `pass`, real run `pass` | Basic `.md/.txt` parser only, not full DU backend |
| fallback parser | `real_integration` | dependency `bundled`, runtime `ready`, smoke `pass`, real run `pass` | Built-in basic text fallback, not full DU backend |

## Guardrails

- `structured_skipped` is fallback behavior only.
- `dependency_missing` is not `real_integration`.
- A planned adapter is not a real adapter.
- Integration decision reports do not replace UI impact evidence.
- Surya cannot be displayed as a ready runtime backend.

## Transition

Campaign 1 can count as accepted. Campaign 3 still cannot open until Campaign 2 is also accepted by `PRE_CAMPAIGN_ACCEPTANCE_GATE.md`.

## Goal Drift Review

- Goal downgrade detected: `false`
- Goal still active: `true`
- Final target not downgraded: `true`
- Not goal complete: `true`
- Remaining gap: UI workflow, Core Bridge execution acceptance, configuration, Full Gate, EXE packaging, and release are not accepted.
