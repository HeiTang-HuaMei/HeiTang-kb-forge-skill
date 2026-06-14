# Target Acceptance Matrix

This matrix maps the user-uploaded 12-section target plan to current evidence status. It is a planning control surface, not runtime evidence.

## Status Legend

- `accepted`: campaign-level acceptance review passed and may be used for sequence movement.
- `partially_complete`: some evidence exists, but the section still has required unfinished work.
- `not_complete`: required evidence is absent.
- `not_allowed_yet`: the plan sequence blocks this work until earlier campaigns finish.
- `allowed_next_not_active`: the campaign may open next, but the current task has not started it.
- `absorbed_do_not_redo`: already absorbed work; do not reprocess unless compatibility evidence breaks.

## 12-Section Matrix

| Plan section | Status | Current evidence | Remaining sequence requirement |
| --- | --- | --- | --- |
| 1. 总目标验收标准 | `not_complete` | Component evidence exists, but installed desktop product acceptance is not proven. | Complete every later section, then prove install, UI, diagnostics, and EXE acceptance. |
| 2. 执行总规则 | `partially_complete` | Governance files, ledger, document output governance, Full Access rules, Plan Sequence Lock, and Campaign Stage Gate policy exist. | Continue enforcing stage gates, no push/tag/release before final acceptance. |
| 3. 第一战役：还需加强项目 | `accepted` | `artifacts/audits/backend_remediation_acceptance_review/backend_remediation_acceptance_matrix.json` verdict is `accepted`. | Preserve truthful backend boundaries; Surya remains benchmark/reference `needs_strengthening`, not a ready parser. |
| 4. 第二战役：批量导入与知识库构建 | `accepted` | `artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.json` verdict is `accepted`. | Preserve chain evidence; report export is one accepted stage, not a substitute for the whole campaign. |
| 5. 第三战役：未接入项目逐个处理 | `supplement_4_0_accepted_for_final_consistency_gate` | Campaign 3 mainline, strengthening records, Supplement 2.0, Supplement 3.0, Pre-4.0, Supplement 4.0, and Product Output Surface guard evidence exist. Campaign 3 Supplement 4.0 Acceptance Gate passed. | Continue only with Campaign 3 Final Consistency Gate; Stage Test, Integrated Closure, Closure Pack, Repository Cleanup, push, tag, CI, and Campaign 4-9 remain blocked. |
| 6. 第四战役：Goal-Oriented Product UI Workbench | `not_allowed_yet` | Replacement plan v3.0 registered in `CAMPAIGN_4_9_REPLACEMENT_PLAN.md`; no UI redesign or Campaign 4 execution has started, and Campaign 3 plus closure/repository-cleanup/push/tag/CI/review-handoff gates are incomplete. | Do not enter Campaign 4 until Campaign 3 complete, Stage Test Gate passed, Integrated Closure Gate passed, Closure Pack generated, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed, repository push succeeded, baseline tag created, CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate passed. |
| 7. 第五战役：Chain-Level Local Core Bridge | `not_allowed_yet` | Replacement plan v3.0 registered in `CAMPAIGN_4_9_REPLACEMENT_PLAN.md`; Bridge actions exist, but chain-level user task execution acceptance is not proven and Campaign 4 is not accepted. | Complete only after Campaign 4 Goal-Oriented Product UI Workbench acceptance; user tasks must map to allowlisted bridge flows without arbitrary shell execution. |
| 8. 第六战役：Agent Runtime & Memory Platform | `not_allowed_yet` | Agent Package evidence exists, but Agent runtime execution, memory fallback, memory isolation, and run audit acceptance are not proven. | Complete only after Campaign 5 Bridge acceptance; Agent Package, memory spec, Redis config, and Vector DB config are not runtime/memory acceptance. |
| 9. 第七战役：Configuration System | `not_allowed_yet` | Configuration remains status/evidence incomplete for full UI-to-runtime acceptance. | Complete API/proxy, DB, Redis, vector DB, workspace path, Agent runtime config, Agent memory backend config, OpenCLI config, diagnostics, and disabled-LLM behavior later in sequence. |
| 10. 第八战役：Full Testing / Full Review | `not_allowed_yet` | Focused tests and Fast Gate evidence exist. | Full Testing / Full Review waits until UI, Bridge, Agent Runtime/Memory, and configuration work are complete. |
| 11. 第九战役：EXE Packaging | `not_allowed_yet` | No current EXE build/install/launch/doctor acceptance. | Package only after product E2E and Full Testing / Full Review readiness. |
| Final Release | `not_allowed_yet` | No final release permission; v3.0 final release waits until Campaign 9 EXE Packaging acceptance. | No final commit, final push, release tag, GitHub Release, or final sync before full target acceptance. |
| 12. 禁止事项 | `partially_complete` | Governance rules forbid false readiness claims and reduced acceptance language. | Continue enforcing throughout every section. |

