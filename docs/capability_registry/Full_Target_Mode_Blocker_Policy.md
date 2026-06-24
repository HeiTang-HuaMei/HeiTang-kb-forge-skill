# Full Target Mode Blocker Policy

Status: `full_target_mode_plan_generated_needs_execution`
Generated at: `2026-06-24T16:14:29.312025Z`

This policy governs autonomous execution after plan generation. Soft blockers trigger automatic diagnosis, repair, and retest. Hard blockers stop execution with a failure report, checkpoint, and resume prompt.

## Soft Blockers

- Core test failure
- UI binding failure
- Blackbox click/action failure
- State not refreshing
- Event Ledger evidence missing
- Artifact Lifecycle evidence missing
- source_trace missing
- validation_report missing
- export/open/delete failure
- Redis/vector/LLM temporary failure
- external source validation failure
- capability_chain_status.json status mismatch
- lint/analyze/unit test failure
- isolatable dirty-worktree pollution
- network timeout, DNS, proxy reset, or HTTP 429/502/503/504

Soft blocker handling:

1. Locate root cause automatically.
2. Apply the smallest aligned fix.
3. Retest automatically.
4. Repeat up to 3 repair rounds for implementation/test issues.
5. Retry temporary network/external-service failures up to 5 rounds.
6. Only after the limit is exhausted, write failure_report, checkpoint, and resume_prompt.

## Hard Blockers

- Risk of deleting real user data
- Need to expose or commit secrets, tokens, cookies, or authorization headers
- Need to add unapproved heavy dependencies
- Need to change packaging architecture
- Need to package Redis or vector DB service binaries into the EXE
- Need to implement prohibited local-model or GPU-video scope
- Need to break an already closed capability
- Need to alter the P0 -> P0 Release Gate -> P1 -> P1 Release Gate -> P2 -> P2 Release Gate chain
- Automatic repair exhausted after 3 rounds
- Network/external-service retry exhausted after 5 rounds

## Deletion Test Authorization

Autonomous blackbox tests may delete only objects created by the same test run and carrying a test marker:

- test_workspace
- test_document
- test_knowledge_base
- test_artifact
- test_skill
- test_assistant
- test_export_package

Forbidden deletion targets:

- real user data not created by the current test
- data without a test marker
- unrecoverable data
- credentials, configuration, or user environment files

## Checkpoint Requirements

When stopping after hard blocker or exhausted repair budget, write affected_capability_id, affected_phase, failed_acceptance_type, missing_evidence, recommended_fix, rollback_or_continue_advice, checkpoint, failure_report, and resume_prompt.

## Worktree Partition Rule

Isolated pre-target dirty files must remain excluded from commits and evidence until separately reviewed or intentionally absorbed by a future capability gate.
