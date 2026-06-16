# Campaign 4 Desktop UI Capability Gap Supplement

Date: 2026-06-16

Status: capability_gap_marking_ready_for_owner_review

Scope: UI-only gap marking for Campaign 4 Desktop UI Layout Alignment. This document does not authorize Campaign 5, Provider Runtime Gate, Campaign 6, Post-9 runtime work, commit, push, tag, or release.

## How to Use This Document

Yellow UI markers mean the visible item is not a fully available runtime capability in Campaign 4. Later Codex runs should use this document to decide which Gate or Campaign owns the missing capability, instead of treating the yellow UI item as complete.

Action classification meanings:

- `enabled_real`: existing real implementation is available in the current scope.
- `disabled_boundary`: visible but intentionally disabled until a Gate, Secret, network permission, Provider, or later campaign is accepted.
- `display_only`: read-only preview, evidence, historical record, or static package view.
- `omitted`: intentionally not exposed as a usable Campaign 4 capability.

## Gap Matrix

| UI area | Yellow marker | Current Campaign 4 behavior | Missing capability | Owner phase | Required validation before removing yellow marker |
|---|---|---|---|---|---|
| Desktop shell / window controls | `display_only` | The top-right title-bar controls for minimize, maximize/restore, and close are visible as Web preview simulation and are kept separate from business toolbars. | Bind the controls to real Windows EXE window behavior without disturbing sidebar, status bar, content scrolling, or desktop grid expansion. | Campaign 9 EXE Packaging | Desktop EXE smoke tests for minimize, maximize, restore, and close; resize layout checks at 1280/1440/1600/1920 widths; no clipping or large-empty-space regressions. |
| Dashboard / Provider boundary | `disabled_boundary` | Provider-related actions stay disabled and show local-first policy. | Formal Provider Runtime with profile, endpoint/model selection, Secret injection, opt-in network, timeout, retry, fallback, cancellation, health check, redaction, and cost evidence. | Provider Runtime Gate | Provider contract tests, opt-in live smoke, redaction/Secret leakage tests, offline and invalid-credential tests, cost/token evidence, Windows compatibility. |
| Dashboard / external verification | `disabled_boundary` | External fact comparison is not executed. Web link import remains separate from external verification. | External Source Verification Gate and evidence source policy. | Provider Runtime Gate or later Owner-approved verification gate | Network consent tests, source provenance evidence, failure handling, contradiction/freshness report tests. |
| Import and Parsing / OCR | `disabled_boundary` when OCR backend is not fully available | OCR settings are visible as parser configuration boundary. | OCR runtime packaging and verified local execution path if chosen for EXE. | Future Owner-approved implementation inside import/parser scope | OCR fixture tests, local file tests, recovery tests, Windows dependency packaging tests. |
| Knowledge Base / vector Provider | `disabled_boundary` | Local knowledge package and local index evidence are visible; external vector provider is not connected. | Accepted vector provider runtime or local vector DB runtime contract. | Provider Runtime Gate or later storage/provider delta | Provider unavailable behavior, offline behavior, index build/read tests, migration and storage path tests. |
| Knowledge Base / external facts | `disabled_boundary` | Local validation only; external comparison is not run. | External comparison workflow and trust policy. | External Source Verification Gate | Freshness/contradiction tests, source trust policy tests, opt-in network evidence. |
| Retrieval and Verification / external fact check | `disabled_boundary` | Retrieval and verification operate against existing local evidence only. | External factual comparison and source evidence pipeline. | External Source Verification Gate | Query-to-source provenance, opt-in network, external unavailable behavior, redaction tests. |
| Document Generation / PDF and PPTX render boundary | `disabled_boundary` where render validation is shown as pending | Markdown/DOCX/PDF/PPTX ownership is in the module, but complete render/export validation may remain boundary-marked. | Full renderer pipeline and artifact validation for every export format. | Campaign 4 acceptance delta if Owner requires, otherwise Campaign 8 review | Export round-trip, visual render checks, corrupt output tests, Windows path/encoding tests. |
| Skill Factory / advanced and composition entries | `display_only` | Book/doc to Skill, KB to Skill, Skill template, and package preview are represented; advanced composition remains a preview boundary. | Full advanced customization, import existing Skill, multi-Skill composition UX and contracts if not already covered by real evidence. | Campaign 6 only if Agent binding needs it, otherwise future Skill delta | Skill import/export tests, composition contract tests, governance report tests. |
| Agent Factory / input mapping | `display_only` | Agent Creation Package input mapping, config declaration preview, package preview, and export boundary are visible. | Agent creation, editing, saving, versioning, and binding editors. | Campaign 6 Agent Foundation | Agent CRUD tests, KB binding, multi-Skill binding, provider binding, package export/import round-trip. |
| Agent Factory / runtime config | `omitted` | Runtime config appears only as boundary evidence such as `runtime_boundary.json`. | Agent Runtime, sessions, execution, memory, collaboration, orchestration. | Post-9 Roadmap unless Owner creates a later runtime campaign | Runtime tests, isolation tests, session audit, memory/collaboration tests. |
| Agent Factory / save and versioning | `omitted` | Save Agent definition and version management are not usable. | Agent definition persistence, versions, restore, archive/delete. | Campaign 6 Agent Foundation | CRUD/version/restore tests, migration compatibility, UI journey tests. |
| Audit and Reports / report archive | `display_only` or `enabled_real` only for report archive manifest | Audit page does not perform unified export for documents, Skill, or Agent packages. | Module-specific export completion remains owned by each module. | Owning module or Campaign 8 review | Per-module export tests and artifact inventory tests. |
| Settings / Provider and storage | `disabled_boundary` | Provider, vector DB, API key, cloud backup, and cache cleanup boundaries are visible with yellow markers. | Provider runtime, storage provider runtime, Secret injection, cloud backup. | Provider Runtime Gate and Campaign 7 configuration engineering | Secret handling, provider profile, storage migration, offline behavior, config precedence tests. |
| Settings / diagnostics | `display_only` | Developer diagnostics are read-only technical evidence. | Editable diagnostic/runtime control surface if ever approved. | Future Owner decision | Access-control, audit, and supportability tests. |
| Post-9 runtime family | `omitted` | Memory Runtime, Collaboration Runtime, Agent Teams, Subagent, Computer Use, Sandbox, A2A, Graphify are not usable entries. | Full post-9 runtime capabilities. | Post-9 Roadmap only | Separate Owner-approved roadmap and acceptance gates. |

## Required Follow-Up Before Any Yellow Marker Is Removed

1. Identify the owning Gate or Campaign.
2. Confirm Owner authorization for that exact scope.
3. Implement only the approved capability.
4. Add real tests and evidence for the capability.
5. Run runtime/provider overclaim scans.
6. Update the UI classification from yellow only after evidence passes.
7. Preserve Campaign 4 historical records and do not rewrite acceptance history.

## Current Stop Point

The UI may show yellow markers for incomplete, boundary, display-only, or omitted capabilities. That is intentional. Removing a yellow marker without accepted implementation evidence is a governance violation.
