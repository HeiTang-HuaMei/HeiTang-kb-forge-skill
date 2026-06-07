# HeiTang Knowledge Workbench 版本计划

## 当前基线

当前已经完成：

- v2.5.1：工程收敛 / CI / CLI / Release Gate。
- v2.6.0-alpha.1：Provider Governance / mock-live 边界。
- v2.7.0-alpha.1：Minimal End-to-End Demo。
- v2.8.0-alpha.1：Parser Backend and Knowledge Reliability checkpoint。
- v2.9.0-alpha.1：Local Knowledge Runtime Loop checkpoint。
- 作品集展示包。
- Agent 与知识库回答策略文档。

当前真实定位：

HeiTang KB Forge Core 是知识供应链核心 Skill，不是完整工具台产品。

当前完成度：

- GitHub / 面试作品集：85%
- KB Forge Core Skill：60%
- 本地工具台产品：30% - 35%
- 完整多知识库 / 多 Agent / 多模型工作台：25% - 30%

## 总体目标

构建 HeiTang Knowledge Workbench：

- 多知识库。
- 多 Agent。
- 多模型。
- 多 Agent 联动。
- Agent 记忆隔离。
- Workflow 共享记忆。
- 知识资产生产。
- 知识库问答。
- 文档生成。
- 专属 Agent / Skill 生成。
- 外部 Skill 拆解融合。
- 本地 Workbench UI。

## 版本规则

每个版本只解决一个大问题。

禁止：

- CI 红进入下一版。
- mock 冒充 live。
- README 夸大能力。
- 默认共享 Agent 私有记忆。
- 把所有功能继续塞进一个 Skill。
- 把 P0 留到后补版本。
- 没有 smoke 就进入下一版。

## v2.8 Parser Backend & Knowledge Reliability

核心问题：

复杂资料解析可靠性不足。

必须完成：

- parser_backend_registry
- optional Docling backend
- optional Marker backend
- parse-with-backend
- parse-compare
- parse-quality-gate
- high_risk_parse_pages.jsonl
- manual_review_queue.jsonl
- corrected_text re-import
- before / after quality diff
- knowledge_reliability_report.json

完成标准：

同一份资料可通过 builtin / docling / marker 至少两种路径解析；能够标出高风险页和高风险 chunk；人工修正文本可回灌并重新 build。

进度提升：

完整工作台：30% - 35% → 45%。

## v2.9 Knowledge Runtime Loop

核心问题：

知识库生成后还不能稳定使用。

必须完成：

- kb-index
- kb-query
- kb-answer
- answer_policy
- citation required mode
- evidence-grounded answer
- low-confidence refusal
- external knowledge disclosure
- query trace
- feedback log
- retrieval quality report
- RAG eval baseline

完成标准：

用户可以基于知识包提问；回答必须带 citation；低置信必须拒答；回答过程可追踪。

进度提升：

45% → 55%。

## v3.0 Document Generation Loop

核心问题：

知识库不能生成用户想要的文件。

必须完成：

- generate-md
- generate-docx
- generate-pdf
- generate-pptx
- template registry
- content planner
- citation insertion
- source evidence appendix
- export validation
- generated_file_report.json

完成标准：

用户选择知识库内容后，可以生成 Markdown / Word / PDF / PPT，且生成文件带来源依据。

进度提升：

55% → 65%。

## v3.1 Agent / Skill Factory

核心问题：

当前 Agent / Skill 仍偏静态导出，既不能形成真正绑定知识库的专属行业 Agent，也不能创建不依赖知识库的 standalone Agent。

必须完成：

- mode: kb_bound
- mode: standalone
- knowledge-bound-skill
- knowledge-bound-agent
- standalone-agent
- retrieval tool binding
- provider binding
- evidence policy binding
- refusal policy binding
- answer_policy binding
- agent test cases
- agent smoke test
- skill validation report
- industry agent template registry
- standalone Agent capabilities / tools / memory / output contract / eval cases