## Required Plan State Buckets

- 已证明完成: Section 3 / Campaign 1 backend strengthening acceptance review; Section 4 / Campaign 2 batch import and knowledge supply-chain acceptance review; Campaign 3 items 5.1 LLM Wiki v2 through 5.14 Sirchmunk plus strengthening records 5.S1 through 5.S3; Campaign 3 Supplement 2.0 closure gate; Supplement 3.0 Entry Gate; all Supplement 3.0 P0/P1 bounded industrial evidence; Campaign 3 Supplement 3.0 Acceptance Gate; Pre-4.0 Workspace Partition Foundation Gate; Campaign 3 Supplement 4.0 Entry Gate; 4.0B/4.0C/4.0D-I implementation evidence; Campaign 3 Supplement 4.0 Acceptance Gate.
- 部分完成: Section 2 execution governance; Section 12 forbidden-claim governance.
- 未完成: Section 1 final installed-product acceptance; Campaign 3 Final Consistency Gate; Campaign 1-3 Stage Test Gate; Campaign 1-3 Integrated Closure Gate; Closure Pack generation; Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate; repository push; campaign baseline tag; baseline CI green.
- 不得提前推进: Sections 6, 7, 8, 9, 10, and 11 until Section 5 and their prerequisites are complete or the user explicitly changes the plan order.
- 已吸收不得重做: Anything2Skill, SkillX, Anthropic skill-creator, and P2.2 Skill Governance / Skill Suite main chain unless DU/KB compatibility tests explicitly break.

## Campaign Acceptance Controls

The same Entry Gate, Acceptance Gate, and Transition Gate mechanism applies to Campaigns 1-9 and Final Release. Campaign 1/2 acceptance does not weaken later gates, and a local command, status card, schema, focused test, or packaging script cannot substitute for the target campaign acceptance evidence.

## Strong Gate Coverage

Strong gates apply to every later campaign, including Goal-Oriented Product UI Workbench, Chain-Level Local Core Bridge, Agent Runtime & Memory Platform, Configuration System, Full Testing / Full Review, EXE Packaging, and Final Release. Campaign 3 per-project evidence remains item evidence until all Section 5 items 5.1-5.14 have both integration decisions and UI impact notes, strengthening records 5.S1-5.S3 are decided or explicitly deferred, the Supplement 2.0 closure gate passes, the Supplement 3.0 Entry Gate plus Supplement 3.0 Acceptance Gate pass, the Pre-4.0 Workspace Partition Foundation Gate passes, Campaign 3 Supplement 4.0 is accepted, the expanded Campaign 3 final consistency gate passes, Campaign 1-3 Stage Test Gate passes, Campaign 1-3 Integrated Closure Gate passes, Closure Pack is generated, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passes, repository push succeeds, a campaign baseline RC tag is created, tag-related CI/CL is green, Closure Checklist is green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate passes.

## Product Output Surface Guard

The product output surface has four distinct categories:

| Output surface | Acceptance boundary |
| --- | --- |
| `knowledge_package` | Traceable KB package assets remain independent product outputs. |
| `document_outputs` | Markdown, DOCX / Word, PDF, and PPTX / PowerPoint through `generate-documents`; registered as `existing_core_capability`, not an audit-report side effect and not covered by Skill Outputs. |
| `skill_outputs` | Skill Template / Dedicated Skill outputs stay in Campaign 3 Supplement 4.0 and do not replace Document Outputs. |
| `agent_creation_package` | Agent Package output is distinct from Agent runtime readiness. |

