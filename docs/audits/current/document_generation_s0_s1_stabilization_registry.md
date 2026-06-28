# Document Generation S0/S1 Stabilization Registry

## Scope

```text
status = blocked_requires_s0_s1_stabilization
module = Document Generation
goal = stabilize existing KB-grounded document pipeline before smart writing workbench expansion
boundary = no Final Owner Review Gate, no package candidate build, no P2 reopen, no capability_chain_status.json change
```

Current document generation capability is not missing. The existing product chain covers:

```text
Knowledge Base
-> chunks/cards/qa_pairs/query result
-> generated Markdown / reading notes
-> generation_manifest.json
-> outline.json
-> citations.json
-> document_validation_report.json
-> document_history
-> edit
-> export
-> Artifact Catalog
-> Event Ledger
-> restart recovery
```

Current gap:

```text
The implementation is a KB-grounded local document pipeline, not a full smart writing workbench.
It still needs S0/S1 hardening for selected KB truth, source trace precision, template effect, export/history/delete consistency, and restart recovery.
```

## Capability Landing

```text
P0 affected = document_generation
P1 affected = document_template_registry, office_artifact_adapter
P1/P2 related = citation verification, multi-KB governance, artifact lifecycle, versioned knowledge governance, office agent/workgroup flows
```

This registry does not reopen P0/P1/P2 gates. It records stabilization work needed before claiming product-level closure.

## S0 Defects

These are S0 only when confirmed by reproduction evidence.

```text
DOC-GEN-S0-001 | A valid current KB cannot generate a document.
DOC-GEN-S0-002 | Generated document is invisible in UI/runtime state or cannot be opened.
DOC-GEN-S0-003 | Export reports success but output file is missing, empty, corrupted, or cannot be opened.
DOC-GEN-S0-004 | Edited document is saved, but export uses the stale pre-edit body.
DOC-GEN-S0-005 | Delete/clear history is unsafe: deleted document/history reappears after restart or deletes unrelated KB/source assets.
DOC-GEN-S0-006 | Artifact Catalog or Event Ledger misses generate/edit/export/delete events required for lifecycle truth.
DOC-GEN-S0-007 | Strict citation/source mode succeeds with no usable source evidence.
DOC-GEN-S0-008 | UI selects one KB but generated document uses another KB or unbound evidence.
DOC-GEN-S0-009 | Export writes secrets or unsafe configuration into generated files or manifests.
```

## S1 Defects

These should be repaired before expanding into a smart writing workbench.

```text
DOC-GEN-S1-001 | selected_kb_id/source_kb_ids are not explicit and persisted across manifest, history, export, artifact, and UI state.
DOC-GEN-S1-002 | Document generation source boundary is not OKF-aligned: source_trace/chunk/source_doc lineage is incomplete or falls back silently.
DOC-GEN-S1-003 | citations.json cannot reliably trace to source_trace_id, chunk_id, source_doc_id, source document, and KB id.
DOC-GEN-S1-004 | Generation types are mostly labels and do not produce type-specific outline/section/validation structure.
DOC-GEN-S1-005 | Template modes are mostly labels and do not materially affect body structure, required variables, or validation.
DOC-GEN-S1-006 | Custom template behavior is not validated for missing variables, deleted template entries, or restart recovery.
DOC-GEN-S1-007 | generation_manifest, outline, citations, validation report, document_history, export_manifest, Artifact Catalog, and Event Ledger can drift.
DOC-GEN-S1-008 | Multiple export formats do not share the same source body priority: edited_document -> reading_notes -> generated.md.
DOC-GEN-S1-009 | Structured exports do not include enough KB/document/source metadata for downstream audit.
DOC-GEN-S1-010 | Failure states are not explanatory enough for no KB, empty title, missing citation, missing template, repeated generation, and export failure.
```

## Not S0/S1 Yet

```text
full smart writing workbench
multi-Agent writing orchestration
complex template marketplace
advanced PPT layout engine
multi-KB automatic writing synthesis
night document maintenance
large DocumentGenerationService architecture extraction
```

These belong after S0/S1 stabilization and OKF source trace alignment are stable.

## Stabilization Requirements

Minimum product chain:

```text
select KB
-> name document
-> choose generation type/template/output format/source display
-> generate
-> view body and sources
-> edit
-> export
-> inspect history
-> delete test document/history
-> restart recovery
```

Minimum artifacts:

```text
doc/reading_notes.md or doc/generated.md
doc/edited_document.md when edited
doc/generation_manifest.json
doc/outline.json
doc/citations.json
doc/document_validation_report.json
document_history/*
export_manifest or generated_file_report
Artifact Catalog records
Event Ledger records
```

Binding and trace truth rules:

```text
selected_kb_id/source_kb_ids must be explicit.
citations must trace to source_trace_id/chunk/source_doc/source document when available.
Strict citation mode must not pass without usable source evidence.
Export manifests must name the exact source body used for export.
History deletion must not delete source KB or user documents.
```

## Source Resolver Priority

Future repairs should align generation source lookup to:

```text
selected knowledge_bases/<kb_id>/source_trace.jsonl
-> selected knowledge_bases/<kb_id>/chunks.jsonl and source_map.json
-> current kb/chunks.jsonl, cards.jsonl, qa_pairs.jsonl
-> query result
-> fallback with explicit warning
```

Fallback output must not claim strict citation coverage.

## Execution Order

```text
1. Audit generateMarkdown, _writeReadingNotes, _writeDocumentGenerationManifest, exportMarkdownDocument, exportDocumentFormat, history functions, and UI config flow.
2. Reproduce one S0/S1 defect at a time and record exact evidence.
3. Repair KB -> document -> edit -> export -> history -> delete -> restart first.
4. Add explicit selected_kb_id/source_kb_ids/source_doc_ids/source_trace_ids where missing.
5. Verify generation type and template mode produce real outline/body/validation differences or downgrade UI wording.
6. Repair manifest/history/export/artifact/event consistency.
7. Keep full smart writing features and broad service extraction out of S0/S1.
```

## Acceptance

White-box:

```text
selected_kb_id_explicit = true
generation_manifest_correct = true
outline_matches_generation_type = true
citations_trace_to_source = true
document_validation_report_correct = true
history_snapshot_correct = true
export_manifest_uses_exact_source_body = true
artifact_catalog_correct = true
event_ledger_correct = true
delete_restart_consistent = true
```

Black-box:

```text
kb_to_document_passed = true
document_view_passed = true
source_view_passed = true
edit_then_export_uses_edited_body = true
md_export_passed = true
local_format_export_passed = true
history_view_passed = true
delete_test_document_passed = true
restart_recovery_passed = true
unhappy_paths_explain_next_action = true
```

## Current Judgment

```text
Document generation has a KB-grounded pipeline foundation.
It is not a free-form chat writer and should not be rebuilt from scratch.
Current priority is S0/S1 stabilization of selected KB truth, OKF source trace, template/type effect, export/history/delete consistency, and restart recovery.
Do not expand into a full smart writing workbench until these defects are cleared.
```
