# Plan Sequence Lock

This file locks execution order for HeiTang KB Forge target-mode work.

## Rule

The user-uploaded 12-section target plan is the execution-order source of truth.

`GOAL_ACCEPTANCE_LEDGER.json` records capability status and evidence. It does not decide the next task. A `remaining_gap` entry may explain risk, but it cannot override the 12-section plan sequence or pull a later campaign forward.

## Authority Order

1. `docs/governance/PLAN_SEQUENCE_LOCK.md` decides execution order.
2. `docs/governance/TARGET_ACCEPTANCE_MATRIX.md` defines acceptance conditions.
3. `docs/governance/PRE_CAMPAIGN_ACCEPTANCE_GATE.md` decides whether the next campaign may open.
4. `docs/governance/GOAL_ACCEPTANCE_LEDGER.json` records status only.

## Ledger Boundary

`GOAL_ACCEPTANCE_LEDGER.json` is a status ledger only. It may show capability evidence, remaining gaps, and drift review, but it must not be used as a scheduler, priority selector, or permission to skip ahead of the 12-section plan.

Every task start must read, in this order:

1. `docs/governance/PLAN_SEQUENCE_LOCK.md`
2. `docs/governance/CAMPAIGN_STAGE_GATE_POLICY.md`
3. `docs/governance/PRE_CAMPAIGN_ACCEPTANCE_GATE.md`
4. `docs/governance/TARGET_ACCEPTANCE_MATRIX.md`
5. `docs/governance/TARGET_MODE_ACCEPTANCE_PLAN.md`
6. `docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md`
7. `docs/governance/CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md`
8. `docs/governance/PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md`
9. `docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md`
10. `docs/governance/REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md`
11. `docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md`
12. `docs/governance/CAMPAIGN_3_FINAL_CONSISTENCY_GATE_POLICY.md`
13. `docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md`
14. `docs/governance/CAMPAIGN_4_5_REPLACEMENT_PLAN.md`
15. `docs/governance/GOAL_ACCEPTANCE_LEDGER.json`

Then Codex must declare:

1. the current plan section and campaign;
2. the next required item from the plan sequence;
3. any later items that are not allowed to advance in the current task;
4. whether the user explicitly changed the plan order;
5. which campaign states cannot be marked by the current task.

## Current Sequence Position

Current required advance:

- Plan section: `5. 第三战役`
- Current campaign: Campaign 3 project-by-project processing
- Current supplement: Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract; do not change the 12-section total plan
- Completed supplement step: Campaign 3 Supplement 3.0 Acceptance Gate passed with verdict `accepted_for_pre_4_0_workspace_partition_foundation_gate`.
- Completed foundation gate: Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate passed with verdict `accepted_for_campaign_3_supplement_4_0_entry_gate`.
- Completed entry gate: Campaign 3 Supplement 4.0 Entry Reconciliation Gate passed with verdict `accepted_for_campaign_3_supplement_4_0_implementation`.
- Completed 4.0B item: Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation passed with source-traced draft, validator report, and testcase evidence.
- Completed 4.0C item: Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer passed with dedicated Skill package, source binding, conflict report, document-output boundary, validator report, and testcase evidence.
- Completed 4.0D-I bundle: Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle passed with Agent Package, workspace binding, memory isolation, single/multi-Agent mode, Campaign 4 UI handoff, and Campaign 5 Bridge handoff evidence.
- Completed Supplement 4.0 Acceptance Gate: verdict `accepted_for_campaign_3_final_consistency_gate`.
- Campaign 3 Final Consistency Gate: `not_started_current_lock`.
- Campaign 1-3 Stage Test Gate: `blocked`.
- Campaign 1-3 Integrated Closure Gate: `blocked`.
- Campaign 1-3 Closure Pack: `blocked`.
- Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate: `blocked`.
- Current stop point: Campaign 3 Supplement 4.0 Acceptance Gate passed; do not run Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test, Integrated Closure, Closure Pack, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, push, tag, CI, Campaign 4, Campaign 5, Full Gate, EXE, or Release in the same item.
- Next locked item: Campaign 3 Final Consistency Gate only.
- Current locked post-Supplement-4.0 chain: Supplement 4.0 is accepted for the Final Consistency transition after the bounded industrial-grade Acceptance Gate passed.
- Later post-Campaign-3 gate chain: Campaign 1-3 Stage Test Gate, Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, baseline tag, CI/CL green, Closure Checklist green, Campaign 1-3 Integrated Review and New Conversation Handoff Gate, and only then Campaign 4 Goal-Oriented Product UI Workbench Entry Gate
- Current completed Section 5 items: `5.1 LLM Wiki v2`, `5.2 WeKnora`, `5.3 AnySearchSkill`, `5.4 n8n`, `5.5 MMSkills`, `5.6 skill-prompt-generator`, `5.7 ai-marketing-skills`, `5.8 ai-money-maker-handbook`, `5.9 Jellyfish`, `5.10 story-flicks`, `5.11 seedance2-skill`, `5.12 RAG-Anything`, `5.13 mattpocock/skills`, `5.14 Sirchmunk`, `5.S1 GBrain`, `5.S2 Horizon`, `5.S3 Obsidian-compatible Vault`
- Next business item: `Campaign 3 Final Consistency Gate only`

