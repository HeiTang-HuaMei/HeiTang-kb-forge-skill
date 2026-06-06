# HeiTang Knowledge Workbench 最终工作目标

## 1. 最终定位

HeiTang Knowledge Workbench 是一个本地优先的多知识库、多 Agent、多模型协作工具台。

它不是单一 Skill，也不是单一 CLI，也不是单一 RAG Demo。

最终形态：

- 多知识库管理。
- 多 Agent 创建与绑定。
- 多 Agent 协作与交互。
- 多模型 Provider 调度。
- Agent 独立记忆与共享记忆隔离。
- 知识资产生产。
- 知识库问答。
- 文档生成。
- Skill / Agent 生成。
- 外部 Skill 拆解与融合。
- 本地 Workbench UI。

## 2. 与 HeiTang KB Forge Core 的关系

HeiTang KB Forge Core 是 Workbench 的知识供应链核心 Skill。

它负责：

- 多格式资料进入知识系统前的标准化加工。
- 生成标准知识资产包。
- 质量门禁。
- 证据追踪。
- 人工复核准备。
- RAG / Agent 上游输出。

它不是完整工具台产品。

Workbench 负责把多个 Skill、多个 Agent、多个知识库、多个模型、多个记忆域组织起来，形成完整工业链路。

## 3. 最终用户路径

### 3.1 多知识库生产

用户上传各种资料：

- PDF
- DOCX
- Markdown
- TXT
- CSV / TSV / XLSX
- 图片
- 扫描 PDF
- HTML
- EPUB
- ZIP
- 外部 Skill 包

系统处理：

1. 选择 parser backend。
2. 执行 OCR / 文档解析。
3. 生成知识资产包。
4. 质量门禁。
5. 证据追踪。
6. 生成人工复核队列。
7. corrected text 回灌。
8. 生成最终知识库版本。

### 3.2 多知识库管理

用户可以创建多个知识库：

- 产品知识库。
- 运营知识库。
- 客服知识库。
- 教材知识库。
- 法务知识库。
- 行业研究知识库。
- 个人经验知识库。
- 项目知识库。
- 外部资料知识库。

每个知识库必须有独立配置：

- kb_id
- kb_name
- domain
- source_files
- version
- owner
- answer_policy
- citation_policy
- index_status
- quality_status
- review_status

### 3.3 多 Agent 创建

用户可以基于不同知识库创建不同 Agent：

- 产品经理 Agent。
- 客服 Agent。
- 导购 Agent。
- 教育伴学 Agent。
- 内容运营 Agent。
- 法务审核 Agent。
- 数据分析 Agent。
- 文档生成 Agent。
- 知识库维护 Agent。
- Skill 融合 Agent。

每个 Agent 必须明确绑定：

- agent_id
- role
- bound_knowledge_bases
- model_provider
- model_policy
- answer_policy
- tools
- private_memory_store
- allowed_shared_memory_scopes
- handoff_policy
- validation_cases

### 3.4 多 Agent 联动

多 Agent 不是默认共享全部记忆。默认隔离，只有在 workflow 明确授权时共享。

示例流程：

用户任务：基于产品知识库和用户反馈知识库生成一份产品方案 PPT。

流程：

1. Orchestrator Agent 接收任务。
2. Product Agent 检索产品知识库。
3. User Research Agent 检索用户反馈知识库。
4. Document Agent 生成 PPT 大纲。
5. Review Agent 检查引用和 answer_policy。
6. Export Agent 输出 PPT。
7. Workflow Memory 保存本次协作记录。
8. 各 Agent 只写入自己的私有记忆；共享结论进入 workflow shared memory。

### 3.5 多模型接入

不同 Agent 可以绑定不同模型：

- DeepSeek：低成本推理。
- Qwen：中文长上下文。
- Kimi：长文资料总结。
- OpenAI：高复杂推理。
- Gemini：多模态或长上下文。
- Anthropic：严谨写作 / 复杂分析。
- Zhipu / Doubao / OpenRouter：补充 Provider。

系统必须支持：

- provider registry
- model routing policy
- fallback policy
- cost guard
- redaction
- live smoke
- mock/live boundary

## 4. 最终系统结构

HeiTang Knowledge Workbench

- Web UI
  - 上传资料
  - 任务进度
  - 知识库浏览
  - 人工复核
  - 知识问答
  - 文档生成
  - Agent / Skill 生成
  - Skill 拆解融合
  - 导出中心

- Orchestrator Agent
  - 任务理解
  - Skill 选择
  - Agent 调度
  - Handoff 控制
  - Memory Scope 控制
  - 失败处理
  - 输出汇总

- Core Skills
  - Parser Backend Skill
  - KB Forge Core Skill
  - Quality / Evidence Skill
  - Knowledge Runtime Skill
  - Document Generator Skill
  - Agent Factory Skill
  - Skill Fusion Skill
  - Provider Governance Skill
  - Memory Governance Skill

- Workspace
  - source_files/
  - knowledge_bases/
  - knowledge_packages/
  - agents/
  - skills/
  - workflows/
  - memory/
  - review_queue/
  - generated_docs/
  - reports/

- External Backends
  - Docling
  - Marker
  - MinerU
  - PaddleOCR
  - Surya
  - Unstructured
  - LlamaIndex
  - Haystack
  - Qdrant
  - RAGAS
  - DeepEval
  - Mem0
  - Zep / Graphiti
  - LangGraph

## 5. 产品边界

当前阶段不做：

- SaaS。
- 多人权限。
- 云部署。
- 自动外部平台发布。
- 把 mock 冒充 live。
- 任意扫描 PDF 自动高精度入库承诺。
- Agent 默认共享记忆。
- 多 Agent 默认互相读取私有记忆。

## 6. 关键原则

1. 默认本地优先。
2. 默认 offline / mock。
3. live 必须显式开启。
4. Agent 记忆默认隔离。
5. 多 Agent 共享记忆必须由 workflow 明确授权。
6. 知识库与 Agent 绑定必须可追踪。
7. 回答策略必须明确。
8. 领域事实必须可引用。
9. 高风险场景必须 strict_grounded。
10. 所有生成物必须有 evidence / trace / report。
