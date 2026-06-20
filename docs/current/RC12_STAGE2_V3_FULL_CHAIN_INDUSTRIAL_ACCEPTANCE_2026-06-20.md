# RC12 Stage 2 v3 Full-Chain Industrial Acceptance

Date: 2026-06-20

Scope: Stage 2 final acceptance checkpoint for the v3 product baseline.

## Baseline

- Product architecture: `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
- PRD: `docs/product/PRD_V3_2026-06-19.md`
- Feature acceptance matrix: `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`
- Required chain: document library -> knowledge base -> index layer -> RAG -> orchestration -> document / Skill / Agent / A2A.

## Final Stage 2 Position

Stage 2 is accepted as an industrial local product checkpoint for the v3 full-chain Workbench.

This acceptance covers UI architecture alignment, document library, standard knowledge package / OKF candidate layer, multi-KB and index artifacts, RAG / validation artifacts, orchestration evidence, document generation, Skill factory, Agent Workbench, A2A under Agent Workbench, Artifact Center, Governance & Audit, Provider settings CRUD evidence, Redis/Qdrant configuration validation, parallel task validation, and Windows EXE build.

It does not claim Stage 3 providerized registered-project loading or external project integration. Those remain the next stage and must surface to users only as configurable Provider/OCR/Parser/Embedding/Vector/Exporter/Agent capability enhancements.

## Stage 2 Closure Checkpoints

| Checkpoint | Commit / tag | Result |
| --- | --- | --- |
| UI gap cleanup | `v4.3.0-rc12.9-ui-gap-cleanup` | pass |
| Core evidence operation hardening | `fa0144c` / `v4.3.0-rc12.10-core-evidence-ops-hardening` | pass |
| Stage 2 industrial validation checkpoint | `058d742` / `v4.3.0-rc12.11-stage2-industrial-validation-checkpoint` | pass |
| A2A artifact audit closure | `1fff0fe` / `v4.3.0-rc12.12-a2a-artifact-audit-closure` | pass |
| Artifact Center export closure | `9bcf449` / `v4.3.0-rc12.13-artifact-center-export-closure` | pass |

## Requirement Coverage

| v3 area | Stage 2 status | Evidence |
| --- | --- | --- |
| Workspace | pass | Create, switch, delete, restart consistency, delete protection covered by runtime tests. |
| Document library | pass | Real file/folder/web-link import, append-not-replace behavior, delete persistence, bounded preview. |
| Standard knowledge package / OKF candidate | pass | Export/import/build-KB flow with OKF candidate boundary; no OKF runtime/page claim. |
| Multi-KB | pass | K1/K2/K3 catalog, copy, merge, split, delete, downstream index removal behavior. |
| Index layer | pass | keyword/vector-reference/metadata/citation/memory/index metadata/build report artifacts. |
| RAG / validation | pass | multi-KB retrieval attribution, rerank, citation coverage, conflict, validation history, manual correction evidence. |
| Orchestration | pass | `orchestration/orchestration_plan.jsonl` records document, Skill, Agent, A2A, export, and standard package actions. |
| Document generation | pass | template config, outline, citations, editable Markdown, history snapshots, Markdown/DOCX/PDF/PPTX/JSON/CSV exports. |
| Skill factory | pass | KB generation, external Skill import/localization/fusion, platform/config metadata, validation, export, Agent binding. |
| Agent Workbench | pass | single Agent, complex config, KB/Skill binding, permission audit, dialogue history, export, run history. |
| A2A | pass | A2A remains under Agent Workbench; total workspace, child workspace, rounds, conflict, consensus, report, and audit artifacts are visible. |
| Artifact Center | pass | Generated artifacts are listed, bounded-previewed, bounded-exported, and owned-stage deleted. |
| Governance & Audit | pass | Audit report export, failure records, artifact records, A2A evidence, Provider/exporter/parallel reports. |
| Settings / Provider configuration | pass | LLM/Embedding/Search/Parser/OCR/Redis/Qdrant/Exporter save/load/validate with masked secrets. |
| Parallel task robustness | pass | 8-task local validation, isolated failure, retry recovery, restart-visible reports. |
| Registered projects | pass for Stage 2 boundary | Registry state remains not falsely integrated; Stage 3 owns providerized loading. |

## Validation Evidence

| Check | Result |
| --- | --- |
| UI `flutter analyze` | pass |
| UI runtime truth test | `29 passed` |
| UI remote CI | `27859574131` success |
| Core remote CI | `27858858810` success |
| Core checkpoint | `fa0144cc925838832d537623a94f7740d070a8e7` |
| Redis Docker | authenticated `PING` pass |
| Qdrant Docker | `/readyz` pass, `/collections` pass |
| Windows EXE build | `build/windows/x64/runner/Release/heitang_workbench.exe` built |
| `git diff --check` | pass, CRLF warnings only |
| Added-line no-secret / overclaim / OKF boundary scan | pass |

## Release Boundary

- No stable `v4.3.0` tag was created.
- No GitHub Release was created.
- No OKF runtime, top-level OKF page, arbitrary shell, Computer Use, or unauthorized plugin marketplace was introduced.
- `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md` remains an unrelated pre-existing dirty file and is excluded from Stage 2 commits.

## Stage 3 Entry

Stage 3 may start after this checkpoint. The implementation direction is providerized capability enhancement:

- Parser / OCR appears in Document Library configuration.
- Embedding / vector DB appears in Knowledge Base and Index configuration.
- Exporters appear in Document Generation and Artifact Center export configuration.
- Agent providers, tools, memory, and collaboration options appear in Agent Workbench.
- Provider status, health, failure, rollback, and audit appear in Settings and Governance & Audit.

User-facing UI must not expose the engineering concept of hot-swap external projects.
