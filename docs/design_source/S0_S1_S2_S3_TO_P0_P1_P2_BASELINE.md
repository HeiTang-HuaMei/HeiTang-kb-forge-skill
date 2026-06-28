# S0/S1/S2/S3 to P0/P1/P2 Product Baseline Mapping

## Purpose

This file maps module-level S0/S1/S2/S3 stabilization targets onto the product P0/P1/P2 capability layers, feature checklist, user paths, and baseline owners.

It is a target and requirement map. It is not a pass report, release claim, package-candidate claim, or Final Owner Review result.

## Boundary

This mapping must not be used to:

- reopen P0, P1, or P2 gates;
- change `capability_chain_status.json`;
- claim UI closure passed;
- claim package candidate passed;
- claim Final Owner Review readiness.

It only clarifies what each module must mean in product language and where the work belongs.

## Severity Meaning

| Level | Meaning | Required landing |
| --- | --- | --- |
| S0 | Main user chain is broken, unsafe, falsely successful, leaks secrets, corrupts source assets, or cannot recover from a basic lifecycle action. | P0 user path and basic lifecycle must be repaired or explicitly blocked before higher-layer claims. |
| S1 | Product truth can drift: IDs, bindings, source trace, operation history, restart recovery, UI state, or artifacts disagree. | P1 stabilization must make data, UI, artifacts, and restart truth consistent before P2 expansion. |
| S2 | Product completeness and usability gaps: clearer states, richer recovery, better edge handling, visual clarity, user wording, and cross-page refresh. | P2 UI/product closure or feature-hardening backlog, depending on whether it blocks ordinary use. |
| S3 | Advanced polish, scale, convenience, automation, marketplace, or broad industrial expansion. | P2+ or later backlog unless it becomes a user-path blocker. |

## P0/P1/P2 Product Layers

| Layer | Product meaning | Exit target |
| --- | --- | --- |
| P0 | A single local user can complete the basic product chain with real workspace data. | Create/select workspace, import sources, view document library, generate/delete/export KB, generate basic document/Skill/Agent output, and recover after restart without corrupting source assets. |
| P1 | Product truth is reliable across modules. | Real IDs, source trace, artifact catalog, event ledger, operation history, restart recovery, citation/skill trace, and external-service boundaries agree. |
| P2 | Industrialized product behavior and user-visible closure. | Multi-KB governance, workgroup/Agent expansion, connector/service governance, diagnostics, long tasks, anti-happy-path E2E, and running UI closure are stable. |

## Module Landing Map