Reason:

- Campaign 1 acceptance review is now recorded as `accepted`.
- Campaign 2 acceptance review is now recorded as `accepted`.
- `PRE_CAMPAIGN_ACCEPTANCE_GATE.md` records that Campaign 3 was allowed to open after Campaign 1 and 2 acceptance.
- Section 5 items 5.1 through 5.14 now have governed integration decision and UI impact evidence.
- Item 5.6 is local Prompt Asset Library enhancement only; it does not copy external prompts, bundle a runtime, or replace P2.2 Skill Factory.
- Item 5.7 is a local original Marketing Skill Pattern Library only; it does not copy ai-marketing-skills code, prompts, `SKILL.md` files, scripts, or runtime, and it exposes no crawler, paid media, account operation, or revenue guarantee.
- Item 5.8 is a local original Business Scenario Template Library only; it does not copy ai-money-maker-handbook code, content, prompts, `SKILL.md` files, scripts, or runtime, and it exposes no trading, payment, ad spend, crawler, account operation, financial advice, money automation, or revenue guarantee.
- Item 5.9 is a local original Content Asset Schema reference only; it does not copy Jellyfish code, content, prompts, `SKILL.md` files, scripts, short-drama workbench runtime, video generation runtime, asset rendering runtime, media operation, or runtime.
- Item 5.10 is a local original AIGC Video Pipeline Schema reference only; it does not copy story-flicks code, content, prompts, `SKILL.md` files, scripts, story-to-video runtime, image/audio/video generation runtime, voice cloning, media rendering, provider execution, or runtime.
- Item 5.11 is verified public MIT video Skill template metadata only; no external `SKILL.md` or prompt body is copied, exact provider API/pricing contracts remain unverified after official-document access timed out, and no API key, provider adapter, video generation, media operation, or executable action is integrated.
- Item 5.12 is a verified MIT cross-modal RAG schema, trace, and benchmark reference only; no RAG-Anything, LightRAG, MinerU, LLM/VLM, embedding, vector database, external-source ingestion, or multimodal query runtime is bundled or executed, and the existing RAG main chain is not replaced.
- Item 5.13 is a verified MIT local engineering governance rule-pack only; no mattpocock/skills code, prompts, `SKILL.md` files, scripts, external runtime, Skill install, Agent creation, Agent binding, or executable workflow is bundled or executed.
- Item 5.14 is a verified Apache-2.0 local bounded direct-file-search provider candidate only; no Sirchmunk runtime, external code, prompts, dependencies, LLM/API key, network call, embedding, vector DB, index build requirement, unsafe path access, or arbitrary shell execution is bundled or executed.
- Strengthening item 5.S1 is a verified MIT local memory/profile/KG strengthening record only; no GBrain runtime, Bun dependency, PGLite/Postgres/pgvector store, MCP connector, imported skillpack, Agent creation, Agent binding, or external ingestion is installed, configured, or executed.
- Strengthening item 5.S2 is a verified MIT local Topic Intake Pipeline schema only; no Horizon runtime, crawler, scheduler, delivery channel, MCP connector, API key, external workflow, or Campaign 3.0 external-source ingestion is installed, configured, or executed.
- Strengthening item 5.S3 is a local Obsidian-compatible Markdown Vault Adapter only; no Obsidian runtime, plugin, sync service, account, database, network dependency, external-source ingestion, Campaign 3.0, or Campaign 4 UI acceptance is installed, configured, or executed.
- Campaign 3 2.0 supplements Section 5 with capability-domain deduplication, one additional item 5.14 Sirchmunk, and strengthening records 5.S1 through 5.S3. It does not alter Campaign 1, Campaign 2, Campaign 4, or the 12-section total plan.
- The user explicitly inserted Campaign 3 3.0 after Campaign 3 2.0 and before Campaign 4. This extension stays inside Section 5 and does not renumber or replace any of the 12 sections.
- The user explicitly inserted the Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate after Campaign 3 Supplement 3.0 Acceptance Gate and before Campaign 3 Supplement 4.0. This gate has passed as a foundation contract only; it must not be mistaken for Campaign 4 UI, Campaign 5 Bridge, runtime KB scope enforcement, or Agent runtime.
- The user explicitly inserted Campaign 3 4.0 after the Pre-4.0 Workspace Partition Gate and before Campaign 4, then replaced its scope with `Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`. This extension stays inside Section 5, supports seven Skill categories, must not be reduced to a video-only generator, and must carry verified knowledge through Skill, dedicated Skill, Agent Package, workspace binding, memory isolation spec, multi-agent workflow spec, Campaign 4 UI handoff, and Campaign 5 Bridge handoff.
- The user explicitly corrected that Campaign 3 Supplement 4.0 must not be deleted, skipped, or renamed as Campaign 4. After Supplement 3.0, the next stop is only Supplement 4.0 Entry Gate; Campaign 1-3 Stage Test Gate waits until Supplement 4.0 acceptance and the Campaign 3 Final Consistency Gate pass.
- The user explicitly replaced future Campaigns 4 through 9 in `CAMPAIGN_4_9_REPLACEMENT_PLAN.md`: Campaign 4 is `Goal-Oriented Product UI Workbench`, Campaign 5 is `Chain-Level Local Core Bridge`, Campaign 6 is `Agent Runtime & Memory Platform`, Campaign 7 is `Configuration System`, Campaign 8 is `Full Testing / Full Review`, and Campaign 9 is `EXE Packaging`. This replacement is governance registration only; it does not enter Campaigns 4-9, Final Release, or change the current Campaign 3 next item.
- The user explicitly inserted the Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate after Closure Pack generation and before repository push, baseline tag, CI/CL green verification, and Campaign 4 Entry. This gate is registered now as a future gate only; it cannot run before Supplement 4.0, Campaign 3 Final Consistency, Stage Test, Integrated Closure, and Closure Pack generation pass.
- The user explicitly inserted the Product Output Surface and External Trend Alignment Gate as a governance guard. It records `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package` as distinct product output surfaces; `document_outputs` include Markdown, DOCX / Word, PDF, and PPTX / PowerPoint through existing `generate-documents` capability. It registers external trend projects as future/reference only and does not run external project integration, Campaign 4, push, tag, or CI.
- Campaign 3 Supplement 4.0 is not Campaign 4. Campaign 4 is not 4.0.