完成标准：

选择一个知识库 + 一个场景，可以生成 KB-bound Agent / Skill；不选择知识库时，可以生成 standalone Agent。KB-bound 生成物必须包含知识库路径、检索配置、Provider 配置、引用规则、拒答规则、测试问题和 smoke 结果；standalone 生成物必须包含 system prompt、capabilities、tools、memory policy、output contract、answer policy、refusal policy、eval cases 和 smoke 结果。

进度提升：

65% → 75%。

## v3.2 Multi-KB & Multi-Agent Orchestration

核心问题：

单知识库 / 单 Agent 不足，用户需要多知识库、多 Agent、多模型协作，并且 Agent registry 必须同时容纳 KB-bound 与 standalone Agent。

必须完成：

- multi-kb registry
- agent registry
- agent mode: kb_bound | standalone
- agent-to-kb binding
- model routing policy
- KB/domain 问题路由到 trusted KB-bound Agent
- planning/process/coach 任务路由到 standalone Agent
- multi-agent workflow definition
- orchestrator agent
- agent handoff protocol
- workflow shared memory
- agent private memory isolation
- cross-kb retrieval
- conflict detection between KBs
- multi-agent trace report
- workflow smoke test

完成标准：

用户可以创建多个知识库；创建多个 KB-bound 或 standalone Agent；KB-bound Agent 可以绑定不同知识库和模型；standalone Agent 可以承担规划、流程、教练、写作等非 KB-grounded 任务；多个 Agent 可以按 workflow 协作；系统输出协作 trace；Agent 私有记忆默认隔离。

进度提升：

75% → 83%。

## v3.3 Skill Reverse & Fusion Loop

核心问题：

不能拆解外部 Skill，也不能融合自身知识库生成自己的专用 Skill。

必须完成：

- import-skill
- analyze-skill
- extract instructions
- extract tools / schema
- extract examples
- capability map
- prompt pattern map
- fusion plan
- generate-fused-skill
- validate-fused-skill
- diff report
- safety boundary report
- answer_policy rewrite

完成标准：

能导入外部 Skill；拆出能力边界、prompt pattern、输入输出；结合自身知识库生成新 Skill；输出差异报告和验证结果。

进度提升：

83% → 88%。

## v3.4 Local Knowledge Workbench UI

核心问题：

当前仍是 CLI，不是产品化工具台。

必须完成：

- local web UI
- upload files
- job queue
- progress dashboard
- knowledge base browser
- review queue UI
- corrected text editor
- kb query UI
- document generation UI
- Agent / Skill generation UI
- multi-agent workflow UI
- memory scope viewer
- export center
- local workspace history

完成标准：

非技术用户可以在本地页面完成上传资料、查看进度、查看知识包、复核低质量内容、查询知识库、生成文档、生成 Agent / Skill、配置多 Agent 协作、查看记忆隔离和导出结果。

进度提升：

88% → 92%。

## v3.5 Product Hardening & Installer

核心问题：

工具台能跑，但还不够稳定、易安装、易演示。

必须完成：

- Windows installer / one-click start
- dependency doctor
- parser backend doctor
- OCR dependency doctor
- memory backend doctor
- task retry
- job resume
- error recovery
- benchmark dataset
- performance dashboard
- backup / restore workspace
- demo mode
- release candidate checklist

完成标准：

新机器可以按文档安装；一键启动本地 Workbench；失败任务可重试；工作区可备份恢复；demo 稳定。

进度提升：

92% → 95%。

## v4.0 Team / SaaS Optional

核心问题：

如果升级为团队平台，需要权限、协作、部署。

必须完成：

- user roles
- workspace permissions
- team review flow
- audit log
- deployment mode
- API server
- multi-user storage
- admin dashboard

说明：

v4.0 不是当前必须目标。当前主目标是本地 Workbench。