| Module / route | P0 target for S0 | P1 target for S1 | P2 / backlog target for S2/S3 |
| --- | --- | --- | --- |
| Workspace | Create, switch, delete/clear, recreate, and restart-recover the current workspace without losing unrelated user data. | Workspace manifest, active workspace, operation records, and UI state must agree after restart. | Multi-workspace governance, dirty-data compatibility, concurrent-window state consistency. |
| Import materials | File, folder, and link entries are understandable; local file/folder import works; failed or unavailable link import explains next action. | Deduplication, parse status, source manifest, document records, and operation records use real current-workspace data. | Connectors, advanced import sources, failure-injection recovery, larger mixed sample sets. |
| Document library | Parsed sources appear as real documents with preview, summary/body, or clear "no content" state. | `ParsedDocument`, source IDs, source trace, parse failure records, and UI preview agree. | Large/complex document UX, OCR/enhanced parsing states, compatibility with old documents. |
| Knowledge base | Generate, view, delete, export, and restart-recover KBs; deleting a KB must not delete source documents. | KB catalog, chunks, source map, source trace, artifact records, and operation history must agree. | Multi-KB governance, merge transaction safety, versioned KBs, conflict marking, retrieval benchmark. |
| KB merge | Merge must create a new KB, not update or overwrite originals. | Parent KBs, source documents, dedupe counts, conflict marks, and citation lineage must be persisted and traceable. | Interrupted merge recovery, duplicate merge handling, cross-KB conflict review, version policy. |
| KB validation | User selects KBs, enters questions, receives answer, basis sources, discovered issues, and suggested supplemental data. | Validation records must trace to selected KBs, chunks, source documents, evidence gaps, and retry history. | Regression benchmark, retrieval comparison, nightly validation, large multi-KB evaluation. |
| Document generation | User selects KB, names document, chooses type/template/format, generates, opens, exports, deletes, and restart-recovers. | Selected KB IDs, citations, generation manifest, edit history, export manifest, artifact catalog, and event ledger agree. | Smart writing workbench, Office/workgroup writing, richer templates, multi-agent writing orchestration. |
| Skill | User can generate Skill from KB, import Skill, name, view, export, delete, and bind it to Agent without exposing internal tiers. | Skill IDs, source KB IDs, source trace, validation report, export manifest, Agent binding manifest, and restart truth agree. | Method-to-skill extraction, native Skill library, Skill evolution, marketplace/recommendation UX. |
| Agent | User can create/name assistant, bind KB/Skill, ask in-scope questions, see sources, clear/delete, and restart-recover. | Agent profile, bound KB/Skill IDs, conversation, citation trace, skill rule trace, memory scope, and event records agree. | Workgroups, A2A, Office/Research agents, advanced memory consolidation, tool execution expansion. |
| Task workbench | User can see tasks, progress, success/failure, retry, ignore/clear history, and export support diagnostics. | Task records, artifact lifecycle, event ledger, failure reasons, retry records, and UI state agree. | Remote task control, parallel/long-running tasks, resource monitoring, workgroup task orchestration. |
| Results / artifacts | Ordinary results show only four types: KB, document, Skill package, Agent package. | Artifact catalog separates user results from audit/support/diagnostic evidence and preserves open/export/delete truth. | Rich metadata detail, support bundle workflow, observability dashboards. |
| Settings | User sees only required external service configuration and test states; local baseline is not blocked by missing external services. | Connection status, secret boundaries, optional-enhancement states, and failure explanations use product language. | Connector industrialization, provider governance, advanced service routing, enterprise policy controls. |

## Feature Checklist Landing

| Product feature | P0 must make possible | P1 must make true | P2 must make robust |
| --- | --- | --- | --- |
| Workspace lifecycle | Workspaces can be created, deleted/cleared, recreated, selected, and restored. | Manifest and UI agree after restart and after failed operations. | Old/dirty workspaces and concurrent windows do not corrupt state. |
| Source ingestion | Files/folders enter the current workspace and show parse progress or failure. | Dedup, source manifest, parsed document records, and operation records match. | Links/connectors and larger mixed samples have explainable fallbacks. |
| KB lifecycle | KBs are generated from selected sources and can be viewed, exported, deleted, and restored. | Source trace, chunks, citations, artifact records, and delete/export truth match. | Merge/version/conflict/retrieval behavior is traceable and interruption-safe. |
| Verification | Selected KBs can be validated with user questions and saved results. | Evidence, source snippets, gaps, retries, and validation history match selected KBs. | Benchmarks and regression runs detect retrieval drift. |
| Document output | KB-grounded documents are generated with name/type/template/format and visible save location. | History, edits, export body, citations, and artifact catalog match. | Office formats, workgroup writing, and richer templates are stable. |
| Skill output | KB-generated/imported Skills are usable assets with view/export/delete. | Real skill IDs, source trace, validation, binding, and restart truth match. | Method extraction and Skill library expansion are reliable. |
| Agent output | Bound assistants answer within knowledge boundaries and show sources. | Profile, binding, memory, conversation, citation, and skill traces match. | Workgroup/A2A/role agents operate without breaking single-Agent truth. |
| Results and recovery | User results are visible, openable/exportable/deletable, and failures have next actions. | Results, operation history, event ledger, diagnostics, and restart truth match. | Support packages and observability help diagnose without polluting ordinary results. |

## User Path Landing

