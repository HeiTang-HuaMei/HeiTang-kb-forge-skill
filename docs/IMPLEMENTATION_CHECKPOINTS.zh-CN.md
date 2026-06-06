# Implementation Checkpoints

## v1.8

状态：已完成。

已实现：

- Skill Package Generator
- Agent Package Generator
- Skill validation 文件
- 可选本地 / mock LLM 辅助 Skill 和 Agent 生成

验证：

- `tests/test_v18_cli_commands.py`
- `tests/test_skill_generator.py`
- `tests/test_agent_package_generator.py`
- `tests/test_llm_skill_generator.py`
- `tests/test_llm_agent_generator.py`

已知缺口：

- 不做真实 Agent Runtime。
- 不做平台上传。

## v1.9

状态：已完成。

已实现：

- Portable local workspace
- Package / Skill / Agent registries
- Relationship graph
- Provider registry
- Prompt profile registry
- LLM call audit import

验证：

- `tests/test_v19_config.py`
- `tests/test_workspace_init.py`
- `tests/test_workspace_import_export.py`
- `tests/test_workspace_relationship_graph.py`

已知缺口：

- 不做 SaaS workspace。
- 不做权限系统。

## v2.0

状态：已完成。

已实现：

- Stable contract checking
- Provider health checks
- Reliability scoring
- Release package snapshot
- Studio stable local outputs

验证：

- `tests/test_v20_config.py`
- `tests/test_v20_pipeline.py`
- `tests/test_stable_contracts.py`
- `tests/test_provider_health.py`
- `tests/test_reliability_score.py`

已知缺口：

- Master Skill decomposition 保留到 v2.2。
- Platform distribution 保留到 v2.4。

## v2.1

状态：已完成。

已实现：

- Input coverage
- Parser hardening
- Knowledge quality scoring
- Review workflow
- Retrieval evaluation
- Evidence benchmark
- LLM quality assist fallback

验证：

- `tests/test_v21_config.py`
- `tests/test_v21_pipeline.py`
- `tests/test_knowledge_quality.py`
- `tests/test_evidence_benchmark.py`

已知缺口：

- Quality assist 默认是本地 / mock。

## v2.2

状态：部分完成，checkpoint 后补已完成。

已实现：

- Master Skill import
- Skill decomposition
- Derived Skill generation
- Skill safety check
- Skill similarity check
- Skill license report
- Enhanced local Skill templates
- Agent compatibility stubs
- Static workspace refresh
- Offline provider readiness
- Prompt profile versioning
- Studio v2.2 action center and run history

验证：

- `tests/test_master_skill_import.py`
- `tests/test_skill_decomposition.py`
- `tests/test_derived_skill_generator.py`
- `tests/test_skill_safety_check.py`
- `tests/test_skill_similarity_check.py`
- `tests/test_skill_templates.py`
- `tests/test_agent_compat_checker.py`
- `tests/test_workspace_refresh.py`
- `tests/test_provider_readiness.py`
- `tests/test_prompt_profile_versioning.py`
- `tests/test_studio_action_center.py`
- `tests/test_run_history.py`

已知缺口：

- 兼容文件只是 stub。
- 不真实运行 OpenClaw、Claude Code、Codex 或 MCP Runtime。
- 不做平台分发。

## v2.3

状态：已完成。

已实现：

- Industrial batch job manifest
- Batch item status JSONL
- Batch retry record
- Batch quality / contract / governance summaries
- Package lineage graph
- Curated package generation
- Governance decision audit
- Update impact reports
- Batch & Governance Center read-only summaries

验证：

- `tests/test_batch_job_manifest.py`
- `tests/test_batch_item_status.py`
- `tests/test_batch_retry_failed.py`
- `tests/test_package_lineage.py`
- `tests/test_curated_package.py`
- `tests/test_update_impact.py`
- `tests/test_v23_config.py`
- `tests/test_v23_pipeline.py`
- `tests/test_v23_ui_smoke.py`

已知缺口：

- Retry 只是本地状态记录，不是后台调度器。
- Update impact 是静态保守分析。

## Planned

- v2.9 飞书 / 个人知识库 / 手机端 / 安装端 / iOS

## v2.4

状态：已完成。

已实现：

- 本地平台分发导出
- 上传准备检查输出
- 缺文件、疑似 API key、危险命令片段的静态上传检查
- Mock publish 输出
- OpenClaw / XHS / Codex / Claude Code / MCP / generic / local registry 文件适配
- 小红书本地 Skill package 准备

验证：

- `tests/test_platform_distribution.py`
- `tests/test_platform_distribution_all.py`
- `tests/test_platform_xhs_package.py`
- `tests/test_platform_upload_check.py`
- `tests/test_mock_publish.py`
- `tests/test_v24_config.py`
- `tests/test_v24_pipeline.py`
- `tests/test_v24_ui_smoke.py`

