# Industrial Knowledge Scope and Reliability Architecture

Status: read_only_design_gate_completed_needs_owner_review

This document records the read-only design mapping for industrial knowledge reliability. It does not implement Scope Resolver, Evidence Graph, rule inference, cross-KB reasoning, new model routing, A2A, or production release readiness.

## 1. Current Capabilities Observed

Evidence inspected from the current Windows EXE workspace and Flutter runtime:

- Knowledge base build creates `kb/manifest.json`, `knowledge_bases/kb_catalog.json`, `source_map.json`, `source_trace.json`, `index_metadata.json`, citation index paths, and source document records.
- Query validation creates `query/validation_report.json`, `citation_coverage_report.json`, `conflict_report.json`, `external_validation_boundary.json`, and writes `validate_knowledge_base` to Event Ledger.
- Agent manifests currently store `kb_ids`, `skill_ids`, `model_config_id`, `model_route_binding`, `knowledge_binding`, `skill_binding`, output format, role goal, and local-only capability boundaries.
- Assistant profile runtime supports `bound_knowledge_base_ids` and `bound_skill_ids` for created profiles.
- Artifact catalog stores `artifact_id`, `artifact_type`, `source_module`, `source_id`, `workspace_id`, `file_path`, status, and metadata.
- Event Ledger stores `event_id`, `event_type`, `module`, `action`, `target_id`, `target_name`, `workspace_id`, `status`, `artifact_path`, `error_message`, and metadata.
- Provider/runtime settings already distinguish local provider IDs, model gateway config, embedding/search/parser/OCR providers, exporter providers, network policy, Redis config, vector config, and masked secrets.
- Skill package artifacts already carry `source_kb_ids`, verification reports, operation history, and model route evidence.

## 2. Current Gaps

Current structures are not yet sufficient for industrial knowledge reliability:

- `knowledge_base_id` / `kb_ids` exist, but there is no unified `knowledge_scope` object spanning workspace, project, assistant, task, user, permission, version, time, domain, jurisdiction, and risk.
- Knowledge base records have `current_version`, but version semantics are incomplete: no canonical `knowledge_base_version_id`, effective date range, rule version, or answer reproducibility contract.
- Agent manifests do not yet reserve `primary_knowledge_base_id`, `allowed_reference_kb_ids`, `kb_scope_mode`, `answer_policy_id`, or `ai_profile_id`.
- Artifact records do not yet consistently store `assistant_id`, `task_id`, `primary_knowledge_base_id`, `used_knowledge_base_ids`, `knowledge_base_version_ids`, `source_document_ids`, `source_chunk_ids`, `answer_status`, `risk_level`, `reasoning_report_path`, or `validation_report_path`.
- Event records do not yet consistently store scope resolution, evidence status, answer status, risk level, created artifact IDs, reasoning reports, or blocked answer events.
- Validation reports cover citation and conflict at retrieval level, but do not yet model A0-A6 answer status, inference chains, exceptions, jurisdiction, high-risk human review, or permission boundaries.
- AI configuration is provider-centric. It lacks explicit `task_profile`, `kb_profile`, `risk_profile`, `answer_policy`, and `verifier_profile`.
- No current evidence proves prevention of cross-KB mixed answers under single-scope mode.
- No current evidence proves high-risk answer blocking beyond local-only external validation boundaries.

## 3. Industrial Scope Model

The minimum reliable unit is not a single KB ID. It is a Knowledge Scope:

```json
{
  "scope_id": "scope_xxx",
  "workspace_id": "workspace_xxx",
  "project_id": "project_xxx",
  "assistant_id": "assistant_xxx",
  "task_id": "task_xxx",
  "user_id": "user_xxx",
  "primary_knowledge_base_id": "kb_fire_safety",
  "used_knowledge_base_ids": ["kb_fire_safety"],
  "allowed_reference_kb_ids": [],
  "knowledge_base_version_ids": ["kb_fire_safety_v2026_06"],
  "document_ids": ["doc_xxx"],
  "chunk_ids": ["chunk_001", "chunk_002"],
  "permission_scope": "user_visible_only",
  "kb_scope_mode": "single",
  "time_scope": {
    "effective_at": "2026-06-24",
    "effective_from": "2026-01-01",
    "effective_to": null
  },
  "domain_scope": "regulation",
  "jurisdiction_scope": ["CN", "Zhejiang", "Hangzhou"],
  "risk_level": "high",
  "answer_policy_id": "policy_strict_evidence",
  "ai_profile_id": "ai_profile_regulation_strict"
}
```

The first implementation must reserve this shape in existing manifests and events, even before reasoning is implemented.

## 4. Evidence Graph Model

P1/P2 should move from flat chunks to a lightweight evidence graph:

Nodes:

- `document`
- `chunk`
- `entity`
- `concept`
- `claim`
- `rule`
- `condition`
- `exception`
- `artifact`
- `human_review_record`

Edges:

- `belongs_to`
- `defined_by`
- `prohibits`
- `allows`
- `requires`
- `except_when`
- `supported_by`
- `conflicts_with`
- `derived_from`
- `reviewed_by`

Minimum example:

```text
cinema --belongs_to--> crowded_place
crowded_place --prohibits--> open_flame
both edges --supported_by--> source_chunk_ids
answer artifact --derived_from--> rule + classification evidence
```

## 5. Rule, Exception, Conflict Model

Rules should be represented separately from raw chunks:

```json
{
  "rule_id": "rule_xxx",
  "knowledge_base_id": "kb_fire_safety",
  "knowledge_base_version_id": "kb_fire_safety_v2026_06",
  "rule_type": "prohibition",
  "subject": "人员密集场所",
  "action": "使用明火",
  "operator": "prohibits",
  "condition": "",
  "exception": "经审批的演出特效另行处理",
  "jurisdiction_scope": ["CN", "Zhejiang", "Hangzhou"],
  "time_scope": {
    "effective_from": "2026-01-01",
    "effective_to": null
  },
  "source_trace": {
    "document_id": "doc_xxx",
    "chunk_id": "chunk_001",
    "citation": "..."
  },
  "confidence": 0.82,
  "review_status": "needs_review"
}
```

Conflict and exception records must be first-class artifacts, not only text in an answer:

```json
{
  "conflict_id": "conflict_xxx",
  "subject": "电影院",
  "action": "使用明火",
  "conflict_type": "allow_vs_prohibit",
  "rule_ids": ["rule_a", "rule_c"],
  "source_chunk_ids": ["chunk_001", "chunk_009"],
  "answer_policy_effect": "block_direct_permission"
}
```

## 6. Answer Status Levels

All answers should eventually carry one of these statuses:

- `blocked_no_bound_kb`: no bound KB, user must select a KB.
- `blocked_missing_evidence`: scope exists but evidence is insufficient.
- `answered_direct_citation`: direct evidence answers the question.
- `answered_multi_evidence`: multiple evidence fragments are combined without rule transfer.
- `answered_with_inference`: classification plus rule transfer is used.
- `answered_with_risk_constraints`: answer includes exceptions, conflicts, approval, version, or jurisdiction constraints.
- `blocked_need_human_review`: high-risk or uncertain answer requires manual review.

These statuses should be reserved before full reasoning exists.

## 7. AI Config Governance Model

Provider settings are necessary but not sufficient. Industrial reliability needs task and risk-specific profiles:

```json
{
  "ai_profile_id": "ai_profile_regulation_strict",
  "task_profile": "rule_extraction",
  "kb_profile": "kb_fire_safety_high_risk",
  "risk_profile": "high",
  "model_role": "structured_extractor",
  "temperature_max": 0.2,
  "json_schema_required": true,
  "source_trace_required": true,
  "verifier_required": true,
  "must_cite": true,
  "allow_creative_completion": false,
  "block_on_missing_evidence": true,
  "human_review_for_execution_advice": true,
  "block_on_schema_error": true
}
```

P0 should reserve references to this model. P1 can implement basic routing. P2 can industrialize governance and cost/risk controls.

## 8. Event Ledger Additions

The Event Ledger schema should allow these event types without requiring all to fire in P0:

- `scope_resolved`
- `scope_resolution_failed`
- `knowledge_base_bound`
- `knowledge_base_unbound`
- `answer_scope_selected`
- `cross_kb_reference_requested`
- `cross_kb_reference_blocked`
- `cross_kb_reference_allowed`
- `evidence_retrieval_started`
- `evidence_retrieval_completed`
- `evidence_missing`
- `claim_extracted`
- `rule_extracted`
- `relation_extracted`
- `exception_detected`
- `conflict_detected`
- `inference_started`
- `inference_completed`
- `inference_blocked`
- `evidence_verified`
- `evidence_verification_failed`
- `answer_blocked_no_bound_kb`
- `answer_blocked_missing_evidence`
- `answer_blocked_conflict`
- `answer_blocked_need_human_review`
- `answer_generated_direct_citation`
- `answer_generated_multi_evidence`
- `answer_generated_with_inference`
- `answer_generated_with_risk_constraints`
- `reasoning_report_created`
- `validation_report_created`
- `reliability_score_updated`
- `human_review_requested`
- `human_review_completed`

Event metadata should reserve:

```json
{
  "workspace_id": "workspace_xxx",
  "project_id": "project_xxx",
  "assistant_id": "assistant_xxx",
  "task_id": "task_xxx",
  "user_id": "user_xxx",
  "primary_knowledge_base_id": "kb_fire_safety",
  "used_knowledge_base_ids": ["kb_fire_safety"],
  "knowledge_base_version_ids": ["kb_fire_safety_v2026_06"],
  "kb_scope_mode": "single",
  "permission_scope": "user_visible_only",
  "domain_scope": "regulation",
  "jurisdiction_scope": ["CN", "Zhejiang", "Hangzhou"],
  "time_scope": {"effective_at": "2026-06-24"},
  "answer_status": "answered_with_inference",
  "evidence_status": "sufficient",
  "risk_level": "high",
  "created_artifact_ids": ["artifact_xxx"]
}
```