Campaign 3 Final Consistency Gate must verify this guard after Supplement 4.0 acceptance. Presenton, CodeGraph, Understand Anything, NVlabs/LongLive, claude-plugins-official, and pi-mono remain future/reference entries only; no runtime dependency, npm install, GPU/runtime integration, or MCP/plugin execution is active.

| Later campaign | Acceptance cannot be replaced by | Required later acceptance evidence |
| --- | --- | --- |
| Campaign 4 Goal-Oriented Product UI Workbench | UI action entry, static preview, status card, asset sync, old page list, Campaign 3 Supplement 4.0 planning, Closure Pack existence, Repository Cleanup existence, push/tag existence, CI/CL green alone, TasteSkill, or Product Design Plugin | Full goal-oriented desktop UI workbench with product-line task cards, simplified navigation, page reconciliation, truthful state rendering, and no false executable claims after Campaign 1-3 closure chain passes |
| Campaign 5 Chain-Level Local Core Bridge | Allowlist presence, raw action mapping, UI buttons, or single action smoke | Real user-task bridge flow execution with path validation, timeout, structured error, audit log, recovery path, and no arbitrary shell execution |
| Campaign 6 Agent Runtime & Memory Platform | Agent Package, runtime schema, memory spec, Redis config, Vector DB config, or Bridge action candidates | Real Agent runtime with KB/Skill use, tool permission enforcement, run logs, audit trace, output verification, memory fallback, and Agent/workspace memory isolation |
| Campaign 7 Configuration System | Schema, config file, settings form, or optional provider field | Real API/proxy, DB, Redis, vector DB, workspace path, Agent runtime, Agent memory backend, and OpenCLI checks plus settings export/import and diagnostics |
| Campaign 8 Full Testing / Full Review | Focused tests, Fast Gate, scoped tests, packaging smoke, or a single green command | Full validation over Core, UI, Bridge, config, external source, Skill, Agent Package, Agent runtime, Agent memory, Multi-Agent, packaging smoke, Release Check, Full Review, and `git diff --check` |
| Campaign 9 EXE Packaging | Packaging script, build config, package directory, or Flutter build alone | Windows EXE, installer, portable package, first-run setup, install/run smoke, dependency checker, config wizard, Agent task smoke, output verification, guides, checksums, and release artifact manifest |
| Final Release | Any local campaign artifact by itself | Campaigns 1-9 accepted, final sync complete, then final commit/push/tag/release may be considered |

| Campaign | Gate status | Evidence |
| --- | --- | --- |
| Campaign 1 | `accepted` | `artifacts/audits/backend_remediation_acceptance_review/backend_remediation_acceptance_matrix.json` |
| Campaign 2 | `accepted` | `artifacts/audits/knowledge_supply_chain_acceptance_review/campaign_2_acceptance_matrix.json` |
| Campaign 3 | `supplement_4_0_accepted_for_final_consistency_gate` | `artifacts/audits/section_5/llm_wiki_v2_knowledge_lifecycle/run_manifest.json`; `artifacts/audits/section_5/weknora_auto_wiki/run_manifest.json`; `artifacts/audits/section_5/anysearchskill_provider_adapter/run_manifest.json`; `artifacts/audits/section_5/n8n_workflow_export/run_manifest.json`; `artifacts/audits/section_5/mmskills_multimodal_package/run_manifest.json`; `artifacts/audits/section_5/skill_prompt_generator_prompt_asset_library/run_manifest.json`; `artifacts/audits/section_5/ai_marketing_skills_pattern_library/run_manifest.json`; `artifacts/audits/section_5/ai_money_maker_handbook_business_scenario_library/run_manifest.json`; `artifacts/audits/section_5/jellyfish_content_asset_schema/run_manifest.json`; `artifacts/audits/section_5/story_flicks_video_pipeline_schema/run_manifest.json`; `artifacts/audits/section_5/seedance2_skill_template_metadata/run_manifest.json`; `artifacts/audits/section_5/rag_anything_cross_modal_rag_schema/run_manifest.json`; `artifacts/audits/section_5/mattpocock_skills_engineering_governance/run_manifest.json`; `artifacts/audits/section_5/sirchmunk_direct_file_search/run_manifest.json`; `artifacts/audits/section_5/gbrain_memory_profile_kg_strengthening/run_manifest.json`; `artifacts/audits/section_5/horizon_topic_intake_strengthening/run_manifest.json`; `artifacts/audits/section_5/obsidian_vault_strengthening/run_manifest.json`; `artifacts/audits/section_5/campaign_3_supplement_2_0_closure_gate/run_manifest.json`; `artifacts/audits/campaign_3_4_0/run_manifest.json` |
| Campaign 4 | `blocked_by_sequence` | Campaign 1-3 Stage Test Gate, Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag, and CI/CL green are incomplete |
| Campaign 5 | `blocked_by_sequence` | Campaign 4 Goal-Oriented Product UI Workbench not accepted |
| Campaign 6 | `blocked_by_sequence` | Campaign 5 Chain-Level Local Core Bridge not accepted |
| Campaign 7 | `blocked_by_sequence` | Campaign 6 Agent Runtime & Memory Platform not accepted |
| Campaign 8 | `blocked_by_sequence` | Campaign 7 Configuration System not accepted |
| Campaign 9 | `blocked_by_sequence` | Campaign 8 Full Testing / Full Review not accepted |
| Final Release | `blocked_by_sequence` | Campaigns 1-9 are not all accepted |