## Sequence Gate

Do not advance to a later section until the current campaign is accepted or the user explicitly changes the plan order.

Current blocked later work:

- Knowledge Verification beyond the currently active foundations item
- Any project or supplement after the closure gate out of order
- Campaign 3 3.0 acceptance before its Acceptance Gate
- Pre-4.0 Workspace Partition Foundation Gate before Campaign 3 3.0 acceptance
- Campaign 3 Supplement 4.0 Acceptance Gate before Supplement 4.0 implementation evidence
- Campaign 1-3 Stage Test Gate before Campaign 3 Supplement 4.0 acceptance and Campaign 3 Final Consistency Gate
- Campaign 1-3 Integrated Closure Gate before the Stage Test Gate is green
- Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag, or CI verification before their ordered prerequisites
- Campaigns 4-9 implementation, Final Release, TasteSkill, Product Design Plugin, UI redesign, or future Campaign Bridge allowlist changes before CI/CL green, Closure Checklist green, and the Campaign 1-3 Integrated Review and New Conversation Handoff Gate
- external Skill learning outside the Section 5 order
- owned Skill generation
- multi-agent workflow
- full goal-oriented UI workbench workflow completion
- chain-level Local Core Bridge completion
- Agent Runtime & Memory Platform completion
- API/proxy configuration completion
- DB/Redis/vector DB configuration completion
- Full Testing / Full Review
- EXE packaging
- push, tag, release

## Campaign Transition Lock

