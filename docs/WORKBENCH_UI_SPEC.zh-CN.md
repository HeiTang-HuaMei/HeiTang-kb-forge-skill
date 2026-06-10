# HeiTang Knowledge Workbench UI 规格

状态：UI-v0.1 至 UI-v0.5 原型，并加入 v4.1.0 Parser/OCR evidence sync。本规格定义基于 fixture 的产品界面，Core runtime 集成保留给明确的 bridge / service 层。

## 范围

- 构建 Web 优先的 Knowledge Workbench 原型，使用静态 HTML、CSS、JavaScript。
- 在 `web/workbench/flutter_app/` 下提供 Flutter scaffold，覆盖 Windows 桌面、Web/PWA、Android、iOS target。
- 数据源只允许使用 `examples/ui_mock_data/*.json`。
- 不实现解析、RAG、文档生成、Agent 编排或记忆运行时逻辑。
- 展示复制自 Core fixture 的 P2.1 parser backend matrix evidence，但不执行 parser/OCR runtime。
- 未来 API 替换边界保留在 `web/workbench/src/mockService.js`。
- Flutter UI scaffold 不得导入 Core pipeline 模块。

## 设计系统

- 视觉风格：极简黑、白、灰。
- 品牌：界面必须明显展示 `黑糖 HeiTang`。
- 品牌资产：黑猫头与黑虎头 SVG 资产必须位于 `web/workbench/flutter_app/assets/brand/`。
- 布局：桌面固定侧边栏、顶部栏、卡片网格、紧凑表格、柔和边框面板。
- 控件：圆角按钮、分段语言切换、主题图标按钮、表单字段、状态标签、进度条。
- 字体：系统无衬线字体，层级清晰，不使用装饰性字体。
- 主题：通过 CSS 变量和 `body[data-theme]` 支持明暗模式。
- 信息密度：偏运营工作台，不使用彩色杂乱装饰。

## 导航

1. 仪表盘
2. 文件上传
3. 任务进度
4. 知识库列表
5. 知识库详情
6. 复核队列
7. 校正文稿编辑器
8. 知识库查询
9. 文档生成
10. Agent / Skill 管理
11. 多 Agent 工作流
12. 记忆范围查看器
13. 设置
14. 导出中心

## 页面契约

### 仪表盘

展示知识库、可信/草稿状态、Agent、复核风险、当前任务和供应商就绪状态。

模拟数据源：`knowledge_bases.json`、`agents.json`、`jobs.json`、`review_queue.json`、`provider_status.json`、`parser_backends/parser_backend_matrix.json`。

### 文件上传

展示模拟拖放区和解析器就绪状态。上传按钮只做界面展示，不调用解析后端。

模拟数据源：`parser_backend_status.json`、`parser_backends/parser_backend_matrix.json`、`jobs.json`。

Parser backend matrix 展示规则：

- Builtin：保留 fallback。
- Docling：真实 runtime 已集成，optional dependency gated，稳定表面以发布证据为准。
- PaddleOCR：真实 runtime 已集成，optional dependency gated，稳定 PNG OCR 证据。
- Unstructured：真实 runtime 已集成，optional dependency gated，稳定表面仅 `.md/.txt`。
- 静态 Web 与 Flutter Workbench 不展示 parser/OCR runtime 执行控件。
- Flutter 以 dashboard summary cards、边界 callout、data table、backend detail panels 与 audit evidence rows 展示矩阵。

### 任务进度

展示导入、复核、导出任务的阶段状态和进度。

模拟数据源：`jobs.json`。

### 知识库列表

展示多个知识库，包括草稿与可信状态、绑定 Agent、回答策略和分片数量。

模拟数据源：`knowledge_bases.json`、`agents.json`。

### 知识库详情

展示单个知识库契约，包括文档数、分片数、可信状态、解析后端、回答策略和绑定 Agent。

模拟数据源：`knowledge_bases.json`、`agents.json`。

### 复核队列

展示带风险标签的复核项，包括来源、原因、状态和负责人。

模拟数据源：`review_queue.json`、`knowledge_bases.json`。

### 校正文稿编辑器

展示校正文稿模拟编辑器和复核动作。编辑器不写入运行时状态。

模拟数据源：`review_queue.json`。

### 知识库查询

展示模拟证据查询回答、引用标签和回答策略上下文。

模拟数据源：`knowledge_bases.json`、`answer_policies.json`。

### 文档生成

展示生成文档草稿、引用数量、Agent 归属和预览/导出就绪状态。

模拟数据源：`generated_docs.json`、`agents.json`、`knowledge_bases.json`。

### Agent / Skill 管理

展示 Agent 状态、模型供应商、工具、知识库绑定、回答策略和私有记忆范围。

模拟数据源：`agents.json`、`knowledge_bases.json`、`provider_status.json`。

### 多 Agent 工作流

展示工作流步骤、工作流共享记忆、参与 Agent 和交接链路。

模拟数据源：`workflows.json`、`agents.json`、`memory_scopes.json`。

### 记忆范围查看器

展示 Agent 私有记忆和工作流共享记忆隔离。

模拟数据源：`memory_scopes.json`、`agents.json`、`workflows.json`。

### 设置

展示供应商状态、解析后端状态、回答策略和记忆策略的模拟配置。

模拟数据源：`provider_status.json`、`parser_backend_status.json`、`parser_backends/parser_backend_matrix.json`、`answer_policies.json`。

### 导出中心

展示导出包项目和生成文档导出项。

模拟数据源：`generated_docs.json`。

## 模拟数据契约

UI 只消费以下文件：

- `knowledge_bases.json`
- `agents.json`
- `workflows.json`
- `memory_scopes.json`
- `jobs.json`
- `review_queue.json`
- `generated_docs.json`
- `provider_status.json`
- `parser_backend_status.json`
- `parser_backends/parser_backend_matrix.json`
- `answer_policies.json`

必须覆盖：

- 多个知识库，包含 `draft` 和 `trusted` 状态。
- 多个 Agent，并包含 Agent 到知识库绑定。
- 不同模型供应商和供应商状态。
- 回答策略模式。
- 从 Core v4.1.0 evidence 派生的解析后端状态，包括安装模式、稳定表面、证据路径、已知限制，以及不声明静态可执行。
- 复核队列风险。
- 生成文档和导出项。
- 多 Agent 工作流、工作流共享记忆、交接链路。
- Agent 私有记忆隔离。

## 未来 API 集成

`web/workbench/src/mockService.js` 是预留服务边界。未来 Core 集成应以 API 调用替换 JSON fetch，并返回相同视图模型字段：

- `knowledgeBases`
- `agents`
- `workflows`
- `memoryScopes`
- `jobs`
- `reviewItems`
- `generatedDocs`
- `exportItems`
- `providers`
- `parserBackends`
- `parserBackendMatrix`
- `answerPolicies`
- `memoryPolicies`

页面不得直接导入解析、RAG、文档生成、Agent 编排或记忆运行时模块。