## Already Absorbed Do Not Redo

| Source | Status | Rule |
| --- | --- | --- |
| Anything2Skill | `absorbed_do_not_redo` | Do not redo unless DU/KB compatibility tests explicitly break. |
| SkillX | `absorbed_do_not_redo` | Do not redo unless DU/KB compatibility tests explicitly break. |
| Anthropic skill-creator | `absorbed_do_not_redo` | Do not redo unless DU/KB compatibility tests explicitly break. |
| P2.2 Skill Governance / Skill Suite | `absorbed_do_not_redo` | Do not redo unless DU/KB compatibility tests explicitly break. |

## Current Required Next Item

Campaign 3 Supplement 4.0 Acceptance Gate has passed after items 5.1 through 5.14 plus strengthening items 5.S1 GBrain, 5.S2 Horizon, and 5.S3 Obsidian-compatible Vault advanced, Campaign 3 Supplement 2.0 closed, Campaign 3 Supplement 3.0 passed Entry and Acceptance, the Pre-4.0 Workspace Partition Foundation Gate passed, and Campaign 3 Supplement 4.0 implementation evidence passed. These supplements do not change the 12-section total plan. The current required next item is:

```text
Campaign 3 Final Consistency Gate only
```

Campaign 3 acceptance is not proven in the current locked state until the dedicated Campaign 3 Final Consistency Gate passes in its own item. Do not infer Stage Test, Integrated Closure, Campaign 4, Campaign 5, Closure Pack, repository cleanup, push, tag, or CI from Supplement 4.0 Acceptance alone.

## Campaign 3 2.0 Dedup Supplement

Campaign 3 2.0 is an internal Section 5 supplement. It does not change the total plan and does not open Campaign 4 early.

