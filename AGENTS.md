# HeiTang KB Forge Project Rules

This project inherits the WorkSpace global rules. Treat those files as active execution rules, not reference material.

## Required WorkSpace Rule Sources

Before business implementation, read and follow:

- `D:\HeiTang-Codex-WorkSpace\AGENTS.md`
- `D:\HeiTang-Codex-WorkSpace\00_全局控制台.md`
- `D:\HeiTang-Codex-WorkSpace\01_全局复利与踩坑日志.md`
- `D:\HeiTang-Codex-WorkSpace\03_测试与发布总规则.md`
- `D:\HeiTang-Codex-WorkSpace\09_项目记忆锁与执行规则.md`
- `D:\HeiTang-Codex-WorkSpace\10_文档产物治理规则.md`
- `D:\HeiTang-Codex-WorkSpace\11_Runtime缓存与依赖规则.md`
- `D:\HeiTang-Codex-WorkSpace\12_Codex长任务恢复与子智能体规则.md`

`D:\HeiTang-Codex-WorkSpace\04_Codex任务模板.md` is also part of the WorkSpace task-entry template set and should be used when a task needs a structured checklist.

## Project Control Files

Also read these project-local files before continuing implementation:

- `docs/governance/PROJECT_CONTROL_INDEX.md`
- `docs/governance/NON_FORGETTABLE_RULES.md`
- `docs/governance/GOAL_ACCEPTANCE_LEDGER.json`
- `docs/governance/GOAL_DRIFT_CONTROL_POLICY.md`
- `docs/governance/TARGET_MODE_ACCEPTANCE_PLAN.md`
- `docs/governance/PLAN_SEQUENCE_LOCK.md`
- `docs/governance/CAMPAIGN_STAGE_GATE_POLICY.md`
- `docs/governance/PRE_CAMPAIGN_ACCEPTANCE_GATE.md`
- `docs/governance/TARGET_ACCEPTANCE_MATRIX.md`
- `docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md`
- `docs/governance/CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md`
- `docs/governance/PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md`
- `docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md`
- `docs/governance/REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md`
- `docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md`
- `docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md`
- `docs/governance/CAMPAIGN_4_5_REPLACEMENT_PLAN.md`
- `docs/governance/DOCUMENT_OUTPUT_GOVERNANCE_POLICY.md`

## Current Project Goal

HeiTang KB Forge is a local executable Agent knowledge supply-chain workbench:

1. Turn local materials into verifiable multi-knowledge-bases.
2. Condense knowledge bases into Skills.
3. Import, decompose, learn from, and regenerate owned Skills from external Skills.
4. Bind knowledge bases and Skills to created and orchestrated Agents.
5. Coordinate multiple Agents in a workspace.
6. Verify knowledge and Agent outputs through OpenCLI or approved external evidence sources.
7. Deliver an installable, runnable, diagnosable Windows EXE.

Older MVP-only constraints are obsolete for target-mode work. Do not reduce the goal back to Markdown/TXT parsing, local fixtures, contract-only checks, UI status-only work, or Fast Gate-only acceptance.

## Non-Forgettable Execution Rules

- Full Access Execution is authorized inside this project scope. Do not repeatedly ask whether allowed actions may proceed.
- Dependency remediation is allowed. Missing dependency evidence is not enough to declare a final blocker before remediation attempts.
- Retry and recovery require checkpoints, bounded retries, and action reports.
- Sub-agents must be registered, rate-limited, consolidated, closed, and archived.
- Goal Drift Control is mandatory. Never present local slices, Fast Gate, UI actions, contract-only work, or a single green command as final completion.
- Plan Sequence Lock is mandatory. The user-uploaded 12-section plan decides execution order; `GOAL_ACCEPTANCE_LEDGER.json` records status but does not choose the next task.
- Campaign Stage Gate is mandatory. Every campaign must pass Entry Gate, Acceptance Gate, and Transition Gate before a later campaign can become active.
- Campaign 3 Supplement 3.0 is locked after all Supplement 2.0 remaining work. Do not start External Source Memory & Verification early or use it to skip 5.11-5.14 or 5.S1-5.S3.
- Campaign 3 Supplement 4.0 is Knowledge-to-Skill Template Generator inside Campaign 3. Do not delete it, skip it, or rename it as Campaign 4.
- Campaigns 4-9 are governed by `CAMPAIGN_4_9_REPLACEMENT_PLAN.md`: Campaign 4 Goal-Oriented Product UI Workbench, Campaign 5 Chain-Level Local Core Bridge, Campaign 6 Agent Runtime & Memory Platform, Campaign 7 Configuration System, Campaign 8 Full Testing / Full Review, and Campaign 9 EXE Packaging. Do not enter any of them before Supplement 4.0, Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, baseline tag, CI/CL green, and Closure Checklist green all pass.
- Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate is a future gate only until its ordered prerequisites pass. It must inventory before cleanup, keep `_local_dependency_remediation`, `.heitang_cache`, `repo_surface_audit_pack`, `current_run`, `latest`, `tmp`, `build`, `dist`, `.venv`, and `node_modules` out of commits, preserve `heitang_kb_forge` import compatibility, block forbidden tracked files/secrets/large runtime binaries before push, and require push success before tag.
- Product Output Surface and External Trend Alignment is a governance guard only. `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package` are distinct product surfaces; Document Outputs include Markdown, DOCX / Word, PDF, and PPTX / PowerPoint through existing `generate-documents`. External trend projects remain future/reference and not integrated.
- Before CI/CL green, do not add TasteSkill or Product Design Plugin as active items, do not redesign UI, and do not change future Campaign Bridge allowlists.
- Document Output Governance is mandatory. Runtime evidence belongs under governed artifacts and manifests, not unlimited flat `docs/audits` sprawl.
- Runtime cache is project/workspace-local by default. Model, parser, OCR, adapter, embedding, and index caches must not silently fall back to C drive system locations.
- Tasks longer than 3 seconds need visible status; tasks longer than 30 seconds need progress, logs, and recovery strategy.
- Pitfalls must become rules, tests, or gates. A pitfall log without prevention does not count as resolved.

## Validation Discipline

Use the smallest relevant validation for the change. Project control and governance changes must include:

```powershell
python -m pytest tests/test_project_control_index.py -q
python -m pytest tests/test_plan_sequence_lock.py -q
python -m pytest tests/test_test_governance_manifest.py -q
git diff --check
```

Full Gate is not implied by Fast Gate. Push, tag, release, and EXE completion remain forbidden to claim until the full target evidence exists.
