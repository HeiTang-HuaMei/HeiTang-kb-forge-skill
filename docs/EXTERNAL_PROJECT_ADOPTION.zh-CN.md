# 外部能力项目接入清单

## 接入原则

HeiTang Knowledge Workbench 不从零自研所有能力。

当前登记口径：

- 高价值：登记 + POC + 接入候选。仅当项目能明显补主链路短板、增强核心能力、节省 token / 成本，或提升工业级稳定性时进入。
- 中价值：登记 + 观察 + 架构参考。仅作为未来 Provider / Adapter 候选或产品方向参考，当前不是 blocker。
- 低价值：不登记到项目清单；可暂存为灵感，但不进入接入路线。

真实接入范围：

- 只接入高价值项目。
- 高价值项目也必须先 POC，再 Provider / Adapter 化，再进入主链路配置。
- 中价值项目不得写成已接入、默认依赖、runtime ready 或主链路 blocker。
- `pi-mono` 作为特殊项保留登记：中价值 / Agent runtime reference / 暂不接入。

接入策略：

- KB Forge Core 负责标准知识资产包、证据边界、质量门禁和复核流程。
- 外部项目作为 optional backend。
- 不复制外部项目源码。
- 不把外部输出直接视为可信知识。
- 所有输出必须归一化为 KB Forge contract。
- 必须保留 backend name / version / command / source path / confidence / warning。

## 1. 文档解析 / OCR / 结构化

### Docling

GitHub: https://github.com/docling-project/docling

用途：

- PDF / Office / HTML 等多格式文档解析。
- advanced PDF understanding。
- 输出适合 GenAI/RAG 的结构化内容。

接入版本：

- v2.8

### Marker

GitHub: https://github.com/datalab-to/marker

用途：

- PDF / image / PPTX / DOCX / XLSX / HTML / EPUB 转 Markdown / JSON / chunks / HTML。
- 表格、公式、图片提取。
- 可选 LLM 提升准确率。

接入版本：

- v2.8

### MinerU

GitHub: https://github.com/opendatalab/MinerU

用途：

- PDF / image / DOCX / PPTX / XLSX 转 Markdown / JSON。
- 复杂文档、科研文档、公式密集文档。

接入版本：

- v2.8 后续增强或 v3.4 backend hardening

### PaddleOCR

GitHub: https://github.com/PaddlePaddle/PaddleOCR

用途：

- 中文 OCR。
- 文档结构化。
- 扫描件、图片、表格识别。

接入版本：

- v3.4 optional backend hardening

### Surya

GitHub: https://github.com/datalab-to/surya

用途：

- OCR。
- layout analysis。
- reading order。
- table r
ecognition。

接入版本：

- v3.4 optional backend hardening

### Unstructured

GitHub: https://github.com/Unstructured-IO/unstructured

用途：

- 企业文档 ingestion / preprocessing。
- 文档 partition。
- 通用 fallback parser。

接入版本：

- v3.4 optional backend hardening

## 2. 知识库检索 / RAG / 评测

### LlamaIndex

GitHub: https://github.com/run-llama/llama_index

用途：

- 数据连接。
- 索引。
- query engine。
- chat engine。
- RAG / Agent 应用。

接入版本：

- v2.9

### Haystack

GitHub: https://github.com/deepset-ai/haystack

用途：

- RAG pipeline。
- retrieval / routing / memory / generation。
- Agent workflow。

接入版本：

- v2.9 后续可选 backend

### Qdrant

GitHub: https://github.com/qdrant/qdrant

用途：

- 向量检索。
- 多知识库检索。
- tenant / namespace 隔离。

接入版本：

- v2.9 或 v3.2

### RAGAS

GitHub: https://github.com/explodinggradients/ragas

用途：

- RAG 自动评测。
- faithfulness。
- context precision / recall。
- answer relevancy。

接入版本：

- v2.9

### DeepEval

GitHub: https://github.com/confident-ai/deepeval

用途：

- LLM / RAG / Agent evaluation。
- Agent / Skill validation。

接入版本：

- v2.9 / v3.1

## 3. 多 Agent 编排

### LangGraph

GitHub: https://github.com/langchain-ai/langgraph

用途：