| Item | Role | Acceptance note |
| --- | --- | --- |
| 5.7 ai-marketing-skills | Marketing Skill Pattern Library candidate | Advanced as a local original Marketing Skill Pattern Library; Horizon remains a later Topic Radar / Content Intake strengthening candidate, not a peer runtime. |
| 5.8 ai-money-maker-handbook | Business scenario template library candidate | Advanced as a local original Business Scenario Template Library; no external trading, payment, ad spend, crawler, account operation, revenue guarantee, financial advice, or money automation claim. |
| 5.9 Jellyfish | Content asset schema / storyboard metadata reference | Advanced as a local original Content Asset Schema reference; no short-drama workbench runtime, video generation runtime, asset rendering runtime, media operation, copied external content, or executable action. |
| 5.10 story-flicks | AIGC video pipeline schema / module slot | Advanced as a local original AIGC Video Pipeline Schema reference; no story-to-video runtime, image/audio/video generation runtime, voice cloning, media rendering, copied external content, provider execution, or executable action. |
| 5.11 seedance2-skill | Verified video Skill template metadata reference | Advanced as `reference_only`: public repository HEAD and MIT license verified; no external prompt/`SKILL.md`, provider adapter, API key, provider request, generated media, or executable action. Exact provider API/pricing contract remains unverified after official-document access timeout. |
| 5.12 RAG-Anything | Multimodal RAG schema / benchmark / cross-modal trace reference | Advanced as `reference_only`: official HEAD/release/MIT verified; local cross-modal schema, trace, and benchmark profile passed; no vendor runtime, model/provider execution, or replacement of the existing RAG main chain. |
| 5.13 mattpocock/skills | Engineering governance strengthening | Advanced as local engineering governance rule-pack evidence: repository HEAD and MIT license verified; local Pre-Code/Test/Review/AI collaboration rules generated and validated; no external Skill files, prompts, scripts, runtime, Agent creation, Agent binding, or executable workflow. |
| 5.14 Sirchmunk | Embedding-free direct file search / no-vector retrieval provider candidate | Advanced as bounded local direct-file-search evidence: source HEAD/tag/license verified; local workspace path-boundary, source trace, and evidence map validated; no vendor runtime, LLM/API key, network, embedding, vector DB, index build requirement, unsafe path access, or arbitrary shell execution. |
| 5.S1 GBrain | Strengthening for memory/profile/KG domains | Advanced as a local memory/profile/KG strengthening record: repository HEAD and MIT license verified; local memory-profile, KG-gap, and agent-memory boundary rules generated and validated; no GBrain runtime, Bun, database, pgvector, MCP, skillpack import, Agent binding, or external ingestion. |
| 5.S2 Horizon | Strengthening for marketing/topic intake domains | Advanced as a local Topic Intake Pipeline schema strengthening record: repository HEAD and MIT license verified; local source scoring, dedup, briefing candidate, and content intake boundary rules generated and validated; no Horizon runtime, crawler, scheduler, delivery channel, MCP, API key, external workflow, or Campaign 3.0 ingestion. |
| 5.S3 Obsidian-compatible Vault | Strengthening for local Markdown vault import/export | Advanced as local Markdown vault adapter evidence with frontmatter, wikilink/backlink, folder structure, and export validation; no Obsidian runtime, plugin, sync, database, network, Campaign 3.0 ingestion, or Campaign 4 UI acceptance. |

Historical compatibility marker: Section 5 strengthening item 5.S2 Horizon followed 5.S1 GBrain during its original locked run.

## Campaign 3 3.0 External Source Memory & Verification

Campaign 3 3.0 is an internal Section 5 supplement registered by explicit user instruction. It does not renumber the 12-section plan. Completed evidence now includes the External Link Import controlled entry and Authenticated Browser Connector Alpha. Execution continues through the explicit internal order with Video-to-Knowledge and Visual Evidence Understanding foundations.