- Campaign 1 accepted: `true`
- Campaign 2 accepted: `true`
- Campaign 3 active: `true`
- Campaign 3 item 5.1 advanced: `true`
- Campaign 3 item 5.2 advanced: `true`
- Campaign 3 item 5.3 advanced: `true`
- Campaign 3 item 5.4 advanced: `true`
- Campaign 3 item 5.5 advanced: `true`
- Campaign 3 item 5.6 advanced: `true`
- Campaign 3 item 5.7 advanced: `true`
- Campaign 3 item 5.8 advanced: `true`
- Campaign 3 item 5.9 advanced: `true`
- Campaign 3 item 5.10 advanced: `true`
- Campaign 3 item 5.11 advanced: `true`
- Campaign 3 item 5.12 advanced: `true`
- Campaign 3 item 5.13 advanced: `true`
- Campaign 3 item 5.14 advanced: `true`
- Campaign 3 strengthening item 5.S1 advanced: `true`
- Campaign 3 strengthening item 5.S2 advanced: `true`
- Campaign 3 strengthening item 5.S3 advanced: `true`
- Campaign 3 sequence status: `supplement_4_0_accepted_for_campaign_3_final_consistency_gate`
- Campaign 3 accepted: `false`
- Next Section 5 item: `Campaign 3 Final Consistency Gate only`
- Campaign 3 remaining main items: `none`
- Campaign 3 strengthening items remaining: `none`
- Campaign 3 Supplement 2.0 closure gate passed: `true`
- Campaign 3 Supplement 3.0 entry gate passed: `true`
- Campaign 3 Supplement 3.0 P0 framework passed: `true`
- Campaign 3 Supplement 3.0 P0 Generic Web URL Ingestion passed: `true`
- Campaign 3 Supplement 3.0 P0 Platform Link Preflight passed: `true`
- Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification passed: `true`
- Campaign 3 Supplement 3.0 P0 Manual Evidence Upload passed: `true`
- Campaign 3 Supplement 3.0 P0 unified Source Trace / Evidence Map, progress events, and failure isolation passed: `true`
- Campaign 3 Supplement 3.0 P0 External Link Import entry passed: `true`
- Campaign 3 Supplement 3.0 P1 Authenticated Browser Connector Alpha passed: `true`
- Campaign 3 Supplement 3.0 P1 Video-to-Knowledge and Visual Evidence Understanding foundations passed: `true`
- Campaign 3 Supplement 3.0 P1 Knowledge Verification Engine and dashboard foundations passed: `true`
- Campaign 3 Supplement 3.0 plan state: `accepted_stop_pre_4_0_next`
- Campaign 3 Supplement 3.0 acceptance gate passed: `true`
- Campaign 3 Supplement 3.0 accepted: `true`
- Pre-4.0 Workspace Partition Foundation Gate plan state: `passed_foundation_contract`
- Pre-4.0 Workspace Partition Foundation Gate passed: `true`
- Campaign 3 Supplement 4.0 plan state: `accepted_for_campaign_3_final_consistency_gate`
- Campaign 3 Supplement 4.0 entry gate passed: `true`
- Campaign 3 Supplement 4.0B Knowledge-to-Skill Template Generator passed: `true`
- Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer passed: `true`
- Campaign 3 Supplement 4.0D-I Product Handoff Contract Bundle passed: `true`
- Campaign 3 Supplement 4.0 acceptance gate passed: `true`
- Campaign 3 Supplement 4.0 accepted: `true`
- Campaign 3 Final Consistency Gate passed: `false`
- Campaign 1-3 Stage Test Gate passed: `false`
- Campaign 1-3 Integrated Closure Gate passed: `false`
- Campaign 1-3 Closure Pack generated: `false`
- Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed: `false`
- Repository push succeeded: `false`
- Campaign 1-3 closure tag created: `false`
- Campaign 1-3 closure CI green: `false`
- Expanded Campaign 3 final consistency gate required after Supplement 4.0: `next_required`
- Campaign 4 allowed: `false`
- Campaign 5 allowed: `false`
- Campaign 6 allowed: `false`
- Campaign 7 allowed: `false`
- Campaign 8 allowed: `false`
- Campaign 9 allowed: `false`
- Final Release allowed: `false`

`Campaign 3 active` means Section 5 item-by-item processing started. Campaign 3 is not accepted in the current locked state until the expanded Campaign 3 Final Consistency Gate passes in its own item. Campaign 4 still cannot open until Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag creation, CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate pass.

## Campaign 3 Supplement 2.0 Sequence

Campaign 3 2.0 is a supplement to Section 5, not a total-plan rewrite.

Rules:

- Completed items 5.1 through 5.6 do not roll back or get redone; future work may only strengthen them when explicitly assigned.
- New items must first check overlap against existing capability domains.
- Only items with distinct engineering value remain independent project items.
- Highly overlapping items become strengthening, adapters, or future module slots.
- Do not copy external source code, prompts, `SKILL.md`, scripts, or runtime.
- UI may show status, preview, configuration entry, or future slot, but must not default to executable actions.
- 5.S items did not interrupt or reorder the main line; they proceeded only after the completed 5.14 main-line item and before the now-passed Supplement 2.0 closure gate.
- Campaign 3 cannot be accepted from Campaign 3 2.0 closure alone; Supplements 3.0 and 4.0 plus the expanded final consistency gate still must pass.

Main-line order:

1. `5.7 ai-marketing-skills`
2. `5.8 ai-money-maker-handbook`
3. `5.9 Jellyfish`
4. `5.10 story-flicks`
5. `5.11 seedance2-skill`
6. `5.12 RAG-Anything`
7. `5.13 mattpocock/skills`
8. `5.14 Sirchmunk`

Strengthening order after the main line:

1. `5.S1 GBrain strengthening`
2. `5.S2 Horizon strengthening`
3. `5.S3 Obsidian-compatible Vault strengthening`
4. `Campaign 3 Supplement 2.0 closure gate`

