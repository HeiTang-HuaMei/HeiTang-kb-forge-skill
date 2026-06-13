# Campaign Stage Gate Policy

This policy applies to every target-mode campaign. It prevents a local slice, a single CLI pass, or a UI status surface from being promoted into campaign acceptance.

## Scope Lock

The same strong gate mechanism applies to Campaigns 1-9 and Final Release. It is not limited to Campaign 1 or Campaign 2.

Each campaign must prove:

1. Entry Gate before it may become active.
2. Acceptance Gate before it may be marked accepted.
3. Transition Gate before the next campaign may open.

No campaign can inherit acceptance from a previous local E2E, report export, status card, schema, allowlist, focused test, packaging script, or ledger remaining gap.

## Authority Order

1. `PLAN_SEQUENCE_LOCK.md` decides execution order.
2. `TARGET_ACCEPTANCE_MATRIX.md` defines campaign acceptance conditions.
3. `GOAL_ACCEPTANCE_LEDGER.json` records status and evidence only.
4. `GOAL_ACCEPTANCE_LEDGER.json` must not choose the next campaign, override the plan sequence, or convert `remaining_gap` into scheduling authority.

## Universal Gates

Every campaign must have all three gates:

- Entry Gate: proves the previous campaign is accepted and this campaign is allowed to become active.
- Acceptance Gate: proves the current campaign met its own acceptance matrix.
- Transition Gate: proves the next campaign may open and records any blocked later campaigns.

The previous campaign must be accepted before the next campaign can become active. The current campaign must be accepted before the following campaign can be marked active.

## Non-Substitution Rules

The following evidence cannot substitute for campaign acceptance:

- `local_e2e_passed` cannot substitute `campaign_accepted`.
- `focused_tests_passed` or Fast Gate cannot substitute `full_gate_passed`.
- A single CLI pass cannot substitute UI, Core Bridge, configuration, or EXE acceptance.
- `report_export` cannot substitute Campaign 2 acceptance.
- `integration_decision_report` cannot substitute UI impact.
- `ui_action_entry_present` cannot substitute `goal_oriented_ui_workbench_accepted`.
- `bridge_allowlist_present` cannot substitute `bridge_execution_accepted`.
- A configuration schema cannot substitute real configuration checks.
- `packaging_script_present` cannot substitute `exe_accepted`.
- `structured_skipped` cannot count as a real backend integration.
- `dependency_missing` cannot count as `real_integration`.
- A planned adapter cannot be displayed or counted as a real adapter.

## Transition Predicate Table

