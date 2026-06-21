# Stage3 Provider Capability Integration Matrix

Date: 2026-06-21

Baseline chain: `文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A`

This report is generated from the current runtime evidence workspace. It treats registered projects as Provider capability enhancements, not product modules.

## Summary

- Provider refs evaluated: `26`
- Provider-to-capability mappings evaluated: `29`
- Ready provider-to-capability mappings: `24`
- Ready unique Provider refs: `21`
- Registry class counts: `capability_provider=21`, `template_asset=7`, `architecture_reference=1`
- Architecture reference status counts: `absorbed_into_architecture=29`, `deferred_with_blocker=0`, `candidate_reference=0`, `rejected_no_architecture_gain=0`
- Runtime loaded by default: `0`
- Stage2 preflight: `passed`
- Runtime load allowed: `true`
- Failed Stage2 checks: ``
- Normal UI boundary: no external project names, no hot-swap terminology, no workflow execution claim.

## Classification Model

Registered projects are split before they can affect product behavior:

| Lane | Runtime behavior | User-facing behavior | Current count |
| --- | --- | --- | --- |
| Capability Provider | Can become a configurable Provider only after config, health/readiness, fallback, audit, and rollback evidence exists. | Users see capability options such as Parser/OCR, index backend, exporter, Agent memory/tool runtime, evaluation gate, or A2A export. | `21` mappings |
| Template Asset | Never requires external runtime load. Must provide template manifest, source, version, validation, and Skill/Agent binding boundary. | Users see template/style/method options inside Skill Factory, document generation, or Agent binding surfaces. | `7` mappings |
| Architecture Reference | Does not enter normal UI or runtime loading. It must be absorbed into architecture, explicitly rejected, or deferred with a blocker. | Users do not see project names. Only improved contracts, schema, gates, audit, or fallback behavior may surface indirectly. | `1` mapping |

Architecture reference statuses are now explicit:

- `absorbed_into_architecture`: reference has been converted into Provider contracts, schema, UI information architecture boundary, test gate, audit model, fallback/degradation rule, or loading rule. It is not accepted as a learning note only, and the runtime absorption record must include `parallel_architecture_delivery`.
- `deferred_with_blocker`: reference may be valuable but cannot yet be absorbed because a named blocker remains, such as external runtime proof, retrieval evaluation evidence, network authorization, or permission boundary proof.
- `rejected_no_architecture_gain`: reference is not retained when it does not improve the v3 main chain or is covered by existing abstractions.
- `candidate_reference`: must remain `0` in current Stage3 runtime reports. It is not a long-term holding state.

`reference_only` is not a current source or runtime classification. Registered projects must resolve to Provider capability, template asset, absorbed architecture reference, rejected reference, or deferred reference with a named blocker.

## Capability Binding State

| Capability | Active provider kind | Active provider | Selection allowed | Runtime load allowed | Runtime loaded | User status |
| --- | --- | --- | --- | --- | --- | --- |
| `agent_model_tools_memory` | `registered_provider` | `llm_wiki_v2` | `true` | `true` | `false` | 连接成功 |
| `document_exporter` | `registered_provider` | `jellyfish` | `true` | `true` | `false` | 连接成功 |
| `document_parser_ocr` | `registered_provider` | `docling` | `true` | `true` | `false` | 连接成功 |
| `governance_audit_provider` | `registered_provider` | `mattpocock_skills` | `true` | `true` | `false` | 连接成功 |
| `knowledge_embedding_vector` | `registered_provider` | `rag_anything` | `true` | `true` | `false` | 连接成功 |
| `retrieval_provider` | `registered_provider` | `sirchmunk` | `true` | `true` | `false` | 连接成功 |
| `skill_template_provider` | `registered_provider` | `skill_prompt_generator` | `true` | `true` | `false` | 连接成功 |
| `workflow_collaboration_export` | `registered_provider` | `n8n` | `true` | `true` | `false` | 连接成功 |

## Provider Readiness Matrix