- stateful agent orchestration。
- long-running agents。
- workflow graph。
- checkpointer / store。

接入版本：

- v3.2

### LangGraph Supervisor

GitHub: https://github.com/langchain-ai/langgraph-supervisor-py

用途：

- supervisor agent。
- multi-agent handoff。
- short-term / long-term memory 接入。

接入版本：

- v3.2

### AutoGen

GitHub: https://github.com/microsoft/autogen

用途：

- multi-agent conversation。
- human-in-the-loop。
- tool use。
- AutoGen Studio 对标。

接入版本：

- v3.2 对标，不作为首选内嵌依赖。

## 4. Agent 记忆

### Mem0

GitHub: https://github.com/mem0ai/mem0

用途：

- Agent persistent memory。
- 用户偏好。
- 个性化记忆。

接入规则：

- optional。
- 必须 namespace 隔离。
- agent_id / workspace_id 必填。

接入版本：

- v3.4

### Zep / Graphiti

GitHub:

- https://github.com/getzep/zep
- https://github.com/getzep/graphiti

用途：

- temporal knowledge graph memory。
- relationship-aware context。
- dynamic state over time。

接入规则：

- optional。
- 不进入默认本地最小安装。
- 适合长期增强。

接入版本：

- v3.4 或 v4.0

## 5. 文档生成

### python-docx

GitHub: https://github.com/python-openxml/python-docx

用途：

- Word docx 生成。

接入版本：

- v3.0

### python-pptx

GitHub: https://github.com/scanny/python-pptx

用途：

- PPTX 生成。

接入版本：

- v3.0

### WeasyPrint

GitHub: https://github.com/Kozea/WeasyPrint

用途：

- HTML / CSS 转 PDF。

接入版本：

- v3.0

## 6. 当前登记分层

### 高价值：登记 + 优先 POC / 接入候选

| 项目 | 价值 |
| --- | --- |
| OpenDataLoader PDF | 补 PDF 解析质量，直接影响导入 / 文档库 / 知识库 |
| Marker | 多格式转 Markdown / JSON / chunks，补解析能力 |
| Docling | 企业文档解析，补 Parser / OCR / 结构化 |
| Sirchmunk | 原始文件直搜，降低向量库 / embedding 依赖，节省成本 |
| Graphify | 图谱索引，减少反复读全仓 / 全文，增强结构理解 |
| GBrain | 记忆生命周期、编译真相、时间线证据，补长期知识治理 |
| Qdrant | 向量索引基础设施，已在路径内 |
| RAGAS | RAG 质量评测，补验收指标 |
| DeepEval | Agent / RAG 评测，补质量门禁 |
| Redis | 缓存 / 状态 / 任务记忆，提升性能和稳定性 |

### 中价值：只登记，不急接入

| 项目 | 价值 |
| --- | --- |
| WeKnora | RAG + Agent + Auto-Wiki 架构参考，整包接入成本高 |
| LLM Wiki v2 | 知识生命周期范式，和 GBrain / OKF 一起做架构参考 |
| LlamaIndex | RAG pipeline 参考 / 可选 backend |
| Haystack | RAG / Agent pipeline 参考 / 可选 backend |
| LangGraph | 编排层参考，未来 Agent Orchestrator 可选 |
| Mem0 | Agent 记忆参考，后续可选 |
| Zep / Graphiti | 时序知识图谱记忆参考 |
| Horizon | 信息抓取 / 资料采集参考 |
| codebase-memory-mcp | 代码库记忆 / MCP 参考 |
| Presenton | PPT 生成参考 |
| drawio-generator | 图表生成 Skill 参考 |
| BestBlogs.dev | RSS / 信息源参考 |
| open-notebook | Notebook / 研究工作流参考 |
| pi-mono | Agent runtime reference，保留登记，暂不接入 |

### 剔除或暂不登记

| 项目 | 原因 |
| --- | --- |
| Nano_Banana_Pro_Web | 偏视频 / 图像生成，主链路弱相关 |
| NVlabs/LongLive | 视频生成，不是当前方向 |
| claude-plugins-official | 插件生态参考即可，不进入接入登记 |
| 随机 Skill 仓库 | 除非能明确增强主链路或节省 token |