| Attempted transition | Required predicate | Explicitly blocked when |
| --- | --- | --- |
| Campaign 3 active | Campaign 1 accepted and Campaign 2 accepted | Campaign 1 or Campaign 2 is not accepted |
| Pre-4.0 Workspace Partition Gate active | Campaign 3 Supplement 3.0 accepted after its stop point | Campaign 3 Supplement 3.0 is incomplete, or the run tries to skip the 3.0 stop point |
| Campaign 3 Supplement 4.0 active | Pre-4.0 Workspace Partition Foundation Gate passed | Pre-4.0 Workspace Partition Foundation Gate is incomplete, or the run tries to skip workspace/KB-scope foundations |
| Campaign 1-3 Stage Test Gate active | Campaign 3 Supplement 4.0 accepted and Campaign 3 Final Consistency Gate passed | Campaign 3 Supplement 4.0 is incomplete, or the Campaign 3 Final Consistency Gate has not passed |
| Campaign 1-3 Integrated Closure Gate active | Campaign 1-3 Stage Test Gate passed | Stage Test Gate failed, was skipped, or is only partially run |
| Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate active | Closure Pack generated after Integrated Closure Gate passed | Closure Pack missing, tests failed, closure failed, JSON parse failed, `git diff --check` failed, or secret boundaries are dirty |
| Repository push | Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed | Cleanup inventory missing, forbidden tracked files found, secret scan failed, large runtime binary check failed, rename compatibility not recorded, or push target/credentials are missing |
| Closure tag creation | Repository push succeeded | Push failed, push evidence is absent, or tag safety report failed |
| Campaign 4 active | Campaign 3 accepted, Campaign 1-3 closure tag exists, tag-related CI/CL is green, Closure Checklist is green, Campaign 1-3 Integrated Review and New Conversation Handoff Gate passes, and the Campaign 4 Goal-Oriented Product UI Workbench Entry Gate passes | Campaign 3 is in progress, Supplement 4.0 is incomplete, Stage Test/Closure/Repository Cleanup/Push/Tag/CI/Closure Checklist/Review-Handoff is missing or failed, only per-project decisions exist, or the run tries UI redesign before CI/CL green |
| Campaign 5 active | Campaign 4 accepted and `goal_oriented_ui_workbench_accepted = true` | Only UI action entries, status cards, static previews, old page lists, or flat technical menus exist |
| Campaign 6 active | Campaign 5 accepted and `bridge_execution_accepted = true` | Only bridge allowlist or action mapping exists, or only Agent Package exists without runtime/memory acceptance |
| Campaign 7 active | Campaign 6 accepted and `agent_runtime_memory_accepted = true` | Only Agent Package, runtime schema, or memory spec exists |
| Campaign 8 active | Campaign 7 accepted and configuration checks accepted | Only configuration schema or settings files exist |
| Campaign 9 active | Campaign 8 accepted and `full_gate_passed = true` | Only focused tests, Fast Gate, scoped tests, or partial packaging smoke exists |
| Final Release allowed | Campaigns 1-9 accepted and `exe_accepted = true` | Packaging script exists without EXE install/run acceptance |

The table above is normative. `GOAL_ACCEPTANCE_LEDGER.json` may record progress, but it cannot make any blocked transition true.

## Campaign Gates

### Campaign 1: Document Backend / OCR / Document Understanding Backend Strengthening

Entry Gate:
- Target-mode backend contract and backend list are fixed.
- Dependency remediation is allowed and must be attempted where needed.

Acceptance Gate:
- Backend remediation acceptance review exists.
- PaddleOCR, MinerU, Docling, Marker, OpenDataLoader, Surya, Unstructured, and fallback parser are each reviewed.
- Real integrations require remediation/check/smoke or real-run evidence.
- Surya may be accepted only as a non-primary benchmark/reference boundary when it remains `needs_strengthening`.
- Unstructured and fallback parser must clearly state their limited basic-text boundary and must not claim full Document Understanding.
- Structured skipped is only fallback evidence, not completion evidence.

Transition Gate:
- Campaign 2 may open only after the Campaign 1 acceptance review is `accepted`.
- Campaign 3 cannot open from Campaign 1 evidence alone.

### Campaign 2: Batch Import / DU / KB / Package / Search / Report Export

Entry Gate:
- Campaign 1 acceptance review is `accepted`.

Acceptance Gate:
- Real multi-file E2E evidence exists.
- The chain covers batch import, document preflight, backend selection/recommendation, Document Understanding, knowledge base build, knowledge package build, search/index query, governed knowledge/report export, progress/failure evidence, source trace, quality report, and evidence map.
- Report export must be governed chain export evidence; it cannot be the only proof of Campaign 2.
- No LLM and no vector DB remain valid default operation modes.

Transition Gate:
- Campaign 3 may become active only when Campaign 1 and Campaign 2 are both accepted.

### Campaign 3: Not-Yet-Integrated Projects One by One