The Campaign 3 Supplement 2.0 closure gate has passed with verdict `accepted_for_transition_to_campaign_3_3_0_entry_gate`. The 5.S items are complete in their locked order after the completed main line, completed 5.S1 GBrain strengthening record, completed 5.S2 Horizon Topic Intake schema strengthening record, and completed 5.S3 Obsidian-compatible local vault adapter strengthening record. The Campaign 3 Supplement 3.0 Entry Gate has also passed with verdict `accepted_for_campaign_3_3_0_p0_framework_start`. The Campaign 3 Supplement 3.0 P0 framework has passed as `real_integration / framework_only`. The Generic Web URL Ingestion step has passed as `real_integration / generic_web_url_ingestion_only`. The Platform Link Preflight step has passed as `real_integration / platform_preflight_only`. The OpenCLI External Search Verification step has passed as `real_integration / opencli_external_search_verification_only`. The Manual Evidence Upload step has passed as `real_integration / manual_evidence_upload_only`. The unified Source Trace / Evidence Map, progress events, and failure isolation step has passed as `real_integration / unified_trace_evidence_progress_failure_isolation_only`. The External Link Import entry and completed-P0 allowlist/no-shell step has passed as `real_integration / external_link_import_entry_bridge_allowlist_only`. Authenticated Browser Connector Alpha has passed as `real_integration / authenticated_browser_visible_content_connector_alpha`. Video-to-Knowledge and Visual Evidence Understanding foundations have passed as `real_integration / video_visual_foundations_only`, with subtitle timestamp trace, user-supplied image/keyframe OCR, layout blocks, multimodal chunks, evidence map, and structured skipped records for unavailable ffmpeg/ffprobe automation. Knowledge Verification Engine and dashboard foundations have passed as `real_integration / knowledge_verification_foundations_only`, with local claim verification, correctness, answer grounding, dashboard foundation, source trace, evidence map, progress events, and no LLM/network requirement. The Supplement 3.0 Acceptance Gate has passed after 10 evidence bundles, 9 capability checks, 73 focused Core/regression tests, 16 Flutter tests, and Flutter analysis passed. This accepts Supplement 3.0 only; it does not complete Pre-4.0, Supplement 4.0, Campaign 3, Campaign 4, or Campaign 5.

## Campaign 3 Supplement 3.0 Sequence

Campaign 3 3.0 is a new Section 5 supplement, not a total-plan rewrite.

Authority:

- Detailed scope: `docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md`
- State: `accepted_stop_pre_4_0_next`
- Product layer: External Source Memory & Verification
- Activation prerequisite: Campaign 3 Supplement 3.0 Entry Gate, P0 framework, Generic Web URL Ingestion, Platform Link Preflight, OpenCLI External Search Verification, Manual Evidence Upload, and unified Source Trace / Evidence Map, progress events, and failure isolation have passed; the Supplement 2.0 closure gate already passed
- Transition prerequisite: Campaign 3 3.0 acceptance permits only the Pre-4.0 gate, not Supplement 4.0 or Campaign 4

Locked order after Supplement 2.0:

1. `Campaign 3 Supplement 3.0 Entry Gate`
2. P0 External Source Memory & Verification framework
3. P0 Generic Web URL Ingestion
4. P0 Platform Link Preflight
5. P0 OpenCLI External Search Verification
6. P0 Manual Evidence Upload
7. P0 unified Source Trace / Evidence Map, progress events, and failure isolation
8. P0 External Link Import entry plus real Core Bridge allowlist registrations and no-shell tests
9. P1 Authenticated Browser Connector Alpha
10. P1 Video-to-Knowledge and Visual Evidence Understanding foundations
11. P1 Knowledge Verification Engine and dashboard foundations
12. Campaign 3 Supplement 3.0 Acceptance Gate
13. STOP; next safe action is `Run Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate only.`
14. Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate
15. `Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`
16. Campaign 3 Supplement 4.0 Acceptance Gate
17. Expanded `Campaign 3 final consistency gate`
18. STOP; next safe action is `Run Campaign 1-3 Stage Test Gate only.`
19. Campaign 1-3 Stage Test Gate
20. Campaign 1-3 Integrated Closure Gate
21. Closure Pack generation
22. Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate
23. Repository push
24. Tag creation
25. CI green verification
26. Closure Checklist green verification
27. Campaign 1-3 Integrated Review and New Conversation Handoff Gate
28. `Campaign 4 Goal-Oriented Product UI Workbench Entry Gate`

Campaign 3 3.0 safety boundaries are mandatory: no login, CAPTCHA, paywall, platform-control, or anti-detection bypass; no cookie import, plaintext cookie persistence, or cookie upload; no unlimited crawler or high-frequency platform collection; user-triggered and traceable evidence only.

After Campaign 3 Supplement 3.0 acceptance, do not run Campaign 1-3 total closure directly. The Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate must run before Supplement 4.0. Supplement 4.0 must still run as a Campaign 3 internal supplement before the Campaign 3 Final Consistency Gate and before any Campaign 1-3 Stage Test Gate.

## Pre-4.0 Workspace Partition Foundation Gate Sequence

The Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate is a Section 5 foundation gate, not Campaign 4 UI and not Campaign 5 Bridge.

Authority:

- Detailed scope: `docs/governance/PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md`
- State: `passed_foundation_contract`
- Product layer: workspace partition, KB access scope, asset ownership, legacy default workspace registration, path boundary, UI handoff contract, and Bridge handoff contract
- Activation prerequisite: Campaign 3 Supplement 3.0 acceptance
- Transition prerequisite: this gate must pass before Campaign 3 Supplement 4.0 may start

Locked order:

1. `Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate`
2. STOP; next safe action is `Run Campaign 3 Supplement 4.0 Entry Reconciliation Gate only.`
3. `Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`

This gate has passed as a foundation contract only. It generated workspace manifest/registry, KB partition/access-scope, path-boundary, legacy default workspace, UI handoff, and Bridge handoff contracts. It must not move, delete, or rename legacy artifacts; must not claim KB access-scope runtime enforcement, Agent runtime, Campaign 4 UI completion, Campaign 5 Bridge completion, or current Bridge allowlist expansion; and must not create open-any-path behavior.

## Campaign 3 Supplement 4.0 Sequence

Campaign 3 4.0 is a new Section 5 supplement, not a total-plan rewrite.

Authority:

- Detailed scope: `docs/governance/CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md`
- State: `accepted_for_campaign_3_final_consistency_gate`
- Product layer: Knowledge-to-Skill-to-Agent Package & Product Handoff Contract
- Activation prerequisite: Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate passed
- Transition prerequisite: Supplement 4.0 acceptance, the Campaign 3 Final Consistency Gate, the Campaign 1-3 Stage Test Gate, the Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag creation, CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate must all pass before Campaign 4 Goal-Oriented Product UI Workbench Entry Gate

Locked order:

1. 4.0A Entry Reconciliation Gate over 3.0 verification outputs, Pre-4.0 workspace partition outputs, KB artifacts, existing Skill, Agent Package, `knowledge_bound_factory`, `agent_compat`, `generate-agent`, and `generate-bound-agent` - `passed`
2. 4.0B Verified Knowledge-to-Skill Template - `passed`
3. 4.0C Skill Import & Dedicated Skill Composer - `passed`
4. 4.0D Skill-to-Agent Package Unification - `passed`
5. 4.0E Agent Workspace Binding Spec - `passed`
6. 4.0F Agent Memory Isolation Spec - `passed`
7. 4.0G Single-Agent / Multi-Agent Mode Spec - `passed`
8. 4.0H Campaign 4 UI Handoff Contract - `passed`
9. 4.0I Campaign 5 Bridge Handoff Contract - `passed`
10. Campaign 3 Supplement 4.0 Acceptance Gate - `passed`
11. Product Output Surface and External Trend Alignment guard must be checked by the expanded `Campaign 3 final consistency gate`
12. STOP; next safe action is `Campaign 3 Final Consistency Gate only.`
13. Expanded `Campaign 3 final consistency gate` - `next_required`
14. STOP; next safe action after Final Consistency passes is `Run Campaign 1-3 Stage Test Gate only.`
15. Campaign 1-3 Stage Test Gate
15. Campaign 1-3 Integrated Closure Gate
16. Closure Pack generation
17. Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate
18. Repository push
19. Tag creation
20. CI green verification
21. Closure Checklist green verification
22. Campaign 1-3 Integrated Review and New Conversation Handoff Gate
23. `Campaign 4 Goal-Oriented Product UI Workbench Entry Gate`

Generation always starts as `draft`; validation may establish `validated`; only explicit user confirmation may establish publish-ready or published state when that state is in scope. A Skill Template must not directly execute an Agent. Agent Package readiness is not Agent runtime readiness; memory policy files are not Redis/vector runtime completion; Multi-Agent Workflow Spec is not multi-agent execution; UI handoff is not Campaign 4 UI completion; Bridge handoff is not Campaign 5 Bridge completion. `visual_video_skill` is one subtype among seven, not the root product definition.

4.0A Entry Reconciliation passed as a bounded industrial-grade entry gate only. It generated `precondition_matrix.json`, `boundary_matrix.json`, `entry_reconciliation_report.json/.md`, `next_action_manifest.json`, and audit evidence under `artifacts/audits/section_5/campaign_3_supplement_4_0_entry_gate/`. It does not run KB profiler, Skill Generator, Skill Validator, Skill testcase generator, Agent runtime, Campaign 3 Final Consistency Gate, Campaign 4, Campaign 5, Stage Test, Closure, upload, tag, or CI. The next safe action is `Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation`.

4.0B Verified Knowledge-to-Skill Template passed as a bounded industrial-grade implementation. It generated `kb_profile.json`, `skill_opportunity_report.json`, `skill_template_draft.json/.md`, `methodology_rules.json`, `style_profile.json`, `workflow_rules.json`, `prompt_pattern_library.json`, `quality_checklist.json`, `risk_boundaries.json`, `skill_testcases.json`, `skill_source_trace.json`, `skill_validation_report.json`, `validation_report.json`, `run_manifest.json`, `run_summary.md`, and `checkpoint.json` under `artifacts/audits/section_5/campaign_3_supplement_4_0_skill_template/`. It remains a draft source-traced Skill Template output, does not publish a Skill, does not compose a Dedicated Skill, does not generate an Agent Package in 4.0B, does not accept Supplement 4.0, and does not enter Campaign 4 or Campaign 5. The next safe action is `Campaign 3 Supplement 4.0C Skill Import & Dedicated Skill Composer only`.

