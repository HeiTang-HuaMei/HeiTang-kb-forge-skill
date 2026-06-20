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
| Embedding Provider | Provider type, model, dimension, endpoint, API key ref, test vector status, dimension mismatch flag |
| Search Provider | Provider type, endpoint, API key ref, network authorization, external verification flag, query test status |
| OCR Provider | Provider type, enabled flag, language, test availability, unavailable reason |
| PDF Parser Provider | Builtin/provider type, enabled flag, test parse status, fallback policy |
| Exporter Provider | Markdown, DOCX, PDF, PPTX, JSON, CSV, Skill package, Agent config, A2A report with per-format availability |
| Redis | Host, port, username, password ref, db, namespace, TLS, timeout, ping/auth/write-read-delete status |
| Vector DB | Provider type, endpoint, API key ref, collection, embedding config id, dimension, health, collection, vector test |
| Network Authorization | Web import, external verification, allowlist, timeout, retry, disabled reason |
| Agent Memory / Tool Policy | Simple/complex Agent memory and tool access policy, unauthorized resource guard |

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
- `provider_adapter_contracts.json`
- `provider_adapter_readiness_report.json`
- `provider_adapter_readiness_log.jsonl`

Coverage:

- 26 unique registered provider references
- 30 provider-to-capability mappings
- 8 product capability areas
- 0 entries marked runtime-loaded by default
- 0 entries marked ready for user selection without config/test evidence
- 1 local retrieval adapter can become selectable after real KB chunks are present

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
- Current evidence covers 30 provider-to-capability mappings and 26 unique registered Provider references.
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

Adapter contracts:

- `provider_adapter_contracts.json` turns the 26 unique registered Provider references into explicit adapter contracts.
- Each contract records adapter type, capability IDs, affected modules, runtime execution mode, required config refs, health check actions, activation prerequisites, fallback Provider, rollback support, and masking policy.
- The contracts cover all 30 provider-to-capability mappings while keeping `runtime_loaded_count=0`. Readiness remains blocked unless a real readiness check passes.
- `registered_provider_health_report.json` and `project_config_runtime_status.json` both reference the adapter contract path.

Local retrieval adapter proof:

- `sirchmunk` has a bounded direct-file-search probe at `config/provider_adapter_probe_sirchmunk.json`.
- The probe reads only workspace-owned `kb/chunks.jsonl` and requires at least one chunk with real text or content.
- When the probe succeeds, `provider_adapter_readiness_report.json` marks `sirchmunk` as `连接成功` and `ready_for_user_selection=true`.
- `provider_capability_binding_manifest.json` then binds `retrieval_provider` to `sirchmunk` with `selection_allowed=true`.
- `runtime_loaded` remains `false`; this is a verified local adapter readiness path, not arbitrary external project execution.
- The probe records `network_used=false`, `secret_plaintext_written=false`, and `normal_ui_project_name_visible=false`.

Adapter readiness:

- `provider_adapter_readiness_report.json` evaluates the 26 adapter contracts against the active Profile and current workspace configuration.
- It records missing config refs, blocked reasons, Chinese error messages, degradation targets, affected modules, and masked status for each Provider.
- The readiness report feeds audit/runtime status without exposing external project names in normal UI.
- Current evidence keeps `runtime_loaded_count=0` and `ready_for_user_selection_count=0`; adapters remain blocked, disabled, or test-required until real checks pass.

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
| Exporter | `validateExporterSettings` | Markdown/JSON/CSV local availability, DOCX/PDF/PPTX gated until configured |
| Storage | `_probeStoragePath` | Real write probe and Windows free-space query; failure records Chinese permission reason |
| Registered Provider health | `testAllRegisteredProviderCapabilities` | Checks 30 mappings, writes health JSON/JSONL, blocks unverified runtime load, proves rollback/fallback |
| Provider capability binding | `provider_capability_binding_manifest.json` | Binds 8 product capability areas to local fallback or proven Provider and syncs downstream runtime status |
| Provider adapter contracts | `provider_adapter_contracts.json` | Defines 26 Provider adapter contracts with required config refs, health checks, fallback, and rollback |
| Provider adapter readiness | `provider_adapter_readiness_report.json` | Evaluates 26 adapter contracts against active Profile/config and keeps unverified adapters blocked |

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
