# 路线图

## 当前方向

HeiTang KB Forge 仍然是 Skill-first Agent 知识供应链底座。桌面 UI 是本地表现层，不替代 Python package、CLI、config runner 或 pipeline runner。

## v1.6 已收口

- v1.6.2 progress 与大文件 / OCR 性能基线
- 多模态知识资产
- 多模态 evidence map
- Knowledge Package Contract v2
- contract checker
- Knowledge Package Builder UI v1
- v1.6 双语文档和溯源说明

## 明确非目标

- SaaS 多租户
- 权限系统
- 真实业务系统集成
- UI 私有知识包格式
- 把核心逻辑搬进 React 或 Tauri
# v1.7 可靠知识治理

v1.7 新增可选知识治理、高精度本地检索、Evidence Gate 和最小 LLM provider adapter，用于证据校验。该层保持 HeiTang KB Forge 的 Skill-first 和 headless 定位，并为后续 Agent/RAG Runtime 做准备。

# v1.8 Skill 与 Agent Package 生成

v1.8 完成从知识包到 Skill Package 再到 Agent Package 的交付闭环。它新增本地生成、校验、benchmark cases、可选 mock LLM 辅助和 UI 预览，但不新增真实 Agent Runtime。

# v1.9 Portable Local Workspace

v1.9 将项目升级为本地 Agent 知识资产工作区，包含 registry、relationship graph、provider registry、prompt profile registry、LLM call audit、import/export 和 health check。

# v2.0 稳定版 Agent 知识供应链底座

v2.0 将 v1.6-v1.9 的能力收口为稳定版 Agent 知识供应链底座，重点是 studio-run、stable-check、provider-health、reliability-score、release-package、extension readiness 和稳定版双语文档。

v2.0 只预留后续扩展点。母版 Skill 拆解学习、派生 Skill 生成、平台分发与上传适配在 v2.0 文档中作为未来能力预留，不作为 v2.0 已实现功能。

# v2.1 知识底座补强

v2.1 通过 opt-in 输入覆盖、parser hardening、增强 source inventory、知识质量评分、review workflow、retrieval evaluation、evidence benchmark 和 mock/fallback LLM quality assist 补强知识底座。

v2.1 仍然保持 offline-first，不强制真实 LLM。

# v2.2 工业级母版 Skill 拆解学习

v2.2 计划正式实现母版 Skill / 优秀 Skill 拆解学习。目标是分析 Skill 结构、任务模式、工作流、风格 profile、边界规则、安全约束、相似度风险和 license 状态，再结合用户自己的知识包生成派生 Skill。

这不是复制第三方 Skill。v2.2 只学习可复用结构和工作流模式，并保留安全边界、来源说明和用户自有知识范围。

v2.2 实现输出包括 `master_skill_inventory.json`、`skill_decomposition.json`、`skill_capability_map.json`、`skill_workflow_graph.json`、profile YAML 文件、`derived_skill_package`、安全报告、相似度报告和 license 报告。

# v2.4 Skill 分发与平台上传适配

v2.4 已实现 OpenClaw、XHS、Codex、Claude Code、MCP、Generic package 和 Local Registry package 的平台导出与上传适配准备。

v2.4 只生成 platform manifest、安装说明、上传检查和 mock publish 结果；不调用真实平台账号、不真实运行 Agent 平台、不启动真实 MCP Server、不自动上传小红书。

v2.4 实现范围是本地平台分发输出、上传准备检查、静态上传风险检查和 mock publish 记录。v2.6 / v2.9 仍然是 planned。

# v2.5 Release Quality Gate And Regression Certification

v2.5 已实现本地发布质量门禁、发布阻塞项检测、回归覆盖检查、golden sample 验证、平台导出认证、兼容矩阵、mock-first LLM quality gate assist、release readiness 汇总，以及 Release Quality Center v2.5 只读摘要。

v2.5 不调用真实 LLM API，不真实运行平台 runtime，不启动 MCP Server，不上传小红书，不实现 v2.6 Provider 安全审计完整版本，不实现 v2.8 parser backend reliability，也不实现 v2.9 Knowledge Runtime Loop。

后续真实验证边界：v2.6 做真实 LLM live smoke 与 provider governance，v2.7 做 runtime compatibility smoke，v2.9 做本地 Knowledge Runtime Loop，后续客户端平台集成再做飞书 / 移动端 / 安装端 / iOS，v3.x 做 SaaS / 权限系统 / 多用户协作。

# v2.8 Parser Backend and Knowledge Reliability

v2.8 实现 opt-in parser backend reliability。它新增 backend registry、内置 parser backend 标准化、可选 Docling 与 Marker adapter stub、parse compare、parse quality gate 输出、OCR risk report、manual review queue、corrected text re-import、trust status metadata 和 trusted KB export gate。

v2.8 保持默认 build、batch、run、pipeline 行为不变，只有显式启用 parser backend mode 时才生成新增输出。它不强制安装外部 parser 依赖，也不进入 v2.9 的平台、移动端、安装端或 iOS 范围。

# v2.9 Knowledge Runtime Loop

v2.9 实现 opt-in 本地 Knowledge Runtime Loop。它新增 `kb-index`、`kb-query`、`kb-answer`、本地 KB index 输出、query trace、citation trace、带引用本地答案、低置信拒答、retrieval quality report 和 RAG eval baseline 输出。

v2.9 保持默认 build、batch、run、pipeline 行为不变，只有显式启用 knowledge runtime mode 时才生成新增输出。它不调用 LLM API、embedding API、向量库、外部 Agent runtime、飞书、移动端、安装端或 iOS surface。
# v2.3 工业级批量处理与知识治理

v2.3 实现工业级 batch job manifest、item status 追踪、retry 记录、批量汇总、package lineage、curated package、governance decision log、update impact report，以及只读 Batch & Governance Center 方向。

v2.3 不实现平台导出、平台上传、真实 Agent Runtime、真实 MCP Server、SaaS 协作或外部发布 API。平台导出和上传适配保留到 v2.4。

# v2.3 checkpoint 后补

本轮后补关闭 v2.2 的部分工业级缺口，包括 enhanced Skill template files、Agent compatibility stubs、静态 workspace refresh、离线 provider readiness、prompt profile versioning 和 Studio v2.2 本地摘要。

这些都是本地文件输出，不实现 v2.4 平台分发、小红书 packaging/upload、OpenClaw export、MCP export 或 mock publish。