4.0C Skill Import & Dedicated Skill Composer passed as a bounded industrial-grade implementation. It generated `dedicated_skill_package/`, `composed_skill_manifest.yaml`, `imported_skill_manifest.json`, `skill_distinction_matrix.json`, `skill_source_binding.json`, `skill_conflict_report.json`, `document_output_boundary.json`, `skill_composition_report.md`, `dedicated_skill_validation_report.json`, `validation_report.json`, `run_manifest.json`, `run_summary.md`, and `checkpoint.json` under `artifacts/audits/section_5/campaign_3_supplement_4_0_skill_composer/`. It distinguishes generated, imported, composed, reference-only, planned, and document-output capability surfaces; it does not publish the composed Skill, does not auto-trust imported Skills, does not generate an Agent Package in 4.0C, does not claim Presenton PPT runtime, does not accept Supplement 4.0, and does not enter Campaign 4 or Campaign 5. The next safe action is `Campaign 3 Supplement 4.0D Skill-to-Agent Package Unification only`.

4.0D-I Product Handoff Contract Bundle passed as a bounded industrial-grade implementation. It generated the KB + Skill -> Agent Package evidence under `artifacts/audits/section_5/campaign_3_supplement_4_0_agent_package/`, workspace binding, memory isolation, single/multi-Agent mode, Campaign 4 UI handoff, and Campaign 5 Bridge handoff contracts, plus the D-I bundle audit under `artifacts/audits/section_5/campaign_3_supplement_4_0_product_handoff_bundle/`. Agent Package readiness is not Agent Runtime readiness; Memory Spec is not Redis/vector runtime completion; UI handoff is not Campaign 4 UI completion; Bridge handoff is not Campaign 5 Bridge completion.

Campaign 3 Supplement 4.0 Acceptance Gate passed with verdict `accepted_for_campaign_3_final_consistency_gate`. It accepted Supplement 4.0 only and generated `artifacts/audits/campaign_3_4_0/run_manifest.json`, `campaign_3_supplement_4_0_acceptance_gate.json/.md`, `campaign_3_supplement_4_0_acceptance_matrix.json`, `status_boundary_matrix.json`, `validation_report.json`, and `checkpoint.json`. It did not start Campaign 1-3 Stage Test, Integrated Closure, Repository Cleanup, push, tag, CI, Campaign 4, Campaign 5, Full Gate, EXE, or Release.

Campaign 3 Final Consistency Gate remains the only next safe action in the current locked state. Historical downstream artifacts, if present in the workspace, are not counted as current-sequence acceptance. Do not run Campaign 1-3 Stage Test, Integrated Closure, Closure Pack, Repository Cleanup, push, tag, CI, Closure Checklist, Campaign 1-3 review handoff, Campaign 4, Campaign 5, Full Gate, EXE, or Release before Final Consistency passes in its own locked item.

## Product Output Surface and External Trend Alignment Gate

This governance guard is registered now but does not change the current next item.

| Control | Current state | Boundary |
| --- | --- | --- |
| Product output surfaces | `registered` | `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package` must remain distinct. |
| Document Outputs | `existing_core_capability` | Markdown, DOCX / Word, PDF, and PPTX / PowerPoint through `generate-documents`; not an audit-report side effect and not covered by Skill Outputs. |
| External trend queue | `reference_only_or_needs_verification` | andrej-karpathy-skills, Presenton, CodeGraph, Understand Anything, NVlabs/LongLive, claude-plugins-official, and pi-mono remain `not_integrated`. |
| Current sequence | `supplement_4_0_accepted_for_final_consistency_gate` | The next safe action is `Campaign 3 Final Consistency Gate only`; Stage Test and later gates remain blocked. |

The expanded Campaign 3 Final Consistency Gate verified this guard after Supplement 4.0 acceptance. It did not claim Presenton PPT runtime, LongLive video generation, CodeGraph / Understand Anything knowledge graph, Claude plugin runtime, or pi-mono runtime integration.

## Historical Section 5 Compatibility Markers

These markers preserve the locked next item recorded by earlier Section 5 integration-decision tests. They are historical evidence only and do not override the active current position above.

- Historical marker, Next Section 5 item: `5.13 mattpocock/skills`
- Historical marker, Next Section 5 item: `5.14 Sirchmunk`
- Historical marker, Next Section 5 item: `5.S1 GBrain`
- Historical marker, Next Section 5 item: `5.S2 Horizon`
- Historical marker, Next Section 5 item: `5.S3 Obsidian-compatible Vault`
- Historical marker, Next Section 5 item: `Campaign 3 Supplement 2.0 closure gate`
- Historical marker, Next Section 5 item: `Campaign 3 Final Consistency Gate only`
- Historical marker, Campaign 3 accepted: `false`
- Historical marker, Campaign 4 allowed: `false`
- Historical marker, Campaign 3 Final Consistency Gate passed: `false`
- Historical marker, Campaign 1-3 Stage Test Gate passed: `false`
- Historical marker, Campaign 1-3 Integrated Closure Gate passed: `false`
- Historical marker, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed: `false`