Entry Gate:
- Campaign 1 and Campaign 2 are accepted by `PRE_CAMPAIGN_ACCEPTANCE_GATE.md`.
- The current project item is selected from Section 5 of the 12-section target plan.
- Campaign 3 Supplement 2.0 may refine Section 5 item handling, but it must not change the 12-section total plan or open Campaign 4 early.
- Campaign 3 Supplement 3.0 may start only after all Supplement 2.0 main-line and strengthening items plus the Supplement 2.0 closure gate pass.
- Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate may start only after Supplement 3.0 acceptance.
- Campaign 3 Supplement 4.0 may start only after the Pre-4.0 Workspace Partition Foundation Gate passes.
- Campaign 1-3 Stage Test Gate may start only after Supplement 4.0 acceptance and the Campaign 3 Final Consistency Gate pass.
- Campaign 1-3 Integrated Closure Gate may start only after Stage Test Gate is green.
- Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag creation, CI/CL green verification, Closure Checklist green verification, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate must run in that order before Campaign 4 Goal-Oriented Product UI Workbench Entry Gate.

Acceptance Gate:
- Items 5.1 through 5.14 are processed one project at a time.
- Strengthening items 5.S1 through 5.S3 have a decision report or explicit deferred record.
- Campaign 3 Supplement 2.0 closure gate passes.
- Campaign 3 Supplement 3.0 External Source Memory & Verification passes its Entry and Acceptance Gates.
- Supplement 3.0 P0 covers Generic Web URL Ingestion, Platform Link Preflight, OpenCLI verification, Manual Evidence Upload, unified source trace/evidence map, progress, failure isolation, a real External Link Import entry, and real Core Bridge allowlist registrations with no-shell tests.
- Supplement 3.0 P1 is either accepted with evidence or truthfully recorded as a strengthening gap; it includes the authorized visible-content connector, video/visual evidence foundations, and knowledge verification foundations.
- Supplement 3.0 preserves the no-login-bypass, no-CAPTCHA-bypass, no-paywall-bypass, no-cookie-import/save/upload, no-unlimited-crawler, user-triggered-source boundary.
- Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate passes after Supplement 3.0 acceptance and before Supplement 4.0. It must define workspace manifest/registry, KB partition/access scopes, path boundaries, legacy default workspace registration, UI handoff, and Bridge handoff without claiming runtime enforcement, Campaign 4 UI, Campaign 5 Bridge, Agent runtime, or allowlist expansion.
- Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract passes its Entry and Acceptance Gates.
- Supplement 4.0 supports literary, visual/video, domain expert, operations/growth, product/business, research/learning, and general personal Skill types; video remains one subtype only.
- Supplement 4.0 generates source-traced Skill Template, Dedicated Skill, Agent Package, workspace binding spec, memory isolation spec, single/multi-agent mode spec, Campaign 4 UI handoff, and Campaign 5 Bridge handoff evidence.
- Supplement 4.0 generation always starts at `draft`; validator/testcase evidence controls `validated`; explicit user confirmation gates publication or publish-ready states.
- Supplement 4.0 must not replace P2.2 Skill Governance / Skill Suite, write Agent Package as Agent runtime, write memory policy as Redis/vector runtime, write Multi-Agent Workflow Spec as execution, write UI handoff as Campaign 4 completion, or write Bridge handoff as Campaign 5 completion.
- Product Output Surface and External Trend Alignment must be preserved: `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package` are distinct product surfaces; Document Outputs include Markdown, DOCX / Word, PDF, and PPTX / PowerPoint through existing `generate-documents` and are not covered by Skill Outputs.
- Each project item has `integration_decision_report.json/.md`.
- Each project or strengthening item has a UI impact note or explicit no-business-UI decision.
- Each item chooses exactly one of `real_integration`, `reference_only`, `needs_strengthening`, or `stop_integration`.
- New items must first be checked for overlap with existing capability domains.
- Highly overlapping items are handled as strengthening, adapter, or future module slots instead of duplicate runtime integrations.
- No external source code, prompt, `SKILL.md`, script, or runtime may be copied or vendored without explicit evidence and authorization.
- Core registry and UI assets must agree on every item status.
- Targeted tests, governance tests, drift tests, relevant UI focused tests, and `git diff --check` must pass.
- Reference-only items are never displayed as runtime backends.
- The expanded Campaign 3 final consistency gate must cover Supplements 2.0, 3.0, and 4.0.
- The same expanded Campaign 3 final consistency gate must also cover Product Output Surface and External Trend Alignment before Campaign 3 can be accepted.
- After the Campaign 3 Supplement 4.0 Acceptance Gate, business implementation stops and the next safe action is `Campaign 3 Final Consistency Gate only.`
- After the Campaign 3 Final Consistency Gate passes in its own locked item, the next safe action becomes `Run Campaign 1-3 Stage Test Gate only.`
- Campaign 1-3 Stage Test Gate, Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag creation, CI/CL green verification, Closure Checklist green verification, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate are mandatory before Campaign 4 Goal-Oriented Product UI Workbench Entry Gate.

