# Pre-Campaign Acceptance Gate

This gate is the required stop point before Section 5 / Campaign 3 can become active. It verifies the previous campaigns against their acceptance matrices instead of trusting checklist marks or `remaining_gap` ordering.

## Scope

Current review target:

- Campaign 1: Document Backend / OCR / Document Understanding backend strengthening.
- Campaign 2: Batch Import -> Document Preflight -> Document Understanding -> KB -> Package -> Search -> Report Export.

Explicitly not advanced in this gate:

- LLM Wiki v2, WeKnora, AnySearchSkill, n8n, MMSkills, or any other Section 5 project.
- External Skill learning.
- Agent or multi-agent business implementation.
- Full UI workflow completion.
- Configuration completion.
- EXE packaging.
- Push, tag, or release.

## Required Evidence

Campaign 1 evidence:

- `artifacts/audits/backend_remediation_acceptance_review/backend_remediation_acceptance_matrix.json`
- `artifacts/audits/backend_remediation_acceptance_review/backend_remediation_acceptance_matrix.md`
- `artifacts/audits/backend_remediation_acceptance_review/run_summary.md`

Campaign 2 evidence:

- `artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.json`
- `artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.md`
- `artifacts/audits/knowledge_supply_chain_acceptance_review/run_summary.md`

## Gate Rules

1. Campaign 1 must be `accepted` before Campaign 3 can become active.
2. Campaign 2 must be `accepted` before Campaign 3 can become active.
3. Campaign 3 is allowed next only when both previous reviews are accepted.
4. Campaign 3 is not automatically active merely because it is allowed next.
5. `GOAL_ACCEPTANCE_LEDGER.json` records status only and does not decide order.
6. `PLAN_SEQUENCE_LOCK.md` decides the plan sequence.
7. `TARGET_ACCEPTANCE_MATRIX.md` decides acceptance conditions.
8. `structured_skipped` cannot satisfy backend acceptance by itself.
9. `dependency_missing` cannot satisfy `real_integration`.
10. `report_export` cannot replace Campaign 2 acceptance.
11. This pre-campaign gate opens only Campaign 3; it does not weaken Campaign 4-9 gates.
12. Later campaigns still require their own Entry Gate, Acceptance Gate, and Transition Gate in `CAMPAIGN_STAGE_GATE_POLICY.md`.
13. Campaign 3 per-project integration decisions cannot substitute for Campaign 4 UI workflow acceptance.
14. Focused tests and Fast Gate remain development evidence only and cannot substitute Campaign 8 Full Testing / Full Review.

## Current Verdict

- Campaign 1 Acceptance Verdict: `accepted`
- Campaign 2 Acceptance Verdict: `accepted`
- Campaign 3 allowed next: `yes`
- Campaign 3 active now: `yes`
- Campaign 3 accepted now: `no_until_final_consistency_gate`

Campaign 3 was allowed as the next plan campaign only after this gate. Later governed Section 5 runs completed Campaign 3 Supplement 3.0, its dedicated Acceptance Gate, the Pre-4.0 Workspace Partition Foundation Gate, Campaign 3 Supplement 4.0 Entry Reconciliation Gate, Campaign 3 Supplement 4.0B Verified Knowledge-to-Skill Template, Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer, Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle, and the Campaign 3 Supplement 4.0 Acceptance Gate. Pre-4.0 accepts only workspace partition and KB access-scope foundation contracts, 4.0A accepts only a bounded industrial-grade entry gate, 4.0B accepts only a source-traced draft Skill Template plus validator/testcase evidence, 4.0C accepts only a source-bound Dedicated Skill draft package plus source binding/conflict/document-boundary evidence, and 4.0D-I accepts only product handoff contracts. Supplement 4.0 Acceptance accepted Supplement 4.0 only. PLAN_SEQUENCE_LOCK now permits only Campaign 3 Final Consistency Gate only.

## Transition Decision

`next_allowed_campaign = Section 5 / Campaign 3`

Blocked campaigns:

- Campaign 4 remains blocked until Campaign 3 is accepted.
- Campaign 5 remains blocked until Campaign 4 is accepted.
- Campaign 6 remains blocked until Campaign 5 is accepted.
- Campaign 7 remains blocked until Campaign 6 is accepted.
- Campaign 8 remains blocked until Campaign 7 is accepted.
- Campaign 9 remains blocked until Campaign 8 is accepted.
- Final Release remains blocked until Campaign 9 is accepted and all prior campaigns remain accepted.

## Goal Drift Review

- `final_target_not_downgraded = true`
- `not_goal_complete = true`
- Goal downgrade detected: `false`
- Remaining gap: Closure Pack, Repository Cleanup, push, tag, CI, Closure Checklist, Campaign 1-3 review handoff, full desktop UI, Core Bridge execution acceptance, Agent Runtime & Memory, configuration checks, Full Testing / Full Review, EXE install/run smoke, and Final Release are still blocked by sequence.
- Product output guard: Final Consistency must preserve `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package`; Document Outputs include Markdown, DOCX / Word, PDF, and PPTX / PowerPoint through existing `generate-documents`.
- Next required E2E step: Campaign 3 Final Consistency Gate only. Stage Test, Integrated Closure, Closure Pack, Repository Cleanup, push, tag, CI, Campaigns 4-9, Full Testing / Full Review, EXE, and release must not start early.
