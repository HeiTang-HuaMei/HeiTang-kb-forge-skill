# Skill Module S0/S1 Stabilization Registry

## Scope

```text
status = blocked_requires_s0_s1_stabilization
module = Skill
goal = stabilize existing Skill product chain before method-to-skill expansion
boundary = no Final Owner Review Gate, no package candidate build, no P2 reopen, no capability_chain_status.json change
```

Current Skill capability is not missing. The existing product chain covers:

```text
KB -> primary Skill
external Skill -> imported asset
external Skill + KB -> localized Skill
multiple Skills -> fused Skill
Skill set -> Agent binding manifest
Agent -> reads kb_ids / skill_ids for dialogue
```

Current gap:

```text
The implementation is a fixed artifact generation chain, not a dynamic method-to-skill factory.
KB -> multiple method candidates -> user select/merge/name -> multiple method Skills is not yet complete.
```

## S0 Defects

These are S0 only when confirmed by reproduction evidence.

```text
SKILL-S0-001 | KB to Skill generation fails for a valid current KB.
SKILL-S0-002 | Generated Skill is invisible, cannot be opened, or cannot be exported from UI/runtime state.
SKILL-S0-003 | Skill delete is unsafe: deleted Skill reappears after restart or deletes KB/user assets.
SKILL-S0-004 | Agent binding cannot read the selected Skill/kb ids after Skill generation.
SKILL-S0-005 | Agent dialogue uses the wrong Skill/KB and answers from unbound evidence.
SKILL-S0-006 | External Skill import bypasses validation or imports dangerous executable/system override content.
SKILL-S0-007 | Skill export leaks secrets or unsafe configuration.
```

## S1 Defects

These should be repaired before method-to-skill expansion.

```text
SKILL-S1-001 | Persisted source_kb_ids are hard-coded as K1/K2/K3 instead of resolved current kb_id values.
SKILL-S1-002 | Persisted skill_ids are hard-coded as S1/S2 instead of generated/imported/localized Skill ids.
SKILL-S1-003 | agent_binding_manifest does not reliably reflect actual Agent/Skill binding state.
SKILL-S1-004 | Skill manifests lack source_trace/source_kb_ids/source_doc_ids/source_chunk_ids/source_trace_ids.
SKILL-S1-005 | generated/imported/localized/fused Skill states are mixed in one manifest without clear generation_mode/source_mode.
SKILL-S1-006 | built-in helper Skills are not marked as built_in_template_skill and can be mistaken for KB-extracted methods.
SKILL-S1-007 | Skill export package lacks a stable manifest, validation_report, source_trace, or dependency summary.
SKILL-S1-008 | Agent used_skill_ids and citation_trace.skill_ids are not guaranteed to match actual bound Skill ids.
SKILL-S1-009 | Skill operation history, artifact lifecycle, delete record, and restart recovery evidence are incomplete.
SKILL-S1-010 | _writeAdditionalSkillPackages mixes primary generation, external import, localization, fusion, manifest, export, and binding writes.
```

## Not S0/S1 Yet

```text
method-to-skill automatic extraction
multi-book method clustering
large Skill marketplace
automatic Skill evolution
large service/repository architecture extraction
visual polish and advanced Skill recommendation UI
```

These belong after S0/S1 stabilization and OKF semantic chunks are stable.

## Stabilization Requirements

Minimum product chain:

```text
KB -> primary Skill -> view -> export -> bind Agent -> Agent dialogue uses Skill -> delete -> restart recovery
```

Minimum artifacts:

```text
skill_catalog.json
skill_manifest.json
source_trace.jsonl
validation_report.json
export_manifest.json
agent_binding_manifest.json
operation_history
event_ledger records
artifact_lifecycle records
```

Binding truth rules:

```text
Persisted bindings must use real kb_id and skill_id values.
K1/S1 style values may be display aliases or test aliases only.
Agent manifests, operation records, used_skill_ids, and citation_trace.skill_ids must agree.
```

Built-in helper Skills must be explicit:

```text
generation_mode = built_in_template
source_mode = template_plus_current_kb
is_method_extracted_from_kb = false
```

Future method candidates should use:

```text
generation_mode = kb_method_candidate
source_mode = from_okf_semantic_chunks
is_method_extracted_from_kb = true
```

## Execution Order

```text
1. Audit generateSkill, importExternalSkillPath, _writeAdditionalSkillPackages, agent_binding_manifest, agent_manifest.
2. Reproduce one S0/S1 defect at a time and record exact evidence.
3. Repair KB -> primary Skill -> export -> bind Agent -> dialogue -> delete -> restart first.
4. Replace persisted K1/K2/K3 and S1/S2 hard-coding with resolved real ids.
5. Add/repair skill_catalog.json and source_trace.jsonl.
6. Mark built-in helper Skills as templates, not KB-extracted methods.
7. Add minimal skill_candidates.jsonl structure only after the existing chain is stable.
8. Defer broad service/repository extraction until S0/S1 is clear.
```

## Acceptance

White-box:

```text
skill_catalog_correct = true
skill_manifest_correct = true
source_trace_correct = true
export_manifest_correct = true
agent_binding_manifest_correct = true
agent_manifest_reads_real_ids = true
used_skill_ids_and_citation_trace_match_binding = true
```

Black-box:

```text
kb_to_primary_skill_passed = true
skill_view_passed = true
skill_export_passed = true
skill_agent_binding_passed = true
agent_dialogue_uses_correct_skill_passed = true
skill_delete_passed = true
restart_recovery_passed = true
```

## Current Judgment

```text
Skill product chain exists.
Method-to-skill is not complete.
Current priority is S0/S1 stabilization of binding, source trace, manifest, catalog, export/delete/restart, and external Skill safety.
Do not expand into a full Skill factory until these defects are cleared.
```