| Control | Current state | Acceptance note |
| --- | --- | --- |
| Sequence | `accepted_stop_pre_4_0_next` | Supplement 3.0 Acceptance Gate passed; STOP before running the Pre-4.0 gate. |
| Framework | `passed_framework_only` | State taxonomy, chunk/source trace/evidence schemas, action registry, safety boundary, and progress/failure contracts exist; no runtime ingestion is claimed. |
| Generic Web URL Ingestion | `passed_generic_web_url_only` | Public HTTP/HTML links can become traceable text chunks with metadata, content hash, backlinks, source trace, and evidence map; platform links, OpenCLI, manual evidence, UI workflow, and Bridge execution are not accepted by this evidence. |
| Platform Link Preflight | `passed_platform_preflight_only` | Platform, readability state, failure reason, and next path are structured without fetching platform content; no OpenCLI, browser, manual evidence, video/OCR, UI, Bridge, or Supplement 3.0 acceptance is claimed. |
| OpenCLI verification | `passed_opencli_verification_only` | Public-source candidate discovery, source confidence, source trace, and evidence map passed through the project-local OpenCLI runtime; no manual evidence, browser, video/OCR, UI, Bridge, or Supplement 3.0 acceptance is claimed. |
| Manual Evidence Upload | `passed_manual_evidence_only` | Copied text and metadata-only user-supplied evidence now produce `manual_evidence_manifest.json`, `manual_evidence_blocks.jsonl`, `manual_source_trace.json`, `manual_evidence_map.json`, validation report, and report summary with secret blocking and no OCR/browser/OpenCLI/platform-fetch overclaims. |
| Unified Trace / Evidence / Progress / Failure Isolation | `passed_unified_trace_only` | Completed P0 inputs now aggregate into unified source trace, unified evidence map, progress events, and source-level failure isolation. Manual evidence remains manual evidence, OpenCLI remains verification evidence, and this does not claim Knowledge Verification Engine, Browser, Video/OCR, UI workflow, Bridge execution, Supplement 3.0 acceptance, or Campaign 4. |
| External Link Import controlled entry and allowlist safety | `passed_entry_bridge_allowlist_only` | `external_link_import_ui_entry_only=true`; `external_link_import_bridge_allowlist_only=true`; `campaign_4_active=false`; `campaign_5_active=false`; `ui_industrial_workbench_complete=false`; `local_core_bridge_complete=false`; `bridge_execution_accepted=false`; not Campaign 4 UI redesign and not Campaign 5 Bridge acceptance. |
| Authenticated Browser Connector | `passed_alpha_only` | User-authorized current-visible-content snapshot ingestion, consent lifecycle, expiry, pause/resume/revoke/clear, source trace, evidence map, progress, and secret/Cookie blocking passed. Browser automation and Cookie access remain false. |
| Video and Visual Evidence | `passed_foundations_only` | Subtitle transcript, timestamp trace, user-supplied image/keyframe OCR, layout blocks, multimodal chunks, image trace, visual evidence map, and ffmpeg/ffprobe structured skipped records passed. |
| Knowledge Verification Engine | `passed_foundations_only` | Claim verification, correctness, answer grounding, dashboard foundation, source trace, evidence map, and progress events passed without LLM/network. Its evidence contributes to, but does not alone substitute for, Supplement 3.0 acceptance. |
| Supplement 3.0 Acceptance Gate | `passed` | Ten evidence bundles, nine capability checks, 73 focused Core/regression tests, 16 Flutter tests, and Flutter analysis passed. Verdict: `accepted_for_pre_4_0_workspace_partition_foundation_gate`. |
| UI impact | `entry_only_passed` | The External Link Import entry shows truthful status/progress/trace/evidence/backlink/failure/repair data under the existing import page. Industrial UI workbench acceptance remains false. |
| Core Bridge impact | `allowlist_only_passed` | Completed-P0 commands are allowlisted with no-shell, URL, timeout, and path-boundary tests. Local Core Bridge completion and Bridge execution acceptance remain false. |

Detailed authority: `docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md`.

## Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate

The Pre-4.0 gate is an internal Section 5 foundation gate registered by explicit user instruction. It must run only after Campaign 3 Supplement 3.0 Acceptance Gate passes and before Campaign 3 Supplement 4.0 starts.

| Control | Current state | Acceptance note |
| --- | --- | --- |
| Sequence | `passed_foundation_contract` | Supplement 3.0 acceptance passed first; this gate then passed as a foundation contract before Supplement 4.0. |
| Workspace manifest and registries | `passed_contract_ready` | Workspace-owned registries for sources, KBs, Skills, Agents, workflows, runs, reports, audits, exports, memory, and settings are defined without moving legacy artifacts. |
| Knowledge Base partition and access scope | `passed_contract_ready` | `kb_type`, `access_scope`, explicit reference/clone/import/share, and cross-workspace audit behavior are defined. |
| Path boundary | `passed_contract_ready` | Path escape, open-any-path, repo-root/system/home outputs, and implicit cross-workspace reads are rejected by the contract and focused tests. |
| Legacy default workspace | `passed_contract_ready` | Historical artifacts are registered through `legacy_default_workspace` compatibility without deleting, moving, or renaming them. |
| UI handoff | `passed_handoff_contract_only` | Future Campaign 4 may consume the contract, but this gate is not Campaign 4 UI. |
| Bridge handoff | `passed_handoff_contract_only` | Future Campaign 5 may consume the contract, but this gate is not Bridge completion and does not add current allowlist actions. |
| Acceptance Gate | `passed` | `pre_4_0_workspace_partition_complete=true` after focused tests, reports, validation, RUN_STATE, checkpoint, and manifests passed. |

