# Stage3 Provider Capability Integration Matrix

Date: 2026-06-21

Baseline chain: `文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A`

This report is generated from the current runtime evidence workspace. It treats registered projects as Provider capability enhancements, not product modules.

## Summary

- Provider refs evaluated: `26`
- Ready for user selection: `18`
- Runtime loaded by default: `0`
- Stage2 preflight: `passed`
- Runtime load allowed: `true`
- Failed Stage2 checks: ``
- Normal UI boundary: no external project names, no hot-swap terminology, no workflow execution claim.

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
| `skill_template_provider` | `andrej_karpathy_skills` | 已配置未测试 | `false` | `false` | `false` | teaching_or_reasoning_pattern_present; primary_config_type_recorded | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_andrej_karpathy_skills.json` |
| `skill_template_provider` | `mmskills` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_mmskills.json` |
| `skill_template_provider` | `seedance2_skill` | 配置缺失 | `false` | `false` | `false` | 当前 Profile 未开启网络授权。; 需要 secret 引用，不能写入或展示明文密钥。 | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_seedance2_skill.json` |
| `skill_template_provider` | `skill_prompt_generator` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_skill_prompt_generator.json` |
| `workflow_collaboration_export` | `n8n` | 连接成功 | `true` | `true` | `false` |  | `D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/output/stage2_industrial_runtime_workspace/config/provider_adapter_probe_n8n.json` |

## Current Industrial Boundary

- Ready local capability enhancements may be selected in Settings and reflected downstream in capability status.
- External runtime loading remains separate from local readiness. Current external-runtime eligible Provider is n8n only.
- Default refreshed runtime status keeps external runtime unloaded until an
  explicit endpoint health-load is requested.
- Live n8n external health-load has an opt-in proof against a local Docker
  endpoint at `http://127.0.0.1:5678`. The proof records
  `runtime_loaded_count=1` only after a health check, keeps workflow execution
  disabled, and verifies rollback returns the count to `0`.
- RAG evaluation Providers remain blocked until retrieval validation is explicitly reviewed, not merely saved as pending manual review.
- Benchmark-only, network, secret, dependency, and external-runtime Providers remain blocked until their required config/evidence exists.

## Owner Verification Focus

- In Settings, ordinary users should see capability status/configuration entries, not external project loading language.
- Ready capability enhancements should be selectable only where real local evidence exists.
- Blocked Providers should show user-understandable status such as configuration missing, disabled, external service required, or local fallback.
- Runtime-loaded count should remain zero unless the controlled external health-load gate succeeds.
- For live n8n recheck, run
  `STAGE3_VERIFY_LIVE_N8N=1 HEITANG_N8N_ENDPOINT=http://127.0.0.1:5678 flutter test test\rc6_runtime_truth_blocker_repair_test.dart --plain-name "stage3 live n8n endpoint runtime load uses health check only" --concurrency=1`.