| Capability | Provider ref | Status | Ready | Runtime load allowed | Runtime loaded | Blocked reason | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `agent_model_tools_memory` | `llm_wiki_v2` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_llm_wiki_v2.json` |
| `agent_model_tools_memory` | `rtk` | 需启动外部服务 | `false` | `false` | `false` | 需要启动外部服务并通过健康检查。 | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_rtk.json` |
| `document_exporter` | `jellyfish` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_jellyfish.json` |
| `document_exporter` | `story_flicks` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_story_flicks.json` |
| `document_parser_ocr` | `docling` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_docling.json` |
| `document_parser_ocr` | `marker` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_marker.json` |
| `document_parser_ocr` | `mineru` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_mineru.json` |
| `document_parser_ocr` | `opendataloader` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_opendataloader.json` |
| `document_parser_ocr` | `paddleocr` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_paddleocr.json` |
| `document_parser_ocr` | `surya` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_surya.json` |
| `document_parser_ocr` | `unstructured` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_unstructured.json` |
| `governance_audit_provider` | `deepeval` | 已配置未测试 | `false` | `false` | `false` | validation_report_invalid | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_deepeval.json` |
| `retrieval_provider` | `deepeval` | 已配置未测试 | `false` | `false` | `false` | validation_report_invalid | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_deepeval.json` |
| `governance_audit_provider` | `ragas` | 已配置未测试 | `false` | `false` | `false` | validation_report_invalid | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_ragas.json` |
| `retrieval_provider` | `ragas` | 已配置未测试 | `false` | `false` | `false` | validation_report_invalid | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_ragas.json` |
| `governance_audit_provider` | `mattpocock_skills` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_mattpocock_skills.json` |
| `skill_template_provider` | `mattpocock_skills` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_mattpocock_skills.json` |
| `knowledge_embedding_vector` | `llamaindex` | 配置缺失 | `false` | `false` | `false` | benchmark-only Provider 需要外部配置或基准证据 | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_llamaindex.json` |
| `knowledge_embedding_vector` | `rag_anything` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_rag_anything.json` |
| `knowledge_embedding_vector` | `weknora` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_weknora.json` |
| `retrieval_provider` | `anysearchskill` | 已禁用 | `false` | `false` | `false` | 当前 Profile 未开启网络授权。 | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_anysearchskill.json` |
| `retrieval_provider` | `last30days_skill` | 需安装外部服务 | `false` | `false` | `false` | 当前 Profile 未开启网络授权。; 需要安装依赖或完成本地适配。 | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_last30days_skill.json` |
| `retrieval_provider` | `sirchmunk` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_sirchmunk.json` |
| `skill_template_provider` | `ai_marketing_skills` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_ai_marketing_skills.json` |
| `skill_template_provider` | `andrej_karpathy_skills` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_andrej_karpathy_skills.json` |
| `skill_template_provider` | `mmskills` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_mmskills.json` |
| `skill_template_provider` | `seedance2_skill` | 配置缺失 | `false` | `false` | `false` | 当前 Profile 未开启网络授权。; 需要 secret 引用，不能写入或展示明文密钥。 | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_seedance2_skill.json` |
| `skill_template_provider` | `skill_prompt_generator` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_skill_prompt_generator.json` |
| `workflow_collaboration_export` | `n8n` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_n8n.json` |

## Current Industrial Boundary

- Ready local capability enhancements may be selected in Settings and reflected downstream in capability status.
- Readiness counts are split intentionally: `ready_mapping_count=24` counts
  provider-to-capability rows, while `ready_unique_provider_count=21` counts
  unique Provider refs. `mattpocock_skills` is ready for both Skill templates
  and governance/audit, so it appears in two mappings but one unique Provider
  ref.
- `andrej_karpathy_skills` is now absorbed as a local teaching/reasoning
  template asset manifest. It remains `runtime_loaded=false`; no external
  repository code, network call, or vendor runtime is bundled or executed.
- External runtime loading remains separate from local readiness. Controlled
  external-runtime gates are limited to health checks for n8n and RTK after
  Stage2 preflight evidence passes; they do not execute workflows, Agent tools,
  vendor jobs, or arbitrary project code.
- Default refreshed runtime status keeps external runtime unloaded until an
  explicit endpoint health-load is requested.
- Live n8n external health-load has an opt-in proof against a local Docker
  endpoint at `http://127.0.0.1:5678`. The proof records
  `runtime_loaded_count=1` only after a health check, keeps workflow execution
  disabled, and verifies rollback returns the count to `0`.