Transition Gate:
- Campaign 4 cannot open until every Section 5 item, the 5.S1-5.S3 strengthening records, the Supplement 2.0 closure gate, Supplement 3.0 acceptance, the Pre-4.0 Workspace Partition Foundation Gate, Supplement 4.0 acceptance, the expanded Campaign 3 final consistency gate, Campaign 1-3 Stage Test Gate, Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, closure tag creation, tag-related CI/CL green verification, Closure Checklist green verification, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate are accepted or explicitly deferred by user-approved plan change.
- Campaign 3 Supplement 4.0 is not Campaign 4. Campaign 4 is not `4.0`.
- Any test, closure, repository cleanup, push, tag, or CI failure must stop and write checkpoint plus `resume_prompt`; Campaign 4 remains blocked.
- Before CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate, Campaigns 4-9, Final Release, TasteSkill, Product Design Plugin, UI redesign, and future Campaign Bridge allowlist changes remain blocked.

### Campaign 4: Goal-Oriented Product UI Workbench

Entry Gate:
- Campaign 3 is accepted.
- Campaign 1-3 Stage Test Gate, Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag creation, and CI/CL green are complete.
- The replacement plan in `CAMPAIGN_4_9_REPLACEMENT_PLAN.md` is registered.

Acceptance Gate:
- The UI is organized around the product line: Workspace, Import Materials, Knowledge Base, Skill / Agent, Multi-Agent Workflow, Export / Audit, and Settings / Diagnostics.
- Top-level navigation has no more than seven entries.
- Workspace Home uses task cards with at most one primary action per card.
- Technical pages are reconciled into task flows, detail panels, advanced panels, diagnostics, reports, or future extensions.
- UI truthfully displays dependency, runtime, smoke, skipped, failed, repair suggestion, integration decision, source trace, and evidence states.
- UI does not show reference-only, skipped, planned-not-active, framework-only, preflight-only, provider-not-integrated, Skill draft, Agent spec, or Multi-Agent spec as executable completion.
- TasteSkill and Product Design Plugin are only Campaign 4.x enhancement backlog candidates, not base acceptance.

Transition Gate:
- Campaign 5 cannot open until `goal_oriented_ui_workbench_accepted = true`.

### Campaign 5: Chain-Level Local Core Bridge

Entry Gate:
- Campaign 4 is accepted.

Acceptance Gate:
- User tasks map to allowlisted bridge flows instead of exposing raw Core action buttons.
- One user task may orchestrate multiple allowlisted actions with ordered preconditions, outputs, audit logs, failure points, and recovery actions.
- Bridge execution is verified for the retained allowlisted actions.
- Path boundaries, parameter validation, timeouts, structured errors, audit logs, and no arbitrary shell execution are verified.
- UI action entry, allowlist presence, and action mapping are not enough.
- Skill, Agent, and Multi-Agent actions missing from the current allowlist remain `display_only`, `planned_not_active`, `bridge_action_missing`, or `future_allowlist_candidate`, never executable.

Transition Gate:
- Campaign 6 cannot open until `bridge_execution_accepted` is true.

