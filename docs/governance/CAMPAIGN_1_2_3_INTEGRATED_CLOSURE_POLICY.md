# Campaign 1-3 Integrated Closure Policy

This policy locks the transition after Campaign 3 Supplement 3.0. It does not remove, skip, or rename Campaign 3 Supplement 4.0.

## Concept Boundary

Two similarly named items must stay separate:

| Item | Meaning | Scope |
| --- | --- | --- |
| `Campaign 3 Supplement 4.0` | Knowledge-to-Skill-to-Agent Package & Product Handoff Contract | Internal Section 5 / Campaign 3 supplement |
| `Campaign 4` | Goal-Oriented Product UI Workbench | Future product UI workbench campaign |
| `Campaign 5` | Chain-Level Local Core Bridge | Future local Core Bridge campaign |
| `Campaign 6` | Agent Runtime & Memory Platform | Future Agent runtime and memory campaign |
| `Campaign 7` | Configuration System | Future configuration campaign |
| `Campaign 8` | Full Testing / Full Review | Future full validation campaign |
| `Campaign 9` | EXE Packaging | Future Windows packaging campaign |

`Campaign 3 Supplement 4.0` is not `Campaign 4`. `Campaign 4` is not `4.0`.

The old Campaign 4/5-only definitions are superseded by `CAMPAIGN_4_9_REPLACEMENT_PLAN.md`. This closure policy does not enter Campaigns 4-9 or Final Release; it only defines the gate chain that must pass before Campaign 4 can open.

## Locked Sequence

The locked order after Campaign 3 Supplement 3.0 is:

```text
Campaign 3 Supplement 3.0 completed
-> STOP
-> Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate
-> STOP
-> Campaign 3 Supplement 4.0 Entry Gate
-> Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract
-> Campaign 3 Final Consistency Gate
-> STOP
-> Campaign 1-3 Stage Test Gate
-> tests green
-> Campaign 1-3 Integrated Closure Gate
-> Closure Pack generated
-> Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate
-> repository push succeeded
-> campaign baseline RC tag created
-> CI/CL green
-> Closure Checklist green
-> Campaign 1-3 Integrated Review and New Conversation Handoff Gate
-> Campaign 4 Goal-Oriented Product UI Workbench Entry Gate allowed
```

Campaign 1-3 Stage Test Gate must not run immediately after Campaign 3 Supplement 3.0 if Campaign 3 Supplement 4.0 has not completed.

## Stop Points

After Campaign 3 Supplement 3.0 acceptance, business implementation must stop. The only allowed next action is:

```text
Run Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate only.
```

After the Pre-4.0 Workspace Partition Foundation Gate passes, business implementation must stop. The only allowed next action is:

```text
Run Campaign 3 Supplement 4.0 Entry Gate only.
```

After Campaign 3 Final Consistency Gate passes, business implementation must stop again. The only allowed next action is:

```text
Run Campaign 1-3 Stage Test Gate only.
```

## Campaign 1-3 Stage Test Gate

This is a stage test for Campaigns 1 through 3. It is not the final Full Gate.

The stage test must cover:

- Campaign 1 accepted backend strengthening evidence
- Campaign 2 accepted batch import and knowledge supply-chain evidence
- Campaign 3 mainline items 5.1 through 5.14
- Campaign 3 strengthening items 5.S1 through 5.S3
- Campaign 3 Supplement 2.0 closure gate
- Campaign 3 Supplement 3.0 External Source Memory & Verification
- Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract
- Product Output Surface guard: `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package`
- governance sequence, goal drift guard, registry consistency, audit manifest consistency, validation gate manifest, UI asset boundary, JSON parse, and `git diff --check`

If any test fails:

```text
do not run Campaign 1-3 Integrated Closure Gate
do not generate Closure Pack
do not run Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate
do not push
do not tag
do not verify CI/CL as green
do not enter Campaign 4
```

Failure evidence must write:

- `failed_step`
- `failed_test`
- `error_type`
- `last_success_checkpoint`
- `resume_command`
- `next_safe_action`

## Integrated Closure Gate

Campaign 1-3 Integrated Closure Gate may run only after the Stage Test Gate is green.

It must classify all Campaign 1-3 evidence into:

- `real_integration_matrix.json`
- `framework_only_matrix.json`
- `preflight_only_matrix.json`
- `metadata_only_matrix.json`
- `reference_only_matrix.json`
- `planned_not_active_matrix.json`
- `unfinished_items.json`
- `forbidden_misinterpretations.json`

It must state that:

- framework-only is not business completion
- preflight-only is not full read or capture completion
- metadata-only is not runtime
- reference-only is not provider-ready
- planned-not-active is not started
- closure gate is not final product acceptance
- stage test is not final Full Gate

## Closure Pack

After Stage Test Gate and Integrated Closure Gate pass, generate:

```text
dist/HeiTang-Campaign-1-2-3-Integrated-Closure-Pack.zip
```

The pack must include:

- `docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_REPORT.md`
- `docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_REPORT.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/run_manifest.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/run_summary.md`
- `artifacts/audits/campaign_1_2_3_integrated_closure/campaign_status_matrix.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/real_integration_matrix.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/non_runtime_boundary_matrix.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/planned_not_active_matrix.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/unfinished_items.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/forbidden_misinterpretations.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/changed_files_manifest.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/artifact_manifest.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/test_result_manifest.json`
- `artifacts/audits/campaign_1_2_3_integrated_closure/handoff.md`
- `artifacts/audits/current_run/checkpoint.json`
- `docs/governance/RUN_STATE.md`
- `docs/governance/GOAL_ACCEPTANCE_LEDGER.json`
- `docs/governance/PLAN_SEQUENCE_LOCK.md`
- `docs/governance/TARGET_ACCEPTANCE_MATRIX.md`
- `docs/audits/AUDIT_MANIFEST.json`
- `docs/testing/VALIDATION_GATE_MANIFEST.json`

The pack must not include virtual environments, `node_modules`, Flutter build output, caches, downloaded temporary files, keys, tokens, cookies, account credentials, or unrelated large artifacts.

## Repository Cleanup, Push, Tag, And CI Gate

Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate may run only after:

- Closure Pack exists
- closure reports exist
- `test_result_manifest.json` exists
- checkpoint and `RUN_STATE.md` are current
- secret scan boundaries are clean
- JSON parse passed
- `git diff --check` passed

The gate must first run read-only inventory. It must classify `active_docs`, `milestone_evidence`, `legacy_root_reports`, `temporary_current_run`, and `obsolete_duplicate_docs`; it must not directly delete, move, or rename files before manifests exist.

The gate must keep `_local_dependency_remediation`, `.heitang_cache`, `repo_surface_audit_pack`, `artifacts/audits/current_run`, `artifacts/audits/latest`, `tmp`, `build`, `dist`, `.venv`, and `node_modules` out of commits. It must migrate the public name toward `HeiTang Knowledge Workbench` while preserving the Python import namespace `heitang_kb_forge`.

Push may run only after the Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passes and the push safety report confirms no forbidden tracked files, secrets, cookies, tokens, credentials, or large runtime binaries. If no push target or credentials are configured, stop and write:

```json
{
  "push_required": true,
  "push_blocked_reason": "missing_push_target_or_credentials",
  "next_safe_action": "wait_for_push_configuration"
}
```

Campaign baseline CI validation tag creation may run only after repository push succeeds. The validation tag series is:

```text
campaign-1-3-baseline-rc.1
campaign-1-3-baseline-rc.2
```

Do not create any new `v3.0.x-integrated-closure` tag for Campaign 1-3 baseline validation. Historical `v3.0.x-integrated-closure` tags are superseded CI validation tags only; they are not formal release tags, baseline tags, product version tags, EXE delivery, or Campaign 4 completion. Product version tags remain reserved for real product releases such as `v4.2.x` or `v4.3.x`.

