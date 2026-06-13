# Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate Plan

This plan records the foundation gate inserted after Campaign 3 Supplement 3.0 acceptance and before Campaign 3 Supplement 4.0 implementation. It does not change the user-approved 12-section total plan.

## Current State

- Plan state: `passed_foundation_contract`
- Current active phase: `Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate`
- Current business item: `STOP before Campaign 3 Supplement 4.0 Entry Reconciliation Gate`
- Activation order: Campaign 3 Supplement 3.0 Acceptance Gate passed before this gate started
- Transition target after this gate passes: `Campaign 3 Supplement 4.0 Entry Reconciliation Gate`
- Campaign 4 active: `false`
- Campaign 5 active: `false`
- Supplement 4.0 active: `false`
- Final goal complete: `false`

This gate has generated foundation contracts and audit evidence. It does not create workspace runtime isolation, implement Campaign 4 UI, implement Campaign 5 Bridge execution, add future Bridge actions to the current allowlist, move legacy artifacts, or start Supplement 4.0.

## Locked Local Sequence

```text
Campaign 3 Supplement 3.0 External Source Memory & Verification
-> Campaign 3 Supplement 3.0 Acceptance Gate
-> Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate
-> Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract
-> Campaign 3 Final Consistency Gate
-> Campaign 1-3 Stage Test Gate
-> Campaign 1-3 Integrated Closure
-> Closure Pack
-> Upload
-> Tag
-> CI Green
-> Closure Checklist Green
-> Campaign 4 Goal-Oriented Product UI Workbench
-> Campaign 5 Chain-Level Local Core Bridge
-> Campaign 6 Agent Runtime & Memory Platform
-> Campaign 7 Configuration System
-> Campaign 8 Full Testing / Full Review
-> Campaign 9 EXE Packaging
```

Supplement 3.0 is accepted and the Pre-4.0 gate has passed as a foundation contract. Supplement 4.0 business implementation must not start until its Entry Reconciliation Gate runs.

## Gate Goal

Before Skill or Agent generation, define the workspace partition, knowledge-base access scope, asset ownership, path boundary, and cross-workspace access rules needed by later Skill, Agent Package, Agent Workspace Binding, Agent Memory Isolation, and Multi-Agent Workflow specs.

This gate is a foundation contract. It is not UI, Agent runtime, Campaign 5 Bridge, or a multi-tenant permission runtime.

## Required Scope

- Workspace defaults to strong isolation across sources, knowledge bases, skills, agents, workflows, runs, reports, audits, exports, memory, and settings.
- Knowledge bases belong to one workspace by default, but can be explicitly referenced, cloned, imported, or shared according to `kb_type` and `access_scope`.
- Agent packages later generated in Supplement 4.0 must bind explicit `bound_knowledge_base_ids`, `allowed_kb_scopes`, `denied_kb_ids`, `retrieval_policy`, and `audit_scope`.
- Legacy artifacts must be registered through `legacy_default_workspace` compatibility without moving, deleting, or renaming historical files.
- Workspace path boundaries must reject `../` escape, absolute-path escape, open-any-path behavior, repo-root/system/home outputs, and implicit cross-workspace reads.

## Required Outputs

This gate generated the product and bridge contracts listed by the user request, including:

- `docs/product/WORKSPACE_PARTITION_AND_ASSET_ISOLATION_PLAN.md`
- `docs/product/WORKSPACE_PARTITION_AND_ASSET_ISOLATION_PLAN.json`
- `docs/product/WORKSPACE_MANIFEST_SCHEMA.json`
- `docs/product/WORKSPACE_REGISTRY_SCHEMA.json`
- `docs/product/KNOWLEDGE_BASE_PARTITION_SCHEMA.json`
- `docs/product/KNOWLEDGE_BASE_ACCESS_SCOPE_MATRIX.json`
- `docs/product/WORKSPACE_ASSET_ISOLATION_MATRIX.json`
- `docs/product/CROSS_WORKSPACE_REFERENCE_POLICY.md`
- `docs/product/WORKSPACE_PATH_BOUNDARY_POLICY.md`
- `docs/product/WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.md`
- `docs/product/WORKSPACE_PARTITION_UI_HANDOFF_CONTRACT.json`
- `docs/bridge/WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.md`
- `docs/bridge/WORKSPACE_BOUNDARY_BRIDGE_HANDOFF_CONTRACT.json`
- `artifacts/audits/pre_4_0_workspace_partition/run_manifest.json`
- `artifacts/audits/pre_4_0_workspace_partition/validation_report.json`
- `artifacts/audits/pre_4_0_workspace_partition/checkpoint.json`

These outputs are foundation-contract deliverables. They are not Campaign 4 UI, Campaign 5 Bridge execution, Agent runtime, or runtime permission enforcement.

## Required Tests

The active gate added workspace manifest, registry, path boundary, asset scope, KB partition/access, legacy default workspace, UI handoff, Bridge handoff, and Pre-4.0 focused tests named in the user request.

Focused evidence: `tests/test_pre_4_0_workspace_partition_foundation_gate.py`.

## Non-Completion Guard

- `pre_4_0_workspace_partition_complete = true`
- `workspace_manifest_ready = true`
- `workspace_registry_ready = true`
- `workspace_path_boundary_ready = true`
- `kb_partition_ready = true`
- `kb_access_scope_ready = true`
- `legacy_default_workspace_ready = true`
- `workspace_partition_runtime_enforcement_ready = false`
- `kb_access_scope_runtime_enforcement_ready = false`
- `agent_runtime_ready = false`
- `multi_agent_runtime_ready = false`
- `agent_memory_runtime_ready = false`
- `campaign_4_ui_complete = false`
- `campaign_5_bridge_complete = false`
- `future_bridge_action_added_to_current_allowlist = false`
- `not_goal_complete = true`