Detailed authority: `docs/governance/PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md`.

## Campaign 3 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract

Campaign 3 4.0 is an internal Section 5 supplement registered by explicit user instruction and replaced by the later user-approved handoff-contract plan. It does not renumber the 12-section plan, does not replace P2.2 Skill Governance / Skill Suite, and is active only inside the locked Supplement 4.0 sequence.

| Control | Current state | Acceptance note |
| --- | --- | --- |
| Sequence | `accepted_for_campaign_3_final_consistency_gate` | 4.0A Entry Reconciliation Gate, 4.0B Verified Knowledge-to-Skill Template, 4.0C Skill Import & Dedicated Skill Composer, 4.0D-I Product Handoff Contract Bundle, and Supplement 4.0 Acceptance Gate passed; only Campaign 3 Final Consistency Gate may start next. |
| 4.0A Entry Reconciliation Gate | `passed_entry_gate_only` | Read 3.0 verification outputs, KB artifacts, existing Skill/Agent Package/agent_compat/generate-agent evidence, and recorded agent runtime/workbench/memory/multi-agent runtime as false. |
| Verified Knowledge-to-Skill | `passed_4_0b_only` | Source-traced Skill Template draft consumed verified KB/evidence reports, supports all seven Skill types, keeps video as one subtype only, and remains draft/not published. |
| Skill import and composer | `passed_4_0c_only` | Generated a source-bound Dedicated Skill draft package, distinguished generated/imported/composed/reference-only/planned Skills, preserved Document Outputs as existing Core capability, blocked unresolved conflicts, and did not publish Skill or generate Agent Package. |
| Skill-to-Agent Package | `passed_4_0d_only` | Reused existing Agent Package capability and generated KB + Skill bound package evidence without claiming Agent runtime. |
| Workspace binding spec | `passed_4_0e_only` | Defines Agent workspace partition and audit scope; spec is not runtime enforcement. |
| Memory isolation spec | `passed_4_0f_only` | Redis/vector are candidates/fallbacks only; memory policy is not runtime isolation. |
| Single/Multi-Agent mode spec | `passed_4_0g_only` | Multi-Agent Workflow Spec is spec_ready only, not runtime ready or executable. |
| Campaign 4 UI handoff | `passed_4_0h_only` | Handoff contract and task-card inputs exist; handoff is not Campaign 4 UI completion. |
| Campaign 5 Bridge handoff | `passed_4_0i_only` | Future allowlist candidates and missing-action matrix exist; handoff is not Campaign 5 Bridge completion. |
| Acceptance Gate | `passed` | Verified full product handoff, status boundary matrix, forbidden-overclaim tests, Campaigns 4-9 inactive, Agent runtime not ready, and Redis/vector Agent memory runtime not ready. Verdict: `accepted_for_campaign_3_final_consistency_gate`. |

Detailed authority: `docs/governance/CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md`.

## Campaign 1-3 Integrated Closure Chain

This chain starts only after the Pre-4.0 Workspace Partition Foundation Gate, Campaign 3 Supplement 4.0 acceptance, and the Campaign 3 Final Consistency Gate. It does not replace Pre-4.0 or Supplement 4.0 and does not open Campaign 4 by itself.

| Control | Current state | Acceptance note |
| --- | --- | --- |
| Campaign 3 Final Consistency Gate | `next_required` | The only next safe action after Campaign 3 Supplement 4.0 Acceptance Gate. |
| Campaign 1-3 Stage Test Gate | `blocked_by_sequence` | Must wait for Campaign 3 Final Consistency Gate to pass. |
| Campaign 1-3 Integrated Closure Gate | `blocked_by_sequence` | Must wait for Campaign 1-3 Stage Test Gate to pass. |
| Closure Pack | `not_generated` | May be generated only after Integrated Closure Gate passes. |
| Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate | `not_started` | May run only after Closure Pack generation and must inventory before cleanup. |
| Repository push | `not_started` | May run only after repository cleanup and push safety checks pass. |
| Closure tag | `not_created` | May be created only after repository push succeeds. |
| CI verification | `not_checked` | Campaign 4 Entry Gate waits for tag-related CI green after push and tag. |
| Campaign 1-3 Integrated Review and New Conversation Handoff Gate | `not_started` | May generate the three Campaign 1-3 review reports, `new_conversation_handoff_prompt.md`, and `campaign_1_2_3_handoff_manifest.json` only after Stage Test, Integrated Closure, Closure Pack, Repository Cleanup, push, tag, CI Green, and Closure Checklist Green pass. |