After the CI / Release Check chain is green for an RC tag and the ordered closure checklist passes, the final stable campaign baseline tag may be:

```text
campaign-1-3-baseline
```

The campaign baseline tags are not final releases, not commercial stable releases, not product version releases, not EXE delivery, and not Campaign 4 completion.

CI/CL verification may run only after a campaign baseline RC tag is created. Campaign 4 Goal-Oriented Product UI Workbench Entry Gate may open only when the latest campaign baseline tag-related required CI/CL workflows complete with `conclusion = success`.

Campaign 4 may open only after Supplement 4.0 acceptance, Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, campaign baseline RC tag creation, CI/CL green verification, Closure Checklist green verification, and the Campaign 1-3 Integrated Review and New Conversation Handoff Gate all pass.

Before CI/CL green and Closure Checklist green, do not enter Campaigns 4-9 or Final Release, do not add TasteSkill or Product Design Plugin as active scope, do not perform UI redesign, and do not change future Campaign Bridge allowlists.

## Campaign 1-3 Integrated Review and New Conversation Handoff Gate

This gate may run only after all of the following are true:

1. Campaign 1-3 Stage / Functional Test Gate passed.
2. Campaign 1-3 Integrated Closure Gate passed.
3. Closure Pack generated.
4. Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed.
5. Repository push succeeded.
6. Baseline tag was created.
7. Tag-related CI/CL is green.
8. Closure Checklist is green.

Required outputs:

```text
docs/governance/CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md
docs/governance/CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md
docs/governance/CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md
artifacts/audits/current_run/new_conversation_handoff_prompt.md
artifacts/audits/current_run/campaign_1_2_3_handoff_manifest.json
```

These outputs must not be generated before real final commit, push, tag, and CI evidence exists. They are review and handoff artifacts only. They are not a commercial release, not EXE packaging, not Campaign 4 implementation, and not proof that Campaign 4 is complete.

The integrated review report must answer what Campaigns 1, 2, and 3 completed, including Supplement 2.0, Supplement 3.0, Pre-4.0, Supplement 4.0, and Repository cleanup / rename / push-tag safety completion. It must also record final commit hash, tag name, push status, CI status, Stage / Functional Test result, Integrated Closure result, Repository Cleanup / Rename / Push-Tag Safety result, `git diff --check` result, JSON parse result, forbidden tracked files check result, and secret check result.

The external project integration review must list every external project with these fields:

```text
project_name
source_url_or_registry_id
campaign_section
capability_domain
integration_status
implementation_mode
runtime_dependency_added
tests_added
evidence_path
current_boundary
future_target
```

`integration_status` may only be one of:

```text
real_integration
reference_only
planned_not_active
needs_verification
stopped_or_rejected
```

Required external-project boundary statements:

- LLM Wiki v2 belongs to Campaign 3 Section 5.1; Memory Separation / Knowledge Lifecycle has been integrated as a local capability.
- Redis / Vector DB / external database-backed Memory Store Connector belongs to Campaign 8 future target and must not be written as completed in Campaigns 1-3.
- andrej-karpathy-skills is a Knowledge-to-Skill methodology reference strongly related to 4.0B; it is not external runtime integration.
- Presenton is a Document/PPT workflow reference; it is not integrated PPT runtime.
- CodeGraph and Understand Anything are future codebase graph / knowledge graph / Workbench UI references; they are not integrated knowledge graph runtime.
- LongLive is not in the current product route; this product does not add GPU video generation.
- pi-mono is future Agent Runtime architecture reference; it is not current Agent runtime integration.
- claude-plugins-official is future plugin ecosystem reference; it is not current plugin runtime integration.

The capability review matrix must list these four product output surfaces:

