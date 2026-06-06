# 外部能力项目接入清单

## 接入原则

HeiTang Knowledge Workbench 不从零自研所有能力。

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

## 6. 接入优先级

第一优先级：

- Docling
- Marker

第二优先级：

- LlamaIndex
- RAGAS
- Qdrant

第三优先级：

- python-docx
- python-pptx
- WeasyPrint

第四优先级：

- LangGraph
- langgraph-supervisor

第五优先级：

- Mem0
- Zep / Graphiti

第六优先级：

- MinerU
- PaddleOCR
- Surya
- Unstructured
- Haystack
- AutoGen