## Campaign 1-3 Integrated Closure Sequence

Authority:

- Detailed scope: `docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md`
- Activation prerequisite: Campaign 3 Supplement 4.0 acceptance and Campaign 3 Final Consistency Gate
- Campaign 4 prerequisite: Stage Test Gate passed, Integrated Closure Gate passed, Closure Pack generated, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed, repository push succeeded, tag created, CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate passed

Locked order:

1. Campaign 3 Supplement 3.0 completed
2. STOP
3. Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate
4. Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract
5. Campaign 3 Final Consistency Gate
6. STOP
7. Campaign 1-3 Stage Test Gate
8. Campaign 1-3 Integrated Closure Gate
9. Closure Pack generation
10. Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate
11. Repository push
12. Tag creation
13. CI green verification
14. Closure Checklist green verification
15. Campaign 1-3 Integrated Review and New Conversation Handoff Gate
16. Campaign 4 Goal-Oriented Product UI Workbench Entry Gate

Failure at any test, closure, pack, repository cleanup, push, tag, CI, Closure Checklist, or Campaign 1-3 Integrated Review / Handoff step must stop and write checkpoint plus `resume_prompt`. Campaign 4 remains blocked until the full chain is green.

## Strong Gate Sequence Lock

The same Entry Gate, Acceptance Gate, and Transition Gate mechanism applies after Campaign 3:

- Campaign 4 cannot become active while Campaign 3 is `in_progress`.
- Campaign 4 cannot become active from Campaign 3 2.0 or 3.0 completion alone; the Pre-4.0 Workspace Partition Foundation Gate, Campaign 3 Supplement 4.0, the Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag creation, CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate are also required.
- Campaign 1-3 Stage Test Gate cannot start immediately after Supplement 3.0; it waits for Supplement 4.0 and the Campaign 3 Final Consistency Gate.
- Campaign 4 is `Goal-Oriented Product UI Workbench`, not the old flat UI industrial page list.
- Campaign 5 cannot become active from UI action entries or status cards.
- Campaign 5 is `Chain-Level Local Core Bridge`, not raw Core action buttons exposed directly to users.
- TasteSkill and Product Design Plugin are Campaign 4.x enhancement backlog candidates only and must remain `planned_not_active` before CI/CL green.
- UI redesign and future Campaign Bridge allowlist changes are forbidden before CI/CL green.
- Campaign 6 is `Agent Runtime & Memory Platform` and cannot become active from Core Bridge allowlist presence, Agent Package files, runtime schema, memory spec, Redis config, or Vector DB config alone.
- Campaign 7 is `Configuration System` and cannot become active from Agent Runtime or memory specs alone.
- Campaign 8 is `Full Testing / Full Review` and cannot become active from configuration schema or settings files alone.
- Campaign 9 is `EXE Packaging` and cannot become active from focused tests, Fast Gate, scoped tests, or partial packaging smoke.
- Final Release cannot become active from a packaging script or local artifact alone.

`remaining_gap` and capability statuses in `GOAL_ACCEPTANCE_LEDGER.json` cannot override these transitions.

## Already Absorbed Sources

Do not redo these unless a Document Understanding or Knowledge Package compatibility test explicitly proves breakage:

- Anything2Skill
- SkillX
- Anthropic skill-creator
- P2.2 Skill Governance / Skill Suite main chain

These sources may be cited as already absorbed design or governance context. They are not current runtime integration targets.

## Completion Boundary

UI, Core Bridge, Agent Runtime/Memory, configuration, Full Testing / Full Review, and EXE work cannot be marked complete before their plan sections have direct evidence:

- UI requires full goal-oriented desktop workflow evidence, not only status cards, flat page coverage, or action wiring.
- Chain-level Local Core Bridge requires allowlisted task-flow execution, path validation, timeout, structured errors, audit logs, and no arbitrary shell execution.
- Agent Runtime & Memory requires actual Agent run execution, KB/Skill use, tool permission enforcement, run log, audit trace, output verification, fallback memory, and Agent/workspace memory isolation evidence.
- Configuration requires API/proxy, DB, Redis, vector DB, workspace path, Agent runtime config, Agent memory backend config, OpenCLI config, settings export/import, diagnostics, and disabled-LLM behavior.
- Full Testing / Full Review requires the full validation campaign, not Fast Gate or focused tests.
- EXE requires build, install, launch, first-run setup, dependency checker, diagnostics, and portable/installer evidence.

## Goal Drift Guard

- `final_target_not_downgraded = true`
- `remaining_gap` must not override plan sequence.
- `next_required_e2e_step` must be derived from this sequence lock and the acceptance matrix.
- `not_goal_complete = true` until the installed Windows product passes final acceptance.