- RAG evaluation entries are capability Providers for governance/evaluation
  gates. They are ready only after local retrieval validation has reviewed
  result counts, citation coverage, conflict evidence, and the no-external-call
  boundary. When explicitly activated, the selection state binds both
  `retrieval_provider` and `governance_audit_provider` to the same evaluated
  Provider; rollback removes both selections and returns both capabilities to
  local fallback. `ragas` and `deepeval` remain `runtime_loaded=false` and do
  not execute vendor runtimes.
- `anysearchskill` remains blocked in the default local Profile, but now has a
  tested authorized-network path: non-local Profile, network authorization,
  Provider domain allowlist, local query evidence, and a clean external boundary
  can make it selectable while still avoiding live vendor calls during readiness.
- `last30days_skill` remains blocked in the default local Profile, but now has a
  tested authorized time-window retrieval path: non-local Profile, network
  authorization, local query evidence with recent-date/time-window metadata,
  and a clean external boundary can make it selectable while keeping
  `runtime_loaded=false` and avoiding live vendor calls during readiness.
- `seedance2_skill` remains blocked in the default local Profile, but now has a
  tested authorized template-asset path: non-local Profile, network
  authorization, masked secret ref, and validated template manifest can make it
  selectable as a Skill template asset. It remains `runtime_loaded=false`, does
  not execute video generation, does not perform network calls during readiness,
  and does not write plaintext secrets.
- Authorized high-risk activation paths are now rollback-tested. Rollback of
  `anysearchskill` and `last30days_skill` removes the explicit
  `retrieval_provider` selection, suppresses automatic reselection, and returns
  Retrieval Verification to local fallback. Rollback of `seedance2_skill`
  removes the `skill_template_provider` selection and returns Skill Factory to
  local template behavior. All three rollback paths keep
  `runtime_loaded=false`, `external_runtime_executed=false`, and no plaintext
  secret evidence.
- RTK is an Agent tool/runtime capability Provider. Its default readiness stays
  blocked with `external_runtime_required` until Stage2 Agent permission
  boundary evidence, a user-owned endpoint, and the RTK health gate pass. The
  controlled runtime-load proof is health-check-only: it may record
  `runtime_loaded=true` after `/health` succeeds, but keeps
  `agent_tool_executed=false`, `external_runtime_executed=false`,
  `workflow_executed=false`, and `secret_plaintext_written=false`. Controlled
  rollback snapshots the RTK load manifest and returns Agent capability status
  to local fallback with `runtime_loaded=false`.
- LlamaIndex remains an architecture reference with no runtime loading or
  normal-UI project visibility, but its useful abstraction has now been
  absorbed into the index/RAG Provider architecture: provider contract,
  index/vector schema, RAG orchestration schema, retrieval planning gate,
  fallback policy, and audit model. It is still not selectable from local KB
  artifacts alone and cannot load vendor runtime code.
- Architecture references are not accepted as learning notes. Each registered
  reference must resolve to `absorbed_into_architecture`,
  `rejected_no_architecture_gain`, or `deferred_with_blocker`; deferred entries
  must name the blocker, and absorbed entries must deliver contract, schema,
  runtime boundary, UI information boundary, test gate, audit model, fallback
  rule, or Provider loading rule changes in parallel.
- High-risk gates for network search, time-window retrieval, video Skill
  template, and Agent tool/runtime Providers now publish `gate_kind` and
  `gate_audit` through readiness, health, integration, eligibility, coverage,
  and selection logs. A blocked gate explicitly proves local fallback,
  rollback support, secret masking, no normal-UI project name, no network call,
  no vendor runtime load, and no external runtime execution.
- Benchmark-only, network, secret, dependency, and external-runtime Providers remain blocked until their required config/evidence exists.

## Owner Verification Focus

- In Settings, ordinary users should see capability status/configuration entries, not external project loading language.
- Ready capability enhancements should be selectable only where real local evidence exists.
- Blocked Providers should show user-understandable status such as configuration missing, disabled, external service required, or local fallback.
- Runtime-loaded count should remain zero unless the controlled external health-load gate succeeds.
- For live n8n recheck, run
  `STAGE3_VERIFY_LIVE_N8N=1 HEITANG_N8N_ENDPOINT=http://127.0.0.1:5678 flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "stage3 live n8n endpoint runtime load uses health check only" --concurrency=1`.
- For RTK recheck, use the targeted test
  `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "stage3 rtk runtime load uses agent health check only" --concurrency=1`.