已知缺口：

- 不调用真实平台账号。
- 不自动发布小红书笔记。
- 小红书 package 不是小红书官方上传 API。
- 不真实运行 OpenClaw / Codex / Claude Code / MCP Runtime。
- 不启动 MCP Server。
- 上传检查只是本地静态准备检查，不是 provider 安全审计。

## Planned After v2.4

- v2.6 Provider Security and Studio Industrial Console
- v2.7 Release Candidate
- v2.8 Parser Backend and Knowledge Reliability
- v2.9 飞书 / 个人知识库 / 手机端 / 安装端 / iOS

## v2.5

状态：已完成。

已实现：

- Release Quality Gate
- Release Blocker 检测
- v1.6-v2.4 回归证据检查
- Golden sample registry 与验证
- 平台导出认证
- 兼容矩阵
- Mock-first LLM quality gate assist
- Release readiness 汇总
- Release Quality Center v2.5 只读摘要

验证：

- `tests/test_quality_gate.py`
- `tests/test_release_blockers.py`
- `tests/test_regression_check.py`
- `tests/test_golden_samples.py`
- `tests/test_export_certification.py`
- `tests/test_compatibility_matrix.py`
- `tests/test_llm_quality_gate_assist.py`
- `tests/test_release_readiness.py`
- `tests/test_v25_config.py`
- `tests/test_v25_pipeline.py`
- `tests/test_v25_ui_smoke.py`

已知缺口：

- 不调用真实 LLM API。
- 不真实上传小红书。
- 不真实运行 OpenClaw / Codex / Claude Code / MCP Runtime。
- 不启动 MCP Server。
- Provider 安全审计预留到 v2.6。
- Runtime compatibility smoke 预留到 v2.7。
- Knowledge Runtime Loop 仍预留到 v2.9。

## Planned After v2.5

- v2.6 Provider Security and Studio Industrial Console
- v2.7 Release Candidate
- v2.8 Parser Backend and Knowledge Reliability
- v2.9 Knowledge Runtime Loop

## v2.8

状态：Parser backend and knowledge reliability checkpoint 已完成。

已实现：

- Parser backend registry
- 内置 parser backend contract 标准化
- 可选 Docling adapter 边界
- 可选 Marker adapter 边界
- `parser-backend-list`
- `parse-with-backend`
- `parse-compare`
- `parse-quality-gate`
- `parse-reimport-corrected-text`
- `trusted-kb-gate`
- `build --parser-backend`
- `batch --parser-backend`
- Parser backend result 与 normalized output 文件
- Parse quality report
- OCR risk report
- High-risk page / chunk 输出
- Manual review queue
- Corrected text re-import 和 before/after quality diff
- Draft / reviewed / trusted KB status metadata
- Skill、Agent、platform export 默认阻断 untrusted KB
- Config parser backend build 与 trust policy 支持
- Pipeline 和 web parser backend reliability 可见性

验证：

- `tests/test_v28_parser_backends.py`
- `tests/test_version_alignment.py`
- `tests/test_version_matrix_docs.py`
- `tests/test_release_readiness.py`
- `tests/test_release_readiness_gate.py`

已知缺口：

- Docling 和 Marker adapter 是可选本地集成边界，默认不是 live parser integration。
- Parser backend mode 是 opt-in，不改变默认 build、batch、run 或 pipeline 行为。
- Draft parser-backed KB 需要人工 review 或显式 `--allow-untrusted` 才能导出。
- v2.9 Knowledge Runtime Loop 不属于 v2.8。

## v2.9

状态：本地 Knowledge Runtime Loop checkpoint 已完成。

已实现：

- `kb-index`
- `kb-query`
- `kb-answer`
- 本地 KB index 输出
- Query result 与 query trace 输出
- Citation trace 输出
- 带引用本地答案输出
- 低置信拒答行为
- Retrieval quality report
- RAG eval baseline JSONL 和 Markdown report
- `build --knowledge-runtime`
- `knowledge_runtime` 配置支持
- Pipeline 和 web knowledge runtime 输出可见性

验证：

- `tests/test_v29_knowledge_runtime.py`
- `tests/test_version_alignment.py`
- `tests/test_version_matrix_docs.py`
- `tests/test_release_readiness.py`
- `tests/test_release_readiness_gate.py`

已知缺口：

- Knowledge runtime mode 是 opt-in，不改变默认 build、batch、run 或 pipeline 行为。
- Retrieval 是确定性本地检索，不是 embedding 或向量数据库实现。
- v2.9 不调用 LLM API、embedding API、向量库、外部 Agent runtime、飞书、移动端、安装端或 iOS surface。
