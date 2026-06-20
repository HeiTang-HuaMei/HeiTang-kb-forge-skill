# RC10 Hot Swappable Project Config Industrialization Report

Date: 2026-06-20

Baseline:

- `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
- `docs/product/PRD_V3_2026-06-19.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`

Product chain:

`文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A`

## Scope

This Stage 3 slice industrializes configuration profiles and providerized capability state for the desktop runtime. It does not add OKF runtime, does not expose external project loading as a product module, does not create a stable tag, and does not create a GitHub Release.

Normal users see configurable capability status in Settings and downstream pages. They do not see the engineering concept of hot-swappable project loading.

## Implemented Configuration Types

Runtime configuration assets are written to:

- `config/project_config_profiles.json`
- `config/project_config_assets.json`
- `config/project_config_runtime_status.json`
- `config/registered_provider_integration_matrix.json`
- `config/registered_provider_activation_log.jsonl`
- `config/registered_provider_selection_log.jsonl`
- `config/registered_provider_rollback_manifest.json`
- `config/registered_provider_health_report.json`
- `config/registered_provider_health_log.jsonl`
- `config/registered_provider_hot_swap_stability_report.json`
- `config/provider_capability_binding_manifest.json`
- `config/provider_capability_selection_state.json`
- `config/provider_adapter_contracts.json`
- `config/provider_adapter_readiness_report.json`
- `config/provider_adapter_readiness_log.jsonl`
- `config/config_test_log.jsonl`
- `config/profile_change_log.jsonl`
- `config/profile_activation_log.jsonl`

`project_config_assets.json` covers:

| Type | Status |
| --- | --- |
| Storage Path | Persisted with local path, hybrid policy, write test, disk-space check, permission error field |
| LLM Provider | Provider type, endpoint reference, model, API key ref, timeout, enabled flag, test result, masked secret |
| Model Gateway / API Relay | Gateway pool, direct provider pool, ModelRoute pool, route binding matrix, fallback, usage/cost policy, masked key refs |
| Embedding Provider | Provider type, model, dimension, endpoint, API key ref, test vector status, dimension mismatch flag |
| Search Provider | Provider type, endpoint, API key ref, network authorization, external verification flag, query test status |
| OCR Provider | Provider type, enabled flag, language, test availability, unavailable reason |
| PDF Parser Provider | Builtin/provider type, enabled flag, test parse status, fallback policy |
| Exporter Provider | Markdown, DOCX, PDF, PPTX, JSON, CSV, Skill package, Agent config, A2A report with per-format availability |
| Redis | Host, port, username, password ref, db, namespace, TLS, timeout, ping/auth/write-read-delete status |
| Vector DB | Provider type, endpoint, API key ref, collection, embedding config id, dimension, health, collection, vector test |
| Network Authorization | Web import, external verification, allowlist, timeout, retry, disabled reason |
| Agent Memory / Tool Policy | Simple/complex Agent memory and tool access policy, unauthorized resource guard |

## Model Gateway / ModelRoute Scope

The large-model configuration object is `模型网关与大模型接入配置能力补全计划`, not an Agent-only plan.

Implemented runtime evidence:

- `config/model_gateway/model_gateway_config.json`
- `config/model_gateway/model_gateway_test_report.json`
- `config/model_gateway/model_gateway_usage_report.json`
- `config/model_gateway/model_gateway_fallback_report.json`
- `config/model_gateway/model_gateway_reference_registry.json`
- `config/model_gateway/model_route_pool.json`
- `config/model_gateway/model_route_binding_matrix.json`
- `config/model_gateway/model_usage_cost_policy.json`
- `config/model_gateway/model_gateway_audit.jsonl`
- `config/model_gateway/model_route_audit.jsonl`

Runtime boundary:

- Gateway is the Provider Gateway / API Relay layer, not an Agent runtime.
- Provider is the upstream model service or OpenAI-compatible relay target.
- ModelRoute is the business-facing route consumed by document pipeline, OKF, document generation, Skill Factory, Agent Workbench, A2A, Tool reasoning, and embedding.
- Embedding route is separated from chat routes.
- API keys are stored only as refs or masked previews; test/audit artifacts do not write plaintext secrets.

Stage 2 runtime binding proof:

- Skill generation, external Skill analysis/localization, Skill validation, Skill runtime manifest, and Skill factory audit now write `model_route_binding` / `model_route_evidence`.
- Agent generation, single-Agent dialogue, dialogue export, Agent run history, A2A conflict/consensus/session artifacts, and orchestration records now write `model_route_binding` / `model_route_evidence`.
- This makes the LLM/Gateway layer auditable across KB-to-Skill, Skill-to-Agent, and A2A paths without exposing gateway mechanics as normal product pages.

## Registered Provider Integration

The registered but previously unloaded projects are now represented as Provider capability enhancement entries, not as standalone user-facing modules.

Runtime evidence:

- `registered_provider_integration_matrix.json`
- `registered_provider_activation_log.jsonl`
- `registered_provider_selection_log.jsonl`
- `registered_provider_rollback_manifest.json`
- `registered_provider_health_report.json`
- `registered_provider_health_log.jsonl`
- `registered_provider_hot_swap_stability_report.json`
- `provider_capability_binding_manifest.json`
- `provider_capability_selection_state.json`
- `provider_adapter_contracts.json`
- `provider_adapter_readiness_report.json`
- `provider_adapter_readiness_log.jsonl`

Coverage:

- 26 unique registered provider references
- 29 provider-to-capability mappings
- 8 product capability areas
- 0 entries marked runtime-loaded by default
- 0 entries marked ready for user selection without config/test evidence
- 1 local retrieval adapter can become selectable after real KB chunks are present
- 2 local RAG evaluation adapters can become selectable after retrieval validation, citation, conflict, and review evidence exists
- 1 local governance rule-pack adapter can become selectable from repository-owned governance/test assets
- 1 local Agent memory lifecycle adapter can become selectable after Agent and memory-index evidence exists
- 1 local teaching/reasoning Skill template adapter can become selectable from Skill Factory runtime evidence
- 1 local marketing Skill pattern adapter can become selectable from repository-owned template/demo assets
- 1 local Skill schema/package adapter can become selectable after Skill package, validation, fusion, version, and Agent binding evidence exists
- 1 local workflow collaboration export adapter can become selectable after A2A multi-round, conflict, consensus, runtime-audit, and collaboration-report evidence exists

Capability areas:

| Product capability | User entry | Provider mappings |
| --- | --- | --- |
| Parser / OCR | 文档库：解析 / OCR | 7 |
| Embedding / Vector DB | 知识库：Embedding / 向量库 | 3 |
| Search / Retrieval | 检索验证：检索 / 召回 | 5 |
| Exporter | 文档生成：导出器 | 3 |
| Skill templates / localization | Skill 工厂：模板 / 本地化 | 6 |
| Agent model / tools / memory | Agent 工作台：模型 / 工具 / 记忆 | 2 |
| Workflow / A2A export | Agent 工作台：A2A / 工作流导出 | 1 |
| Governance / audit | 审计中心：评测 / 治理 | 3 |

The Settings UI shows aggregate enhancement counts and capability status. It does not expose registered project names in normal business pages.

Provider enhancement operations:

- Test enhancement attempts activation for one registered Provider enhancement.
- If dependency, network, secret, runtime, or verification conditions are missing, activation is denied and audited.
- Rollback enhancement writes a rollback event to the local fallback Provider.
- Selection logs keep `runtime_loaded_after_event=false` unless the Provider has already been proven ready.

Health and stability validation:

- `testAllRegisteredProviderCapabilities()` checks all registered Provider mappings before they can be selected.
- Current evidence covers 29 provider-to-capability mappings and 26 unique registered Provider references.
- Every entry writes a user-readable health state such as `需安装外部服务`, `需启动外部服务`, `配置缺失`, `已禁用`, or `已配置未测试`.
- No unverified entry is marked runtime-loaded or selectable.
- `registered_provider_hot_swap_stability_report.json` records failure isolation, local fallback availability, rollback coverage, and downstream binding behavior.
- Downstream binding checks cover Document Library, Knowledge Base, Retrieval Verification, Document Generation, Skill Factory, Agent Workbench, and Audit Center.

Runtime binding:

- `provider_capability_binding_manifest.json` is the active Provider binding authority for product capabilities.
- It records each capability's current active Provider kind, fallback Provider, user-readable status, blocked reason, affected modules, and unauthorized resource guard.
- Current evidence keeps unverified capabilities on local fallback. `sirchmunk` can become the active `retrieval_provider` binding only after a real `kb/chunks.jsonl` probe succeeds.
- Blocked activation and rollback both refresh this binding manifest and keep `selected_provider_runtime_loaded=false`.
- `project_config_runtime_status.json` includes the binding manifest path and downstream module binding summaries for Document Library, Knowledge Base, Retrieval Verification, Document Generation, Skill Factory, and Agent Workbench.
- `provider_capability_selection_state.json` persists explicit capability-to-Provider selection. Runtime refresh and EXE restart keep the explicit selection applied while readiness remains proven.
- Rollback removes the explicit selection and suppresses automatic selection of another ready Provider for that same capability, returning the product capability to local fallback until the user explicitly enables a Provider again.
- Binding rows record `explicit_selected_provider_ref`, `explicit_selection_applied`, `explicit_selection_stale`, and `rollback_suppressed` so hot-swap state is auditable.

Adapter contracts:

- `provider_adapter_contracts.json` turns the 26 unique registered Provider references into explicit adapter contracts.
- Each contract records adapter type, capability IDs, affected modules, runtime execution mode, required config refs, health check actions, activation prerequisites, fallback Provider, rollback support, and masking policy.
- The contracts cover all 29 provider-to-capability mappings while keeping `runtime_loaded_count=0`. Readiness remains blocked unless a real readiness check passes.
- `registered_provider_health_report.json` and `project_config_runtime_status.json` both reference the adapter contract path.

Local retrieval adapter proof:

- `sirchmunk` has a bounded direct-file-search probe at `config/provider_adapter_probe_sirchmunk.json`.
- The probe reads only workspace-owned `kb/chunks.jsonl` and requires at least one chunk with real text or content.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks `sirchmunk` as `连接成功` and `ready_for_user_selection=true`.
- `provider_capability_binding_manifest.json` then binds `retrieval_provider` to `sirchmunk` with `selection_allowed=true`.
- `runtime_loaded` remains `false`; this is a verified local adapter readiness path, not arbitrary external project execution.
- The probe records `network_used=false`, `secret_plaintext_written=false`, and `normal_ui_project_name_visible=false`.

Local RAG evaluation adapter proof:

- `ragas` and `deepeval` have workspace-owned RAG evaluation probes at `config/provider_adapter_probe_ragas.json` and `config/provider_adapter_probe_deepeval.json`.
- The probes require real retrieval validation evidence: `query/multi_kb_query_result.json`, retrieval plan, rerank report, citation coverage report, conflict report, external validation boundary, validation report, validation history, and validation markdown.
- Passing readiness requires nonempty retrieval results, selected KB evidence, rerank count consistency, citation coverage, conflict schema evidence, reviewed validation status, validation history, and `external_calls_made=false`.
- When a probe succeeds, `provider_adapter_readiness_report.json` marks that Provider as `连接成功` and `ready_for_user_selection=true`; explicit activation can bind `retrieval_provider` to `ragas` or `deepeval`.
- `runtime_loaded` remains `false`; no RAGAS or DeepEval package, evaluator runtime, network call, or vendor code is bundled or executed.
- The probes record `network_used=false`, `secret_plaintext_written=false`, `external_runtime_executed=false`, `vendor_runtime_loaded=false`, and `normal_ui_project_name_visible=false`.

Local governance adapter proof:

- `mattpocock_skills` has a repository-owned governance rule-pack probe at `config/provider_adapter_probe_mattpocock_skills.json`.
- The probe checks only local HeiTang governance/test assets: `quality_gate/rules.py`, `test_governance/gates.py`, `provider_security/audit.py`, and `tests/test_test_governance_manifest.py`.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks `mattpocock_skills` as `连接成功` and `ready_for_user_selection=true`.
- Because the Provider asset maps this Provider to both Skill template governance and governance/audit, the binding manifest can select it for `skill_template_provider` and `governance_audit_provider`.
- `runtime_loaded` remains `false`; no third-party repository code, prompts, scripts, Agent binding, or external workflow is bundled or executed.
- The probe records `network_used=false`, `secret_plaintext_written=false`, `external_runtime_executed=false`, and `normal_ui_project_name_visible=false`.

Local Agent memory adapter proof:

- `llm_wiki_v2` has a workspace-owned Agent memory lifecycle probe at `config/provider_adapter_probe_llm_wiki_v2.json`.
- The probe requires `agent/agent_generation_manifest.json`, `agent/audit/permission_audit.json`, `agent/audit/agent_validation_report.json`, and `kb/memory_index_reference.json`.
- Before those artifacts exist, readiness remains `已配置未测试` and activation is blocked.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks `llm_wiki_v2` as `连接成功` and `ready_for_user_selection=true`.
- `provider_capability_binding_manifest.json` can then bind `agent_model_tools_memory` to `llm_wiki_v2` for Agent Workbench memory/tool capability status.
- `runtime_loaded` remains `false`; no LLM Wiki vendor runtime, external code, network call, or arbitrary execution is bundled or executed.
- The probe records `network_used=false`, `secret_plaintext_written=false`, `external_runtime_executed=false`, `vendor_runtime_loaded=false`, and `normal_ui_project_name_visible=false`.

Local marketing Skill adapter proof:

- `ai_marketing_skills` has a repository-owned marketing Skill pattern probe at `config/provider_adapter_probe_ai_marketing_skills.json`.
- The probe checks local template/demo evidence: `p1_core_contract_fixture.json`, `agent/templates.py`, `skill_templates/catalog.py`, and `examples/demo_shopping_guide_agent/output_sample/manifest.json`.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks `ai_marketing_skills` as `连接成功` and `ready_for_user_selection=true`.
- The Provider remains a Skill Factory/template capability enhancement. It does not create a new page and does not replace the existing Skill Factory chain.
- `runtime_loaded` remains `false`; no ai-marketing-skills repository code, prompts, scripts, crawler, paid-media operation, account operation, network call, or external runtime is bundled or executed.
- The probe records `network_used=false`, `secret_plaintext_written=false`, `external_runtime_executed=false`, `vendor_runtime_loaded=false`, and `normal_ui_project_name_visible=false`.

Local teaching/reasoning Skill adapter proof:

- `andrej_karpathy_skills` has a workspace-owned teaching/reasoning Skill probe at `config/provider_adapter_probe_andrej_karpathy_skills.json`.
- The probe requires real Skill Factory runtime evidence: `skill_generation_manifest.json`, primary `SKILL.md`, `skill_config.json`, `skill_validation_report.json`, `skill_runtime_manifest.json`, version snapshots, and `skill_version_diff_report.json`.
- Passing readiness requires a KB-generated teaching/reasoning Skill, validation pass, selected generation config, multi-version runtime, version diff, version snapshots, and ModelRoute evidence.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks `andrej_karpathy_skills` as `连接成功` and `ready_for_user_selection=true`, and `provider_capability_binding_manifest.json` can bind `skill_template_provider` to it after explicit activation.
- `runtime_loaded` remains `false`; no external Andrej Karpathy Skill repository, course asset, script, network call, arbitrary execution, or vendor runtime is bundled or executed.
- The probe records `network_used=false`, `secret_plaintext_written=false`, `external_runtime_executed=false`, `vendor_runtime_loaded=false`, and `normal_ui_project_name_visible=false`.

Local Skill Prompt Generator adapter proof:

- `skill_prompt_generator` has a workspace-owned Skill prompt/template probe at `config/provider_adapter_probe_skill_prompt_generator.json`.
- The probe requires real Skill Factory runtime evidence: `skill_generation_manifest.json`, primary `SKILL.md`, `skill_config.json`, `skill_validation_report.json`, localized Skill manifest and diff, fused Skill output, `skill_runtime_manifest.json`, version snapshots, and `skill_version_diff_report.json`.
- Passing readiness requires from-KB generation, external Skill fusion/localization, validation pass, secondary fusion, multi-version runtime, version snapshots, and ModelRoute evidence.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks `skill_prompt_generator` as `连接成功` and `ready_for_user_selection=true`, and `provider_capability_binding_manifest.json` can bind `skill_template_provider` to it after explicit activation.
- `runtime_loaded` remains `false`; no external prompt-generator repository code, network call, arbitrary execution, or vendor runtime is bundled or executed.
- The probe records `network_used=false`, `secret_plaintext_written=false`, `external_runtime_executed=false`, `vendor_runtime_loaded=false`, and `normal_ui_project_name_visible=false`.

Local MMSkills schema/package adapter proof:

- `mmskills` has a workspace-owned Skill schema/package probe at `config/provider_adapter_probe_mmskills.json`.
- The probe requires real Skill Factory evidence: `skill_package_manifest.json`, `skill_validation_report.json`, primary KB Skill config, localized Skill manifest, fused Skill manifest, `skill_runtime_manifest.json`, version snapshots, and `agent_binding_manifest.json`.
- Passing readiness requires a ready package manifest, validation pass, KB-generated primary Skill, external Skill fusion/localization, Skill+KB fusion, secondary fusion runtime, multi-version runtime, ModelRoute evidence, and Agent binding evidence.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks `mmskills` as `连接成功` and `ready_for_user_selection=true`, and `provider_capability_binding_manifest.json` can bind `skill_template_provider` to it after explicit activation.
- `runtime_loaded` remains `false`; this is a schema/package capability readiness proof, not external MMSkills runtime loading.
- The probe records `network_used=false`, `secret_plaintext_written=false`, `external_runtime_executed=false`, `vendor_runtime_loaded=false`, and `normal_ui_project_name_visible=false`.

Local Parser / OCR adapter proof:

- Parser/OCR Provider refs now write bounded probes at `config/provider_adapter_probe_<provider_ref>.json`.
- Parser-style refs such as `docling`, `unstructured`, `opendataloader`, `mineru`, and `marker` require real DU artifacts: `du/document_understanding_manifest.json`, `du/document_understanding_records.jsonl`, `du/normalized_sources/*.md`, and `source_manifest.json`.
- OCR-style refs such as `paddleocr` and `surya` additionally require image/OCR input evidence from `source_manifest.json`, for example `image_count > 0` or an image extension.
- Passing probes mark the Provider as `连接成功` and `ready_for_user_selection=true`, while keeping `runtime_loaded=false`.
- Missing DU artifacts or missing OCR input evidence keep the Provider at `已配置未测试` with Chinese blocked reasons.
- No external parser/OCR runtime is executed, no dependency is silently installed, and normal UI still exposes only the Parser/OCR capability status.

Local Embedding / Vector adapter proof:

- Embedding/Vector Provider refs now write bounded probes at `config/provider_adapter_probe_<provider_ref>.json`.
- `rag_anything` and `weknora` require real local KB index evidence: `kb/chunks.jsonl`, `kb/index_profile.json`, `kb/vector_index_reference.json`, `kb/index_build_report.json`, and `kb/index_metadata.json`.
- The probe requires PRD v3 schema versions, consistent chunk counts across chunks/vector/build/metadata, `vector_index_enabled=true`, and a nonempty vector-store reference.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks the Provider as `连接成功` and `ready_for_user_selection=true`, and `provider_capability_binding_manifest.json` can bind `knowledge_embedding_vector` to the selected Provider.
- `llamaindex` remains benchmark/config gated and is not selectable from local KB artifacts alone.
- `runtime_loaded` remains `false`; no external embedding/vector runtime, vendor code, network call, vector service mutation, or arbitrary execution is bundled or executed.
- The probe records `network_used=false`, `secret_plaintext_written=false`, `external_runtime_executed=false`, `vendor_runtime_loaded=false`, and `normal_ui_project_name_visible=false`.

Local Exporter adapter proof:

- `jellyfish` has a workspace-owned content asset export probe at `config/provider_adapter_probe_jellyfish.json`.
- The probe requires real structured export artifacts: `export/structured/knowledge_export.json`, `export/structured/knowledge_export.csv`, and `export/structured/structured_export_manifest.json`.
- When those artifacts exist and contain retrieval result evidence, `provider_adapter_readiness_report.json` marks `jellyfish` as `连接成功` and `ready_for_user_selection=true`.
- `story_flicks` has a workspace-owned video workflow handoff probe at `config/provider_adapter_probe_story_flicks.json`.
- The probe requires the video task boundary artifacts under `agent/artifacts/video/`, plus `agent/tool/tool_call_log.jsonl` and the external video Skill dependency report.
- The `story_flicks` probe explicitly requires `fake_video_generated=false` and `api_called=false`; it validates an export/handoff boundary, not real video generation.
- Both Provider refs remain Document Exporter capability enhancements. They do not create new pages, do not execute external runtimes, do not call network APIs, and keep `runtime_loaded=false`.

Local Workflow / A2A export adapter proof:

- `n8n` has a workspace-owned workflow collaboration export probe at `config/provider_adapter_probe_n8n.json`.
- The probe requires real A2A workflow artifacts: `agent/workspaces/W_M/a2a_sessions/A2A_001/a2a_session_manifest.json`, `a2a_rounds.jsonl`, `a2a_runtime_audit.jsonl`, `multi_agent/a2a_conflict_report.json`, `multi_agent/a2a_consensus_report.json`, `multi_agent/multi_agent_discussion_manifest.json`, and the collaboration report markdown.
- The probe requires multi-round evidence, runtime-audit records for each round, conflict and consensus reports, and export-ready collaboration output before the Provider can be selected.
- Passing the probe marks `workflow_collaboration_export` as `连接成功` and selectable while keeping `runtime_loaded=false`.
- `n8n` is intentionally excluded from `document_exporter`; document export binds to document/content export Providers such as `jellyfish` or `story_flicks`.
- This validates a local workflow export boundary only. It does not bundle n8n, call n8n, expose n8n as a normal product module, or execute any external workflow runtime.

Adapter readiness:

- `provider_adapter_readiness_report.json` evaluates the 26 adapter contracts against the active Profile and current workspace configuration.
- It records missing config refs, blocked reasons, Chinese error messages, degradation targets, affected modules, and masked status for each Provider.
- The readiness report feeds audit/runtime status without exposing external project names in normal UI.
- Current evidence keeps `runtime_loaded_count=0`. Adapters remain blocked, disabled, or test-required unless a local bounded probe has produced evidence.

## Profile Schema

`ProjectConfigProfile` includes:

`profile_id`, `display_name`, `mode`, `workspace_id`, `storage_config_id`, `model_config_id`, `embedding_config_id`, `search_provider_config_id`, `ocr_provider_config_id`, `pdf_parser_provider_config_id`, `exporter_config_id`, `redis_config_id`, `vector_config_id`, `network_policy_id`, `agent_memory_policy_id`, `tool_policy_id`, `is_default`, `is_active`, `version`, `created_at`, `updated_at`, `last_activated_at`, `last_test_status`, `last_test_summary`, `last_error`, `rollback_from_profile_id`.

Lifecycle behavior implemented:

- Default local Profile auto-created on runtime initialization.
- Active Profile persists across restart.
- Delete active Profile is blocked.
- Delete last Profile is blocked.
- Create, copy, update, activate, rollback, test operations are persisted and audited.
- Update increments version.
- Copy stores rollback source.
- Activation rewrites runtime status for downstream modules.

## Connection Test Matrix

| Config | Runtime path | Verified behavior |
| --- | --- | --- |
| Redis | `testRedisConnection` | Missing password, auth failure, connection failure, ping/write/read/delete result persistence, masked logs |
| Vector DB / Qdrant | `testQdrantConnection` | Invalid endpoint, invalid dimension, health/collection/vector write-search-delete path, masked logs |
| Provider runtime | `validateProviderRuntimeSettings` | Writes validation report, activation matrix, lifecycle log, rollback manifest |
| Model Gateway / ModelRoute | `saveModelGatewayProviderConfig`, `testModelGatewayProvider` | Writes gateway config/test/usage/fallback/reference registry, route pool, binding matrix, route audit, and downstream route evidence |
| Exporter | `validateExporterSettings` | Markdown/JSON/CSV local availability, DOCX/PDF/PPTX gated until configured |
| Storage | `_probeStoragePath` | Real write probe and Windows free-space query; failure records Chinese permission reason |
| Registered Provider health | `testAllRegisteredProviderCapabilities` | Checks 29 mappings, writes health JSON/JSONL, blocks unverified runtime load, proves rollback/fallback |
| Provider capability binding | `provider_capability_binding_manifest.json` | Binds 8 product capability areas to local fallback or proven Provider and syncs downstream runtime status |
| Provider active selection | `provider_capability_selection_state.json` | Persists explicit Provider selection, survives runtime refresh/restart, and suppresses auto-selection after rollback |
| Provider adapter contracts | `provider_adapter_contracts.json` | Defines 26 Provider adapter contracts with required config refs, health checks, fallback, and rollback |
| Provider adapter readiness | `provider_adapter_readiness_report.json` | Evaluates 26 adapter contracts against active Profile/config and keeps unverified adapters blocked |
| Parser/OCR adapter probes | `provider_adapter_probe_<provider_ref>.json` | Verifies real DU manifest, records, normalized markdown, and OCR input evidence before allowing Parser/OCR enhancements to be selected |
| Embedding/Vector adapter probes | `provider_adapter_probe_<provider_ref>.json` | Verifies real KB chunks, index profile, vector reference, build report, metadata, and chunk-count consistency before allowing Embedding/Vector enhancements to be selected |
| Exporter adapter probes | `provider_adapter_probe_jellyfish.json`, `provider_adapter_probe_story_flicks.json` | Verifies real structured export and video handoff boundary artifacts before allowing exporter enhancements to be selected |
| Workflow/A2A export adapter probes | `provider_adapter_probe_n8n.json` | Verifies real A2A session, rounds, runtime audit, conflict, consensus, and collaboration report artifacts before allowing workflow export enhancements to be selected |

The CI-safe tests cover failure and config-state paths without requiring external services. Real Redis/Qdrant success checks remain part of EXE smoke when Docker services are available.

## Failure Degradation Matrix

| Failure | Runtime behavior |
| --- | --- |
| Redis failure | Agent short memory disabled; A2A session state falls back to local files; document library, KB, Markdown generation unaffected |
| Vector DB failure | External vector DB disabled; knowledge base uses local index; runtime status marks rebuild/switch need when dimensions mismatch |
| LLM failure | Local import and parsing stay available; LLM summary, Skill generation, Agent dialogue require configured provider |
| Exporter failure | Markdown/JSON/CSV stay available; DOCX/PDF/PPTX remain disabled or failed until configured |
| Network authorization off | Web import and external fact verification disabled; local retrieval unaffected |

## Secret Masking Proof

Implemented:

- API keys, Redis password, and Vector DB token are stored as `*_secret_ref` or masked display values.
- `project_config_profiles.json`, `project_config_assets.json`, validation reports, and JSONL logs set `secret_plaintext_written=false` or `secret_masked=true`.
- Tests assert raw secrets are not written to storage settings or test logs.
- Config export paths do not include plaintext secret values.

## Runtime State Sync Proof

Profile activation refreshes `project_config_runtime_status.json` for:

- Dashboard: active Profile and health summary
- Document Library: storage path, OCR/Parser, web import state
- Knowledge Base: index backend, embedding dimension, vector status, rebuild flag
- Retrieval Verification: retrieval backend, external fact verification, search status
- Document Generation: LLM status, exporter status, Office exporter availability
- Skill Factory: LLM, KB, Search status
- Agent Workbench: model, Redis memory, vector memory, tool policy, unauthorized resource guard
- Registered Provider summary: provider count, selectable count, and capability-enhancement boundary
- Registered Provider health: health report path, health log path, hot-swap stability report path
- Provider capability binding: current local fallback vs proven Provider binding per downstream module
- Provider adapter contracts: contract path for all registered Provider refs and their activation prerequisites
- Provider adapter readiness: readiness report/log paths and blocked/degraded Provider reasons

Automated tests verify activation from local Profile to hybrid Profile synchronizes these module states.

## UI Scope

Settings now contains a minimal Config Profile panel:

- Profile list
- Active Profile
- Create, copy, test, switch, rollback, delete inactive
- Health and failure summary
- Registered capability health audit action

No broad UI redesign was performed. No tutorial/path prompt card was added.

## EXE Smoke Result

Automated unit/widget/runtime gates are complete. Full manual EXE smoke is pending Owner verification after opening the built EXE.

Required EXE smoke checklist:

1. Start EXE.
2. Create local Profile.
3. Create cloud/hybrid Profile.
4. Configure local storage.
5. Configure Redis.
6. Configure Qdrant.
7. Configure exporters.
8. Run connection tests.
9. Switch Profile.
10. Import input folder.
11. Build KB.
12. Search.
13. Generate Markdown.
14. Create Agent.
15. Run Agent dialogue.
16. Close EXE.
17. Restart EXE.
18. Confirm Profile, config state, KB, and Agent state persist.
19. Disconnect Redis/Qdrant.
20. Confirm degradation without crash.

## Validation

Passed locally:

- `flutter analyze`
- `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1`
- `flutter test test\widget_test.dart --concurrency=1`
- `git diff --check`
- no-secret scan
- overclaim scan
- OKF runtime scan

Latest Stage 3 Provider health slice:

- `flutter analyze`
- `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1`
- `flutter test test\widget_test.dart --concurrency=1`

Latest Stage 3 Provider active-selection slice:

- `flutter analyze`
- `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1`
- Targeted test: `provider hot swap selection persists across runtime refresh and rollback`

Latest Stage 3 Exporter Provider slice:

- `flutter analyze`
- `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1`
- Targeted test: `exporter adapters become selectable from real export artifacts`
- Fixed industrial evidence refresh now requires `jellyfish` to pass against
  the current structured export payload shape: `sources`,
  `retrieval.results`, JSON/CSV outputs, manifest `status=pass`, and
  `secret_plaintext_written=false`.
- This proves local structured content export readiness only; Jellyfish vendor
  runtime remains unloaded.

Latest Stage 3 Parser/OCR Provider slice:

- `flutter analyze`
- `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1`
- Targeted test: `parser ocr adapters become selectable from real parse artifacts`

Latest Stage 3 OCR evidence refresh slice:

- OCR Provider readiness now accepts real DU OCR evidence from
  `du/document_understanding_records.jsonl` in addition to image metadata from
  `source_manifest.json`.
- `provider_adapter_probe_paddleocr.json` and
  `provider_adapter_probe_surya.json` record `du_ocr_input_evidence` and
  `du_ocr_record_count`.
- The fixed industrial evidence refresh includes an OCR record so PaddleOCR and
  Surya can be proven as selectable Parser/OCR enhancements without loading
  vendor runtimes.
- Runtime boundary remains `external_runtime_executed=false`,
  `vendor_runtime_loaded=false`, and `secret_plaintext_written=false`.

Latest Stage 3 Embedding/Vector Provider slice:

- Targeted test: `embedding vector adapters become selectable from real index artifacts`

Latest Stage 3 Workflow/A2A Export Provider slice:

- Targeted test: `workflow collaboration adapter becomes selectable from real A2A exports`
- Fixed industrial evidence refresh now requires the real Agent Workbench A2A
  session manifest to carry `schema_version=prd_v3_a2a_session_manifest.v1`.
- `provider_adapter_probe_n8n.json` must pass from the fixed Stage 2 evidence
  workspace before `workflow_collaboration_export` can bind to `n8n`.
- The binding remains a workflow export capability enhancement:
  `runtime_loaded=false`, `external_runtime_executed=false`, and
  `vendor_runtime_loaded=false`.

Latest Stage 3 high-risk Provider gate slice:

- High-risk registered Provider refs now write explicit readiness probes before
  activation can be attempted: `anysearchskill`, `last30days_skill`,
  `seedance2_skill`, and `rtk`.
- Probe artifact:
  `config/provider_adapter_probe_<provider_ref>.json` with schema
  `prd_v3_provider_adapter_probe_high_risk_gate.v1`.
- The probes record network authorization status, secret-ref status, external
  runtime status, missing config refs, blocked reasons, local degradation
  target, rollback support, and affected modules.
- The gate keeps `ready_for_user_selection=false`,
  `runtime_loaded=false`, `runtime_load_allowed=false`,
  `network_call_attempted=false`, `external_runtime_executed=false`,
  `vendor_runtime_loaded=false`, and `secret_plaintext_written=false`.
- Activation audit now uses the Provider readiness status and blocked reasons
  instead of a generic blocked state, so Settings, readiness, binding, and
  selection logs stay consistent.
- Targeted test:
  `prd settings and parallel task validation produce industrial audit artifacts`.

Pending after push:

- remote CI green confirmation

## Unfinished Items

- Real Redis/Qdrant success probe depends on running external services and valid environment configuration; failure/degradation paths are automated.
- Full EXE smoke requires manual Owner verification after EXE launch.
- Registered but unloaded projects are still not loaded as product modules. Stage 3 now validates them as Provider capability enhancements with health status, blocked activation, local fallback, and rollback audit before any future real adapter execution.

## Owner Retest Checklist

- Settings Profile operations work: create, copy, test, switch, rollback, delete inactive.
- Active Profile persists after EXE restart.
- Deleting active or last Profile is blocked.
- DOCX/PDF/PPTX are not executable when exporter is unconfigured.
- Redis/Qdrant failures degrade safely and do not crash.
- Normal UI does not expose hot-swap project loading, Gate, Campaign, Core operation, backend matrix, or plaintext secret values.
