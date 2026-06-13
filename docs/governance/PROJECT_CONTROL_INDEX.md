# Project Control Index

This index locks HeiTang KB Forge to the WorkSpace global rules and the project-local control files that must be read before business implementation.

## WorkSpace Rule Sources

| Rule source | Role |
| --- | --- |
| `D:\HeiTang-Codex-WorkSpace\AGENTS.md` | WorkSpace execution entry point and inherited agent rules |
| `D:\HeiTang-Codex-WorkSpace\00_全局控制台.md` | WorkSpace control console, boundaries, and global operating rules |
| `D:\HeiTang-Codex-WorkSpace\01_全局复利与踩坑日志.md` | Pitfall log, compound learning, prevention rules, and gate binding |
| `D:\HeiTang-Codex-WorkSpace\03_测试与发布总规则.md` | Fast/Medium/Full Gate, release, and command-output rules |
| `D:\HeiTang-Codex-WorkSpace\04_Codex任务模板.md` | Structured task-entry template |
| `D:\HeiTang-Codex-WorkSpace\09_项目记忆锁与执行规则.md` | Project Memory Lock, Pre-Run Checklist, and Goal Drift Control |
| `D:\HeiTang-Codex-WorkSpace\10_文档产物治理规则.md` | Document Output Governance, manifests, retention, and document merging |
| `D:\HeiTang-Codex-WorkSpace\11_Runtime缓存与依赖规则.md` | Dependency remediation and runtime cache policy |
| `D:\HeiTang-Codex-WorkSpace\12_Codex长任务恢复与子智能体规则.md` | Progress events, retry/recovery, sub-agent lifecycle, and archival rules |

## Project Rule Sources

| Project source | Role |
| --- | --- |
| `AGENTS.md` | Project entry point binding WorkSpace rules to this repo |
| `docs/governance/NON_FORGETTABLE_RULES.md` | Project-local non-forgettable rules |
| `docs/governance/GOAL_ACCEPTANCE_LEDGER.json` | Authoritative goal acceptance ledger |
| `docs/governance/GOAL_ACCEPTANCE_LEDGER.md` | Human-readable ledger mirror |
| `docs/governance/GOAL_DRIFT_CONTROL_POLICY.md` | Non-downgrade policy |
| `docs/governance/TARGET_MODE_ACCEPTANCE_PLAN.md` | Target-mode final acceptance plan and campaign order lock |
| `docs/governance/PLAN_SEQUENCE_LOCK.md` | Enforces that the 12-section plan decides execution order, not ledger remaining gaps |
| `docs/governance/CAMPAIGN_STAGE_GATE_POLICY.md` | Defines Entry, Acceptance, and Transition Gates for Campaigns 1-9 and Final Release |
| `docs/governance/PRE_CAMPAIGN_ACCEPTANCE_GATE.md` | Verifies Campaign 1/2 acceptance before Campaign 3 may open |
| `docs/governance/TARGET_ACCEPTANCE_MATRIX.md` | Maps each plan section to proved, partial, unfinished, blocked, and absorbed work |
| `docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md` | Locks the future External Source Memory & Verification supplement after Campaign 3 2.0 and before Campaign 4 |
| `docs/governance/PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md` | Locks the Pre-4.0 Workspace Partition and KB access-scope foundation gate after Supplement 3.0 acceptance and before Supplement 4.0 |
| `docs/governance/CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md` | Locks Knowledge-to-Skill-to-Agent Package & Product Handoff Contract as Campaign 3 Supplement 4.0, not Campaign 4 |
| `docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md` | Locks post-Supplement-4.0 Campaign 1-3 Stage Test, closure, Closure Pack, repository cleanup, push, tag, and CI gates before Campaign 4 |
| `docs/governance/REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md` | Registers the future public repository surface cleanup, rename compatibility, push safety, tag safety, and CI gate after Closure Pack generation and before Campaign 4 |
| `docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md` | Registers product output surface guard and future/reference external trend alignment without runtime integration |
| `docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md` | Registers future Campaign 4 through Campaign 9 replacement definitions without activating them |
| `docs/governance/CAMPAIGN_4_5_REPLACEMENT_PLAN.md` | Compatibility pointer to the v3.0 Campaign 4-9 replacement plan |
| `docs/governance/FULL_ACCESS_EXECUTION_POLICY.md` | Full Access Execution policy |
| `docs/governance/DEPENDENCY_REMEDIATION_POLICY.md` | Dependency remediation policy |
| `docs/governance/DOCUMENT_OUTPUT_GOVERNANCE_POLICY.md` | Project audit/report output governance |
| `docs/governance/SUB_AGENT_LIFECYCLE.md` | Project sub-agent lifecycle policy |
| `docs/governance/UI_STATUS_TRUTHFULNESS_POLICY.md` | UI status truthfulness policy |