### Campaign 6: Agent Runtime & Memory Platform

Entry Gate:
- Campaign 5 is accepted.

Acceptance Gate:
- Single-Agent runtime can load Agent Packages, use bound KBs and Skills, enforce tool permissions, write run logs and audit traces, verify output, and export run reports.
- Agent short-term and long-term memory semantics have fallback behavior and do not crash when Redis or Vector DB is unavailable.
- Agent private memory, workspace memory, run memory, audit memory, and shared workflow memory enforce isolation and explicit sharing rules.
- Agent A cannot read Agent B private memory; Workspace A cannot read Workspace B data.
- Multi-Agent runtime, if incomplete, is truthfully displayed as spec ready but runtime not ready and not executable.
- Agent Package, memory spec, Redis config, or Vector DB config alone is not Agent Runtime & Memory acceptance.

Transition Gate:
- Campaign 7 cannot open until `agent_runtime_memory_accepted = true`.

### Campaign 7: Configuration System

Entry Gate:
- Campaign 6 is accepted.

Acceptance Gate:
- API base URL, reverse proxy, API key, model, embedding model, rerank model, SQLite, PostgreSQL, Redis, vector DB, workspace path, Agent runtime config, Agent memory backend config, Multi-Agent shared memory config, and OpenCLI/external verification config are configurable and diagnosable.
- Settings export/import works.
- `check-api-proxy`, `check-db`, `check-redis`, `check-vector-db`, `check-agent-runtime`, `check-agent-memory-backend`, and `check-opencli` have real check evidence.
- A config file, schema, or settings form alone is not acceptance.

Transition Gate:
- Campaign 8 cannot open until configuration checks and diagnostics are accepted.

### Campaign 8: Full Testing / Full Review

Entry Gate:
- Campaign 7 is accepted.

Acceptance Gate:
- Core Full Gate, UI Full Gate, backend adapter smoke tests, missing dependency tests, batch import tests, preflight tests, Document Understanding tests, external source tests, knowledge verification tests, knowledge package tests, search tests, Skill tests, external Skill learning tests, Agent Package tests, Agent runtime tests, Agent output verification tests, Agent memory isolation tests, Multi-Agent workflow tests, DB/Redis/vector/API/proxy/OpenCLI config tests, Core Bridge tests, export report tests, packaging smoke, `git diff --check`, Release Check, and Full Review pass.
- Fast Gate, focused tests, scoped tests, or a single green command do not count as Full Testing / Full Review acceptance.

Transition Gate:
- Campaign 9 cannot open until `full_gate_passed` is accepted.

### Campaign 9: EXE Packaging

Entry Gate:
- Campaign 8 is accepted.

Acceptance Gate:
- Windows EXE, installer, portable package, first-run setup, default workspace, default SQLite, dependency checker, backend diagnostics, config wizard, diagnostics report, user guide, install guide, and diagnostics guide are delivered.
- A real install or run smoke proves the user can open UI, create workspace, import materials, build/search/verify KBs, generate or learn Skills, create/bind/run a basic Agent task, verify Agent output, configure dependencies, diagnose memory backends, and export reports/packages.
- Redis, Vector DB, LLM, and OpenCLI missing states must not crash and must display degraded, optional, or not configured states.
- Packaging script presence is not EXE acceptance.

Transition Gate:
- Final Release cannot open until `exe_accepted` is true.

### Final Release

Entry Gate:
- Campaigns 1 through 9 are all accepted.

Acceptance Gate:
- Final commit, push, tag, and GitHub Release are allowed only after the full target evidence exists.
- Workspace status, HANDOFF, task_log, and global pitfall log sync are required before release.

Transition Gate:
- No later transition exists. Until this gate opens, push, tag, and release remain blocked.

## Current Gate Review