1. Knowledge Package.
2. Document Outputs: Markdown / DOCX / PDF / PPTX.
3. Skill Outputs: Skill Template / Skill Suite.
4. Agent Creation Package.

It must also list the lower-level capability surfaces:

- Memory Separation / Knowledge Lifecycle.
- Evidence Map / Source Trace.
- Retrieval / Verification.
- Workspace Partition / KB Access Scope.
- External Source Memory & Verification.
- Document generation.
- Skill generation.
- Agent package generation.

The boundary section must explicitly state:

- Campaign 4 has not started unless CI Green and the existing Closure Checklist Green gate allow the next safe action.
- Campaign 8 Redis / Vector DB has not started.
- EXE packaging has not started.
- Local large model support is not planned.
- GPU video generation is not planned.
- Optional OCR and advanced parser providers are dependency-gated and not default bundled.
- `_local_dependency_remediation/` is not a release artifact and must not be packaged into the main EXE.

The new-conversation handoff prompt must include current project positioning, completed state, integrated capabilities, external-project integration degree, forbidden misinterpretations, current tag / commit / CI Green result, next safe action, Campaign 4 Entry Gate initial target, long-task strategy, and 429 / timeout / retry / checkpoint strategy.

When this future gate passes, the next safe action must be exactly:

```text
Open a new conversation and start Campaign 4 Entry Gate only.
```

Forbidden for this gate:

1. Do not write `reference_only` as `real_integration`.
2. Do not write `planned_not_active` as completed.
3. Do not write Redis / Vector DB as completed in Campaign 3.
4. Do not write LongLive / GPU video into the current product route.
5. Do not write local large model support into the EXE packaging target.
6. Do not write push/tag/CI Green as commercial release completion.
7. Do not start Campaign 4 business implementation inside the report.
8. Do not delete valid audit evidence.
9. Do not write `_local_dependency_remediation/` as a release artifact.

## Failure Stop Rule

Any failure in tests, Integrated Closure Gate, Closure Pack generation, repository cleanup, push, campaign baseline RC tag creation, or CI verification must stop the transition. The run must write checkpoint and resume evidence, and Campaign 4 must remain blocked.

Required failure fields:

- `failed_step`
- `error_type`
- `retry_count`
- `last_success_checkpoint`
- `resume_prompt`
- `next_safe_action`

## Forbidden Misinterpretations

1. Do not run Campaign 1-3 total closure directly after Campaign 3 Supplement 3.0.
2. Do not skip Campaign 3 Supplement 4.0.
3. Do not call Campaign 3 Supplement 4.0 `Campaign 4`.
4. Do not call Campaign 4 `4.0`.
5. Do not enter Campaign 4 before Supplement 4.0 completes.
6. Do not enter Campaign 4 before Campaign 3 Final Consistency Gate passes.
7. Do not enter Campaign 4 before Campaign 1-3 Stage Test Gate passes.
8. Do not enter Campaign 4 before Integrated Closure Gate passes.
9. Do not tag before repository push succeeds.
10. Do not enter Campaign 4 before CI/CL is green.
11. Do not treat Closure Pack as a Release Pack.
12. Do not treat CI green as EXE delivery.
13. Do not treat TasteSkill or Product Design Plugin as Campaign 4 base acceptance.
14. Do not treat Campaign 5 raw allowlist presence as chain-level Bridge execution.
15. Do not treat Agent Package as Campaign 6 Agent Runtime.
16. Do not treat Redis or Vector DB configuration as Agent memory runtime.
17. Do not treat focused tests or Fast Gate as Campaign 8 Full Testing / Full Review.
18. Do not treat packaging scripts or build folders as Campaign 9 EXE acceptance.
19. Do not generate Campaign 1-3 integrated review and new-conversation handoff reports before real push, tag, CI Green, and Closure Checklist Green evidence exists.

`final_target_not_downgraded = true`
`not_goal_complete = true`
