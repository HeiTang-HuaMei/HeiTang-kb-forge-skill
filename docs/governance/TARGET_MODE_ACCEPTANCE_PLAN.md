# Target Mode Acceptance Plan Lock

This document locks the target-mode acceptance plan for HeiTang KB Forge. It is a long-lived governance rule, not run evidence.

## Non-Downgrade Guard

- `final_target_not_downgraded = true`
- `remaining_gap` must stay visible until every acceptance section below has direct evidence.
- `next_required_e2e_step` must name the next missing product workflow, not a smaller local shortcut.
- `not_goal_complete = true` until the installed Windows product passes desktop UI, runtime, diagnostics, and packaging acceptance.

Do not describe this target as lightweight, minimal, demo-ready, preview-only, sample-only, fixture-only, contract-only, a planned adapter, a stub, or a skeleton unless the four non-downgrade fields above are present.

## Final User Acceptance

A downloaded install must let the user:

- open the full desktop UI, complete first-run setup, choose a workspace path, and view system, backend, DB, vector DB, API, and proxy status;
- batch import PDF, DOCX, PPTX, XLSX, Markdown, TXT, HTML, images, scanned documents, mixed-layout documents, folders, and multiple files;
- run automatic preflight for file type, scanned status, tables, images, formulas, multi-column layout, OCR need, layout need, table extraction need, and backend recommendation;
- check, smoke, skip, repair, and run PaddleOCR, MinerU, Docling, Marker, OpenDataLoader, and fallback parser through the unified backend contract;
- run Document Understanding with OCR, layout parsing, reading order, table extraction, figure extraction, formula recognition, caption recognition, header/footer recognition, block normalization, source trace, confidence, risk, and error reports;
- build single and multi knowledge bases with inventory, blocks, chunks or sections, metadata, source trace, evidence map, quality report, package, and package manifest;
- use keyword, structured, source trace, document inventory, and metadata search without requiring LLMs, embeddings, or vector DBs;
- configure API base URL, reverse proxy, API key, model, embedding model, rerank model, SQLite, PostgreSQL, Redis, vector DB, and workspace path;
- export knowledge packages, parsing reports, OCR reports, backend smoke reports, quality reports, governance reports, and failure reports;
- diagnose backend availability, dependencies, adapter smoke, DB, Redis, vector DB, API/proxy connectivity, workspace health, and diagnostics bundles;
- install and run a Windows EXE, installer, and portable package with first-run setup, dependency checker, and diagnostics report.

The following do not satisfy final acceptance: CLI-only execution, development-environment-only execution, static web preview, fixture-only display, sample-only display, reference-only runtime claims, or planned adapter readiness.

## Execution Order

1. Strengthen already selected Document Understanding and OCR backend projects before handling unrelated integrations.
2. Connect strengthened parsing and OCR backends into batch import, Document Understanding, knowledge base build, knowledge package, search index, and report export.
3. Process not-yet-integrated projects one by one. Each project must receive an `integration_decision_report.json` and `.md` with exactly one decision: `real_integration`, `reference_only`, `needs_strengthening`, or `stop_integration`.
4. Confirm UI impact for every backend and integration decision, including truthful display of dependency status, smoke status, run status, skipped status, failure reason, repair suggestion, and report export.
5. Complete the Local Core Bridge with allowlisted actions only, path validation, timeout, structured errors, audit logs, and no arbitrary shell execution.
6. Complete the configuration system for API/proxy, DB, Redis, vector DB, workspace path, settings export/import, diagnostics, and disabled-LLM operation.
7. Run the full validation campaign only after integration and UI confirmation are complete.
8. Build and accept the Windows EXE, installer, portable package, first-run setup, default workspace, default SQLite, dependency checker, backend diagnostics, config wizard, and diagnostics report.
9. Only after full target acceptance: final commit, push, tag, GitHub Release, Workspace status sync, HANDOFF sync, task log sync, and pitfall log sync.

## Already Absorbed: Do Not Redo

Do not reprocess these as new runtime integrations unless final Document Understanding or Knowledge Package compatibility tests prove breakage:

- Anything2Skill absorbed as L3/L4 contract and capability inspiration only.
- SkillX absorbed as L3/L4 contract and capability inspiration only.
- Anthropic Skills / skill-creator absorbed as L3/L4 packaging and governance inspiration only.
- P2.2 Skill Governance / Skill Suite main chain.

These are not bundled runtimes, vendored code, providers, accounts, APIs, or proof of external Skill learning E2E.

## UI Truthfulness

UI must not:

- show `reference_only` as executable;
- show skipped as passed;
- show planned adapter as real adapter;
- show missing dependency failure as success;
- show UI action wiring as full UI workflow completion;
- show static web preview as desktop runtime acceptance.

## Current Ledger Alignment

As of this plan lock:

- Document backend strengthening, batch import, preflight, Document Understanding, KB build, search index, verification, methodology extraction, Skill generation, Agent creation/binding, external evidence verification, progress events, and report export have partial or E2E evidence in the ledger, but each still preserves `not_goal_complete`.
- Skill import/decomposition/learning, owned Skill generation, multi-agent workflow, API/proxy config, DB/Redis/vector DB config, and EXE packaging remain incomplete or contract-only in the ledger.
- `ui_core_bridge = ui_connected` proves only action connection and truthful state presentation. It does not prove the full desktop UI workflow.
- `exe_packaging = not_started` remains true until install, launch, and doctor acceptance run against the Windows package.

## Next Required E2E Gap

Follow the campaign order without redoing already absorbed projects. After the governed report export E2E, the next work is Section 5 / Campaign 3 project-by-project handling, starting with LLM Wiki v2. Later UI truthfulness, configuration diagnostics, Full Gate, and EXE acceptance must not be skipped.
