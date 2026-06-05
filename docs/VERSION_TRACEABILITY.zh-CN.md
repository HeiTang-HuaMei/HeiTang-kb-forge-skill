# 版本溯源

## v1.6 负责范围

v1.6 负责：

- progress 与大文件 / OCR 性能基线
- 多模态知识资产
- 多模态 evidence map
- Knowledge Package Contract v2
- contract checker
- Knowledge Package Builder UI v1
- v1.6 中英文双语文档
- v1.6 验证测试

## 后续问题优先追溯 v1.6

以下问题优先从 v1.6 排查：

- 大文件处理进度问题
- OCR cache / resume 问题
- 多模态资产缺失
- `multimodal_evidence_map.json` 错误
- manifest v2 字段不稳定
- evidence v2 字段不稳定
- contract checker 判定错误

## 边界

v1.6 不做 Evidence Gate、高精度检索索引、Skill 生成、Agent Runtime、Tool Runtime 或外部 connector。
# v1.7 可追溯性

v1.7 新增治理、检索、Evidence Gate 和 LLM 证据校验输出。这些文件都是 opt-in，不改变默认离线知识包契约。

# v1.8 可追溯性

v1.8 负责 Skill Package 生成、Skill Validation、Agent Package 生成，以及可选 LLM 辅助 Skill / Agent 文件生成。`SKILL.md`、`skill_manifest.yaml`、规则文件、`soul.md`、`system_prompt.md` 或 launch checklist 的问题应追溯到 v1.8。

# v1.9 可追溯性

v1.9 负责 workspace 初始化、package/skill/agent registries、relationship graph、provider registry、prompt profile registry、LLM call audit、workspace import/export 和 workspace health check。

# v2.0 溯源

v2.0 负责稳定版 Agent 知识供应链底座：`studio-run`、`stable-check`、stable contracts、`provider-health`、reliability score、release package snapshot、extension readiness、Studio v2 摘要和稳定版双语文档。

母版 Skill 拆解学习预留到 v2.2。平台导出和上传适配预留到 v2.4。

# v2.1 溯源

v2.1 负责输入覆盖、parser hardening、增强 source inventory、知识质量评分、review workflow、curated chunks、retrieval evaluation、evidence benchmark 和可选 LLM quality assist fallback。

# v2.2 溯源

v2.2 负责母版 Skill 导入、Skill 拆解、profile 抽取、派生 Skill 生成、Skill 安全检查、Skill 相似度报告和 Skill license 报告。
# v2.3 Traceability

v2.3 负责 `batch_job_manifest.json`、`batch_item_status.jsonl`、batch retry 记录、批量汇总报告、`package_version_graph.json`、`curated_package/`、`governance_decisions.jsonl`、`impacted_skills.json`、`impacted_agents.json` 和 Batch & Governance Center 摘要。

如果出现批量状态、retry 记录、curation 纳入/排除、package lineage 或 update impact 输出错误，优先追溯 v2.3。

# v2.3 checkpoint 后补 Traceability

本轮后补负责 enhanced Skill template files、Agent compatibility stubs、workspace refresh reports、provider readiness reports、prompt profile versioning reports、`action_center.json`、`run_history.jsonl` 和 `studio_v22_summary.json`。

v2.4 平台分发仍是 planned，不属于本 checkpoint。