- Campaign 1 acceptance review: `accepted`
- Campaign 2 acceptance review: `accepted`
- Campaign 3 status: `in_progress`
- Campaign 3 active: `true`
- Campaign 3 item 5.1 LLM Wiki v2: `advanced`
- Campaign 3 item 5.2 WeKnora: `advanced`
- Campaign 3 item 5.3 AnySearchSkill: `advanced_needs_strengthening`
- Campaign 3 item 5.4 n8n: `advanced`
- Campaign 3 item 5.5 MMSkills: `advanced_reference_only`
- Campaign 3 item 5.6 skill-prompt-generator: `advanced`
- Campaign 3 item 5.7 ai-marketing-skills: `advanced`
- Campaign 3 item 5.8 ai-money-maker-handbook: `advanced`
- Campaign 3 item 5.9 Jellyfish: `advanced_reference_only`
- Campaign 3 item 5.10 story-flicks: `advanced_reference_only`
- Campaign 3 item 5.11 seedance2-skill: `advanced_reference_only`
- Campaign 3 item 5.12 RAG-Anything: `advanced_reference_only`
- Campaign 3 item 5.13 mattpocock/skills: `advanced_real_integration_rule_pack_only`
- Campaign 3 item 5.14 Sirchmunk: `advanced_real_integration_direct_file_search_only`
- Campaign 3 strengthening item 5.S1 GBrain: `advanced_strengthening_record_only`
- Campaign 3 strengthening item 5.S2 Horizon: `advanced_topic_intake_schema_only`
- Campaign 3 strengthening item 5.S3 Obsidian-compatible Vault: `advanced_local_vault_adapter_only`
- Campaign 3 Supplement 2.0 closure gate: `passed`
- Campaign 3 next business item: `Campaign 3 Final Consistency Gate only`
- Campaign 3 Supplement 3.0 Entry Gate: `passed`
- Campaign 3 Supplement 3.0 P0 framework: `passed_framework_only`
- Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion: `passed_generic_web_url_only`
- Campaign 3 Supplement 3.0 P0 Platform Link Preflight: `passed_platform_preflight_only`
- Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification: `passed_opencli_verification_only`
- Campaign 3 Supplement 3.0 P0 Manual Evidence Upload: `passed_manual_evidence_only`
- Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, and failure isolation: `passed_unified_trace_only`
- Campaign 3 Supplement 3.0 P0 External Link Import entry and completed-P0 allowlist/no-shell: `passed_entry_bridge_allowlist_only`
- Campaign 3 Supplement 3.0 P1 Authenticated Browser Connector Alpha: `passed_authenticated_visible_content_alpha_only`
- Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations: `passed_video_visual_foundations_only`
- Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations: `passed_knowledge_verification_foundations_only`
- Campaign 3 Supplement 3.0: `accepted_stop_pre_4_0_next`
- Campaign 3 Supplement 3.0 accepted: `true`
- Pre-4.0 Workspace Partition Foundation Gate: `passed_foundation_contract`
- Pre-4.0 Workspace Partition Foundation Gate passed: `true`
- Campaign 3 Supplement 4.0: `accepted_for_campaign_3_final_consistency_gate`
- Campaign 3 Supplement 4.0 entry gate: `passed`
- Campaign 3 Supplement 4.0B Knowledge-to-Skill Template Generator: `passed`
- Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer: `passed`
- Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle: `passed`
- Campaign 3 Supplement 4.0 accepted: `true`
- Campaign 3 Final Consistency Gate: `next_required`
- Campaign 1-3 Stage Test Gate: `blocked_by_sequence`
- Campaign 1-3 Integrated Closure Gate: `blocked_by_sequence`
- Campaign 1-3 Closure Pack: `not_generated`
- Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate: `not_started`
- Repository push: `not_started`
- Campaign 1-3 closure tag: `not_created`
- Campaign 1-3 closure CI: `not_checked`
- Campaign 3 accepted: `false`
- Campaigns 4-9 status: `blocked_by_sequence`
- Final Release status: `blocked_until_campaigns_1_to_9_accepted`

This policy does not mark the final product complete.