## 9. Artifact Manifest Additions

Artifact records should reserve:

```json
{
  "artifact_id": "artifact_xxx",
  "artifact_type": "reasoning_report",
  "workspace_id": "workspace_xxx",
  "project_id": "project_xxx",
  "assistant_id": "assistant_xxx",
  "task_id": "task_xxx",
  "user_id": "user_xxx",
  "primary_knowledge_base_id": "kb_fire_safety",
  "used_knowledge_base_ids": ["kb_fire_safety"],
  "knowledge_base_version_ids": ["kb_fire_safety_v2026_06"],
  "source_document_ids": ["doc_xxx"],
  "source_chunk_ids": ["chunk_001", "chunk_002"],
  "answer_status": "answered_with_inference",
  "evidence_status": "sufficient",
  "risk_level": "high",
  "validation_report_path": "...",
  "reasoning_report_path": "...",
  "citation_report_path": "...",
  "conflict_report_path": "...",
  "exception_report_path": "...",
  "human_review_record_path": ""
}
```

Reserved artifact types:

- `agent_reply`
- `markdown_document`
- `docx_document`
- `pptx_presentation`
- `xlsx_table`
- `skill_package`
- `validation_report`
- `citation_report`
- `reasoning_report`
- `evidence_report`
- `conflict_report`
- `exception_report`
- `reliability_report`
- `human_review_record`
- `export_package`

## 10. P0 / P1 / P2 Route

P0 metadata reservation:

- Reserve scope fields on assistant profiles, generated agent manifests, KB catalog records, KB manifests, artifact catalog records, event metadata, validation reports, and AI config references.
- Add blackbox checks for: no-bound-KB blocking, artifact KB source metadata, event KB source metadata, restart persistence, and deleted artifact status consistency.
- Allowed statuses: `industrial_scope_metadata_reserved_needs_review`, `event_scope_reserved_needs_review`, `artifact_scope_reserved_needs_review`, `ai_config_governance_reserved_needs_review`, `semantic_reasoning_not_implemented`, `rule_engine_not_implemented`.

P1 basic reliability:

- `Scope Resolver Basic`
- `Evidence Graph Basic`
- `Rule Extraction Basic`
- `Classification Reasoning Basic`
- `Conflict and Exception Detection Basic`
- `Evidence Verifier Basic`
- `Answer Policy Basic`
- `AI Config Governance Basic`
- `reasoning_report` and `reliability_report` artifacts
- Event Ledger full chain for scope, retrieval, evidence, inference, verification, answer or block

P2 industrialization:

- Multi-KB governance with single/compare/primary-plus-reference modes
- Versioned knowledge governance
- Jurisdiction/domain/time scope
- Human review console
- Reliability scoring
- Cross-project, cross-customer, permission-isolated governance

## 11. Blackbox Test Matrix

1. Single-KB inference:
   Bound KB has "crowded places prohibit open flame" and "cinema belongs to crowded place"; answer should be "not allowed" with A+B+inference chain.

2. Missing evidence block:
   Bound KB is cinema operations only; fire-safety question must return `blocked_missing_evidence`.

3. Multi-KB no mixed answer:
   Bound KBs are fire safety and cinema operations, mode is `single`, primary is cinema operations; system must not silently use fire safety KB.

4. Multi-KB compare:
   Compare mode must report each KB separately and avoid merged conclusion.

5. Primary plus reference:
   Primary fire-safety KB plus performance-approval reference KB should say principle is prohibited, approval exception may exist, and no direct execution permission is given.

6. Conflict detection:
   Allow and prohibit rules for the same subject/action must produce conflict and block direct permission.

7. Exception detection:
   Approval exception must be surfaced; without approval materials, execution advice is blocked.

8. Version test:
   Old version allows, new version prohibits; current answer must use current effective version and state version.

9. Permission test:
   User without fire-safety KB permission must not use it.

10. High-risk human review:
   "Can we directly use open flame tomorrow?" must require human review or approval evidence.

## 12. Forbidden Early Claims

Do not write these statuses before their real Gate is implemented and blackbox-verified:

- `semantic_reasoning_passed`
- `rule_engine_passed`
- `cross_kb_reasoning_passed`
- `multi_kb_governance_passed`
- `production_ready`
- `release_ready`
- `industrial_acceptance_passed`

Current design conclusion:

```text
Current P0 must not only reserve knowledge_base_id.
It must reserve workspace / project / assistant / task / user / version / permission / domain / time / jurisdiction / risk / answer_policy / ai_profile scope metadata so later reliable knowledge reasoning does not require a broad data-model rewrite.
```