## Pre-Run Checklist

Before continuing business implementation, confirm that the following were read in the current run:

1. WorkSpace `AGENTS.md`
2. Project `AGENTS.md`
3. `PROJECT_CONTROL_INDEX.md`
4. `GOAL_ACCEPTANCE_LEDGER.json`
5. `NON_FORGETTABLE_RULES.md`
6. `D:\HeiTang-Codex-WorkSpace\01_全局复利与踩坑日志.md`
7. `PLAN_SEQUENCE_LOCK.md`
8. `CAMPAIGN_STAGE_GATE_POLICY.md`
9. `PRE_CAMPAIGN_ACCEPTANCE_GATE.md`
10. `TARGET_ACCEPTANCE_MATRIX.md`
11. `CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md`
12. `CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md`
13. `PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md`
14. `CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md`
15. `REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md`
16. `PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md`
17. `CAMPAIGN_4_9_REPLACEMENT_PLAN.md`
18. `CAMPAIGN_4_5_REPLACEMENT_PLAN.md`

## Fast Gate Binding

Changes to these files must trigger the project governance Fast Gate:

- `AGENTS.md`
- `docs/governance/PROJECT_CONTROL_INDEX.md`
- `docs/governance/TARGET_MODE_ACCEPTANCE_PLAN.md`
- `docs/governance/PLAN_SEQUENCE_LOCK.md`
- `docs/governance/CAMPAIGN_STAGE_GATE_POLICY.md`
- `docs/governance/PRE_CAMPAIGN_ACCEPTANCE_GATE.md`
- `docs/governance/TARGET_ACCEPTANCE_MATRIX.md`
- `docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md`
- `docs/governance/PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md`
- `docs/governance/CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md`
- `docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md`
- `docs/governance/REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md`
- `docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md`
- `docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md`
- `docs/governance/CAMPAIGN_4_5_REPLACEMENT_PLAN.md`
- `docs/governance/NON_FORGETTABLE_RULES.md`
- `tests/test_project_control_index.py`
- `tests/test_plan_sequence_lock.py`
- `tests/test_campaign_stage_gate_policy.py`
- `tests/test_pre_campaign_acceptance_gate.py`
- `tests/test_campaign_1_2_3_integrated_closure_policy.py`
- `tests/test_repository_public_surface_cleanup_gate_plan.py`
- `tests/test_pre_4_0_workspace_partition_gate_plan.py`
- `tests/test_campaign_4_9_replacement_plan.py`
- `tests/test_campaign_4_5_replacement_plan.py`
- `tests/test_backend_remediation_acceptance.py`
- `tests/test_knowledge_supply_chain_acceptance.py`
- `tests/test_campaign_3_external_source_memory_plan.py`
- `tests/test_product_output_surface_external_trend_alignment.py`

Required focused commands:

```powershell
python -m pytest tests/test_project_control_index.py -q
python -m pytest tests/test_plan_sequence_lock.py -q
python -m pytest tests/test_test_governance_manifest.py -q
git diff --check
```

## Goal Boundary

Project Memory Lock alignment does not advance Skill generation, Agent binding, external evidence verification, UI workflow, or EXE packaging. It only makes those future tasks safer by preventing rule drift and context loss.