Detailed authority: `docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md`.

## Campaign 4-9 Replacement Boundary

The old future Campaign 4/5-only definitions are superseded by `docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md`. The older `docs/governance/CAMPAIGN_4_5_REPLACEMENT_PLAN.md` remains only as a compatibility pointer.

| Campaign | Replacement definition | Current state | Boundary |
| --- | --- | --- | --- |
| Campaign 4 | Goal-Oriented Product UI Workbench | `not_allowed_yet` | Must wait for Campaign 3 complete, Campaign 1-3 Stage Test Gate, Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, baseline tag, CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate. |
| Campaign 5 | Chain-Level Local Core Bridge | `not_allowed_yet` | Must wait for Campaign 4 acceptance and must execute user-task flows through allowlisted bridge actions, not raw Core buttons. |
| Campaign 6 | Agent Runtime & Memory Platform | `not_allowed_yet` | Must wait for Campaign 5 acceptance; Agent Package, memory spec, Redis config, and Vector DB config are not runtime/memory acceptance. |
| Campaign 7 | Configuration System | `not_allowed_yet` | Must wait for Campaign 6 acceptance and must cover API/proxy, DB, Redis, vector DB, workspace path, Agent runtime, Agent memory backend, and OpenCLI diagnostics. |
| Campaign 8 | Full Testing / Full Review | `not_allowed_yet` | Must wait for Campaign 7 acceptance; focused tests and Fast Gate do not count as Full Testing / Full Review. |
| Campaign 9 | EXE Packaging | `not_allowed_yet` | Must wait for Campaign 8 acceptance; packaging script or build directory does not count as installer/portable install-run acceptance. |

Before CI/CL green, Closure Checklist green, and Campaign 1-3 Integrated Review and New Conversation Handoff Gate, the following remain forbidden: Campaigns 4-9, Final Release, TasteSkill, Product Design Plugin, UI redesign, and future Campaign Bridge allowlist changes.

Campaign 4 must be goal-oriented with no more than seven top-level navigation entries. It must not flatten every technical module into the main navigation, and it must not expose every Core action as a UI button.

Campaign 5 must keep Skill, Agent, and Multi-Agent runtime actions that are missing from the current allowlist as `display_only`, `planned_not_active`, `bridge_action_missing`, or `future_allowlist_candidate`, never `executable`. Campaign 6 is the first future campaign allowed to prove Agent Runtime and Memory Platform acceptance.

## Non-Completion Guard

- UI is not complete.
- Campaign 3 Supplement 3.0 Entry Gate, bounded P0/P1 evidence, and Acceptance Gate have passed.
- Pre-4.0 Workspace Partition Foundation Gate has passed as a foundation contract only.
- Campaign 3 Supplement 4.0 Entry Reconciliation Gate, 4.0B/4.0C/4.0D-I implementation evidence, and Supplement 4.0 Acceptance Gate have passed.
- Campaign 3 Final Consistency Gate is the only next safe action and has not passed in the current locked state.
- Campaign 1-3 Stage Test Gate is blocked until Campaign 3 Final Consistency Gate passes.
- Campaign 1-3 Integrated Closure Gate is not active or passed.
- Closure Pack is not generated, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate has not run, and repository push has not succeeded.
- Closure tag is not created.
- Closure CI is not green.
- Core Bridge is not complete.
- Agent Runtime & Memory Platform is not complete.
- API/proxy configuration is not complete.
- DB/Redis/vector DB configuration is not complete.
- Full Testing / Full Review is not complete.
- EXE packaging is not complete.
- Final release is not allowed.