| User path | Required product behavior | S-level red lines |
| --- | --- | --- |
| Workspace recovery | Delete/clear workspace -> recreate -> import source -> restart -> same active workspace and data truth. | S0 if workspace cannot be recreated or restart loses/corrupts user data. S1 if UI and manifest disagree. |
| Materials to document library | Add file/folder/link -> dedupe -> parse -> organize -> document library shows real sources. | S0 if valid local import cannot proceed. S1 if backend has sources but UI shows false empty or placeholders. |
| Document library to KB | Select sources -> generate KB -> view sources/chunks -> export/delete -> restart. | S0 if generated KB is unusable or delete corrupts sources. S1 if chunks/source trace/catalog drift. |
| KB merge | Select KBs -> merge creates new KB -> source relationship visible -> delete merged KB safely. | S0 if original KBs are overwritten/deleted. S1 if lineage, dedupe, conflicts, or citations cannot be traced. |
| KB validation | Select KB -> ask question -> answer/basis/problems -> save/retry -> source snippet visible. | S0 if out-of-scope questions fabricate answers. S1 if saved validation uses wrong KB or untraceable evidence. |
| Document generation | Select KB -> name document -> choose type/template/format -> generate -> open/export/delete -> restart. | S0 if export succeeds falsely or document is invisible. S1 if selected KB, citations, history, and export body drift. |
| Skill | Select KB/import Skill -> name -> view/export/delete -> bind Agent. | S0 if Skill cannot be used or delete is unsafe. S1 if IDs/source trace/bindings are fake or inconsistent. |
| Agent | Create assistant -> bind KB/Skill -> ask in-scope/out-of-scope -> sources/refusal -> save/delete/restart. | S0 if Agent answers outside bound KB as grounded truth. S1 if profile, binding, conversation, and trace disagree. |
| Results and records | Generate assets -> results show four user types -> open/export/delete -> operation records clear/retry/export diagnostics. | S0 if ordinary results mix engineering evidence as user assets. S1 if artifact and operation truth disagree. |
| Settings independence | Clear external service config -> local import/organize/basic KB/results still work. | S0 if configuration page blocks local baseline. S1 if test states or secrets are shown incorrectly. |

## Baseline Ownership

| Baseline file | Owns |
| --- | --- |
| `PRODUCT_SCOPE.md` | Product boundary, top-level navigation, ordinary result types, forbidden user-visible implementation terms. |
| `USER_TASK_CHAIN_DESIGN.md` | Continuous user paths, reverse trace paths, non-happy-path actions, running UI path expectations. |
| `IMPLEMENTATION_ROADMAP.md` | Implementation and repair order from local baseline to UI closure and package candidate. |
| `WORKSPACE_AND_DATA_MODEL_DESIGN.md` | Product object identity, workspace data semantics, and persistence model. |
| `DATA_SCHEMA_AND_STORAGE_SPEC.md` | File-level storage structures and required persisted fields. |
| `SERVICE_CONTRACTS.md` | Runtime/controller API contracts that must preserve product truth. |
| `UI_STATE_SPEC.md` | Empty, loading, success, failed, disabled, and next-action UI states. |
| `ERROR_AND_RECOVERY_SPEC.md` | Failure explanation, retry, rollback, and recovery behavior. |
| `TEST_STRATEGY_AND_ACCEPTANCE_MATRIX.md` | Required validation style: running UI, backend truth, restart consistency, and non-happy-path coverage. |
| `CURRENT_PRODUCT_BASELINE.md` | Current canonical product baseline pointer and this S-level landing map. |
| `../product/FEATURE_ACCEPTANCE_MATRIX.md` | Stable pointer to feature acceptance matrix plus this S-level target map. |
| `../audits/current/*_module_s0_s1_stabilization_registry.md` | Module-specific S0/S1 evidence and repair registries. |

## Interpretation Rule

When a module has an S0/S1/S2/S3 item, first decide the affected user path, then place it by product layer:

```text
Does it break or endanger the ordinary task chain? -> S0 -> P0 target.
Does it make UI/backend/artifact/restart truth inconsistent? -> S1 -> P1 target.
Does it reduce usability, recovery clarity, or cross-page quality? -> S2 -> P2 closure target.
Is it advanced scale, marketplace, automation, or convenience? -> S3 -> P2+ backlog.
```

The implementation should then update the smallest owning baseline, feature checklist, user path, service contract, or test file needed to make the target explicit before coding.
