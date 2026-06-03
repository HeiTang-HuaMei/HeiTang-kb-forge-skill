# HeiTang KB Forge Skill

中文说明 | [English](README.md)

## 项目简介

`heitang-kb-forge-skill` 是一个本地命令行工具，用于从源文档生成标准化知识库包。

本项目保持离线运行：不提供 Web UI，不连接向量数据库，也不调用外部 LLM。

## 功能特性

- Python 3.11+
- Typer CLI
- Pydantic schema
- UTF-8 输出
- 稳定、可复现的 `chunk_id`
- 支持 Markdown、TXT、文本型 PDF、文本型 DOCX
- 可选图片 OCR 支持
- 支持 PNG、JPG、JPEG
- 可选扫描 PDF OCR fallback
- CSV / TSV / XLSX 结构化表格文件接入
- DOCX 内嵌表格抽取
- 可选 LLM 结构化抽取
- 可选 RAG 导出层
- 可选 Agent Template 生成
- Demo / Eval 报告
- 作品集 Demo 包
- 配置文件驱动执行
- Pipeline 一键工作流
- Runtime Connector Pack，用于 LLM / embedding / vector export 配置输出
- 文本型 PDF 表格抽取
- 扫描 PDF / 图片 OCR 表格 best-effort 抽取
- 可选 package validation / readiness report
- 可选下游导出格式
- 可选真实 provider validation 入口
- 知识资产质量报告 `quality_report.json`
- `ingest_report.md` 中的 Quality Summary
- 文本型 PDF 优先直接解析；扫描版 PDF / 图片型 PDF 在文本抽取为空或过短时进入 OCR fallback
- DOCX 支持段落文本抽取和内嵌表格抽取
- 不支持图片语义理解、版面还原、复杂表格结构还原
- 检查空 chunk、重复 chunk、缺失字段

## 安装方式

```bash
cd HeiTang-kb-forge-skill
python -m venv .venv
.venv\Scripts\activate
pip install -e ".[dev]"
```

安装可选图片 OCR 支持和扫描 PDF OCR fallback：

```bash
pip install -e ".[ocr]"
```

OCR extra 包含 `pytesseract`、`Pillow`、`pypdfium2`。本机可能仍需安装 Tesseract binary。

XLSX 支持使用 `openpyxl`，它是默认依赖。

安装可选文本型 PDF 表格抽取支持：

```bash
pip install -e ".[pdf-table]"
```

macOS 或 Linux 使用：

```bash
source .venv/bin/activate
```

## 使用方式

将 `.md`、`.txt`、`.pdf`、文本型 `.docx`、`.png`、`.jpg`、`.jpeg`、`.csv`、`.tsv` 或 `.xlsx` 文件放入 `examples/input`，然后运行：

```bash
heitang-kb-forge build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

也可以直接通过 Python module 运行：

```bash
python -m heitang_kb_forge.cli build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

## 图片 OCR

v0.4.0 新增图片 OCR 接入能力，支持 `.png`、`.jpg`、`.jpeg` 文件。

OCR 只负责从图片中提取文字，提取出的文本继续进入现有清洗、切块、知识资产抽取和质量评估流程。OCR 依赖是可选安装；未安装 OCR 依赖时，已有 Markdown、TXT、文本型 PDF、文本型 DOCX 工作流不受影响。

## 扫描 PDF OCR

v0.4.1 新增扫描 PDF OCR fallback。

text-based PDF 仍然优先直接解析。只有当 PDF 文本抽取为空或过短时，才触发 OCR fallback。OCR 后文本继续进入清洗、切块、知识资产抽取和质量评估流程。页面文本会用 `[Page 1]` / `[Page 2]` 标记拼接。

PDF OCR 使用可选 OCR 依赖：

- `pytesseract`
- `Pillow`
- `pypdfium2`

本机可能仍需安装 Tesseract binary。

OCR 边界：

- 不做表格结构识别。
- 不做版面还原。
- 不做 OCR 纠错。
- 不接 LLM。
- 不接向量库。
- OCR 能力本身不生成 Agent Template。
- v0.4.3 不做 PDF 表格抽取。

## 表格文件接入

v0.4.2 新增 CSV / TSV / XLSX 结构化表格文件接入。

表格 parser 会把结构化表格的行列数据转换成可读文本。转换后的文本继续进入清洗、切块、知识资产抽取、质量评估流程。

表格解析行为：

- CSV / TSV 使用 `utf-8-sig` 读取。
- XLSX 支持多 sheet。
- 空行会跳过。
- 默认第一行作为表头。
- 空表头会转换为 `Column A`、`Column B`。
- 重复表头会自动加后缀，例如 `Name 2`。

CSV 行：

```text
书名,作者,ISBN,定价
产品经理入门,张三,123456,59
```

转换文本：

```text
Row 2. 书名: 产品经理入门. 作者: 张三. ISBN: 123456. 定价: 59.
```

XLSX 转换文本：

```text
Sheet: 商品列表. Row 2. 书名: 产品经理入门. 作者: 张三.
```

表格接入边界：

- 不支持 `.xls`。
- 不做 PDF 内嵌表格抽取。
- 不做图片表格 OCR。
- 不做扫描表格结构识别。
- 不做公式计算。
- 不做复杂数据分析。
- 不接 LLM。
- 不接向量库。

## DOCX 内嵌表格抽取

v0.4.3 新增 DOCX 内嵌表格抽取，同时保留原有段落文本抽取。

DOCX 表格行会转换成可读文本，并继续进入清洗、切块、知识资产抽取、质量评估流程。

转换示例：

```text
Table 1. Row 2. 字段A: 值A. 字段B: 值B.
```

边界：

- 不做合并单元格结构语义还原。
- v0.4.3 不做 PDF 表格抽取。
- 不做图片表格 OCR。
- 不做扫描表格结构识别。

## LLM 结构化抽取

v0.5.0 新增可选 LLM 结构化抽取。LLM 默认关闭，只有显式传入 `--llm` 才会启用。

LLM 是增强层，不是唯一生产路径。不启用 `--llm` 时，离线 7 文件输出保持不变。启用后，LLM 输出是额外文件，不覆盖离线 `cards.jsonl`、`qa_pairs.jsonl`、`glossary.jsonl`。

命令示例：

```bash
heitang-kb-forge build --input ./input.md --output ./output --llm --llm-provider fake --llm-model fake-model
```

fake provider 可用于本地测试，不真实联网。

启用 `--llm` 后会额外生成：

- `llm_cards.jsonl`
- `llm_qa_pairs.jsonl`
- `llm_glossary.jsonl`
- `frameworks.jsonl`
- `case_cards.jsonl`
- `metrics.jsonl`

LLM 记录包含：

- `source_path`
- `chunk_id`
- `citation`
- `confidence`
- `llm_provider`
- `llm_model`
- `token_usage`
- `cache_key`

LLM 失败策略：

- 默认 fallback，不影响离线构建成功。
- `--llm-strict` 下，当前 build / batch item / merge group 失败。

安全边界：

- 不把 API key 写入输出文件、cache、report。
- 测试只使用 fake provider，不真实联网。

当前不做：

- 向量库。
- Web UI。

## RAG 导出

v0.6.0 新增可选 RAG 导出层，通过 `--rag-export` 开启。

RAG 导出只生成供后续 embedding pipeline、向量库导入脚本、检索系统、RAG Agent 使用的 provider-neutral 中间文件。它不调用 embedding API，不生成真实向量，也不写入 FAISS / Qdrant / Chroma / Milvus。

命令示例：

```bash
heitang-kb-forge build --input ./input.md --output ./output --rag-export
```

启用 `--rag-export` 后会额外生成：

- `embedding_input.jsonl`
- `retrieval_metadata.jsonl`
- `citation_map.json`
- `rag_manifest.json`

只有同时启用以下三个参数时，RAG 导出才会包含 LLM 增强资产：

```bash
heitang-kb-forge build --input ./input.md --output ./output --llm --rag-export --rag-include-llm
```

RAG 边界：

- 不接真实向量库。
- 不调用 embedding API。
- 不生成真实向量。
- 不做 RAG Agent 运行时。

## Agent Template 生成

v0.7.0 新增可选 Agent Template 生成，通过 `--agent-template` 开启。

Agent Template 生成只写出模板文件，不创建真实在线 Agent，不部署服务，不调用外部 Agent 平台，也不执行工具。

命令示例：

```bash
heitang-kb-forge build --input ./input.md --output ./output --agent-template --agent-type product_manager_agent
```

启用 `--agent-template` 后会额外生成：

- `agent_profile.yaml`
- `system_prompt.md`
- `retrieval_config.yaml`
- `tools.yaml`
- `eval_cases.jsonl`

支持的 `agent_type`：

- `generic_agent`
- `product_manager_agent`
- `shopping_guide_agent`
- `education_tutor_agent`
- `customer_service_agent`
- `interview_coach_agent`
- `operations_agent`
- `book_marketing_agent`
- `publisher_sales_agent`
- `enterprise_kb_agent`

Agent Template 边界：

- 不部署真实 Agent。
- 不调用外部 Agent 平台。
- 不做工具执行。
- 不做 Web UI。
- Agent 类型后续可继续扩展。

## Demo / Eval 报告

v0.8.0 新增 Demo / Eval 报告，用于帮助判断知识包是否具备展示、RAG 接入、Agent Template 接入准备度。

通过 `--demo-report` 开启：

```powershell
heitang-kb-forge build --input .\examples\demo_product_manager_agent\input --output .\examples\demo_product_manager_agent\output --rag-export --agent-template --demo-report
```

启用后会额外生成：

- `demo_report.md`
- `demo_manifest.json`
- `eval_summary.json`

状态分级：

- `pass`
- `warning`
- `fail`

## 作品集 Demo 包

v0.8.1 新增作品集 Demo 包：

- `examples/demo_product_manager_agent`
- `examples/demo_shopping_guide_agent`
- `examples/demo_education_tutor_agent`

每个 demo 都包含 `output_sample`。这些 demo 用于展示产品经理、购物导购、教育陪练等 Agent 知识资产生产场景。它们是知识资产和模板示例，不是真实部署的在线 Agent。

## 配置文件驱动执行

v0.8.2 新增配置文件驱动执行能力，通过 `run --config` 使用。

支持 `.yaml` / `.yml` 配置文件。示例配置：

- `examples/configs/kb_forge.build.yaml`
- `examples/configs/kb_forge.batch.yaml`

配置文件可以减少长 CLI 参数输入，并驱动 build、batch、同序号合并、LLM、RAG、Agent Template、Demo Report。

PowerShell 示例：

```powershell
heitang-kb-forge run --config .\examples\configs\kb_forge.build.yaml
```

```powershell
python -m heitang_kb_forge.cli run --config .\examples\configs\kb_forge.build.yaml
```

`examples/prompt_profiles` 是后续 Prompt Profile 接入的准备样例，目前尚未接入 LLM extractor。

## Pipeline 一键工作流

v0.8.3 新增 Pipeline 一键工作流，通过 `pipeline --config` 使用。

它在 `run --config` 基础上增加 pipeline 级报告，用于展示完整链路：

原始资料 -> 知识库生产 -> 质量报告 -> RAG 导出 -> Agent Template -> Demo Report -> Pipeline Report

PowerShell 示例：

```powershell
heitang-kb-forge pipeline --config .\examples\configs\kb_forge.build.yaml
```

启用后会额外生成：

- `pipeline_report.md`
- `pipeline_manifest.json`

Pipeline 报告会展示 source ingestion、knowledge package、quality report、LLM extraction、RAG export、Agent Template、Demo Report 等阶段状态。

Pipeline 边界：

- 不做 Web UI。
- 不做复杂 DAG。
- 不做调度器。
- 不做后台队列。
- 不做真实 Agent 部署。
- 不写入真实向量库。
- 不做远程执行。

## Runtime Connector Pack

v0.9.0 新增 Runtime Connector Pack，用于为下游运行时准备连接器配置和标准输出。

它包括：

- OpenAI-compatible LLM provider readiness skeleton。
- fake / OpenAI-compatible embedding provider 接口。
- local JSON vector export。
- Agent Template 中增强版 `tools.yaml` 配置。

这些能力只生成配置和中间文件，不把本项目变成 Agent Runtime 或 Tool Runtime。默认测试仍使用 fake/local provider，不访问外部服务。

## v1.0.0 稳定版能力

v1.0.0 将项目收口为 Agent 知识供应链底座，同时保持默认离线 7 文件输出不变。

新增稳定版能力：

- 文本型 PDF 表格抽取，可选依赖 `pdfplumber`。
- 扫描 PDF 页面和图片中的 OCR 表格 best-effort 抽取。
- 可选 package validation，输出 readiness 和 hallucination risk 信号。
- 可选下游导出格式，支持 LangChain / LlamaIndex / generic RAG package 中间文件。
- 新增图书营销、出版社销售、企业知识库 Agent Template。
- 可选真实 provider validation 入口，默认关闭，且不得泄露 API key。

### PDF / OCR 表格抽取

文本型 PDF 表格会转换成可读文本，例如：

```text
Page 1. Table 1. Row 2. 字段A: 值A. 字段B: 值B.
```

扫描 PDF 和图片 OCR 表格抽取是 best-effort：优先使用 OCR word boxes 聚合行列；如果结构化失败，则 fallback 到普通 OCR 文本。

边界：

- 不做 PDF 复杂版面完美还原。
- 不做跨页表格合并。
- 不引入深度学习表格识别模型。
- 不做公式计算。
- 不做 OCR 纠错。

### Package Validation

通过以下参数开启：

```bash
heitang-kb-forge build --input ./input.md --output ./output --validate-package
```

额外输出：

- `package_validation_report.json`
- `package_readiness_report.md`

报告会检查标准输出文件、coverage 信号、warning、readiness level 和 hallucination risk 字段。

### 下游导出

通过以下参数开启：

```bash
heitang-kb-forge build --input ./input.md --output ./output --downstream-export
```

额外输出：

- `langchain_documents.jsonl`
- `llamaindex_documents.jsonl`
- `generic_rag_package.json`
- `openai_files_manifest.json`

这些文件是 provider-neutral 的中间格式。本项目不调用 LangChain、LlamaIndex、OpenAI 上传 API、Dify、FastGPT 或 Coze。

### 可选真实 Provider Validation

真实 provider validation 默认关闭，默认测试不联网。

环境变量：

- `HEITANG_RUN_LIVE_TESTS=1`
- `HEITANG_LLM_API_KEY`
- `HEITANG_LLM_BASE_URL`
- `HEITANG_LLM_MODEL`
- `HEITANG_EMBEDDING_API_KEY`
- `HEITANG_EMBEDDING_BASE_URL`
- `HEITANG_EMBEDDING_MODEL`

输出报告不得写入 API key。

## 输出文件说明

输出目录会生成：

- `chunks.jsonl`：清洗和切片后的文本块，包含稳定 ID 与来源信息
- `cards.jsonl`：由 chunk 派生的基础知识卡片
- `qa_pairs.jsonl`：由 chunk 派生的确定性问答对
- `glossary.jsonl`：从文本中识别出的简单术语候选
- `manifest.json`：知识库包元数据与统计信息
- `ingest_report.md`：可读的导入报告与告警信息
- `quality_report.json`：机器可读的知识资产质量报告

## 知识资产质量报告

v0.3.1 新增 `quality_report.json`，用于对每个知识库包进行机器可读的质量评估；同时 `ingest_report.md` 增加 Quality Summary，方便人工快速查看质量摘要。

`quality_report.json` 包含：

- `source_count`
- `chunk_count`
- `card_count`
- `qa_count`
- `glossary_count`
- empty counts
- duplicate counts
- `citation_coverage`
- `source_path_coverage`
- `quality_score`
- `quality_level`

`quality_level` 包括：

- `excellent`
- `good`
- `fair`
- `poor`

v0.3.1 的定位是让知识库包从“能生成”进一步升级为“可评估”，为后续 RAG 导出、Agent Template、LLM 结构化抽取打基础。

v0.3.1 当时仍然是离线规则版本：

- 不接 OCR
- 不接 LLM
- 不接向量库
- 不做 Agent Template 生成
- 不做 Web UI
- 不改变 `build` / `batch` / `--merge-same-sequence` CLI 行为

## 验证与测试

validator 会检查：

- 空 chunk
- 重复 chunk
- 缺失必需字段
- Pydantic schema 有效性

运行测试：

```bash
pytest
```

## 已知边界

- 不提供 Web UI
- 不连接向量数据库
- 不调用外部 LLM
- 文本型 PDF 优先直接解析，扫描版 PDF / 图片型 PDF 可在 OCR extra 可用时 fallback 到 OCR
- DOCX 支持段落文本抽取和内嵌表格抽取
- 图片 OCR 仅支持 PNG、JPG、JPEG
- 表格文件仅支持 CSV、TSV、XLSX
- 不支持图片内容解析
- 不支持复杂表格结构还原
- 不做复杂 DAG
- 不做调度器
- 不做后台队列
- 不做真实 Agent 部署
- 不写入真实向量库
- 不做远程执行

## License

MIT License. See LICENSE for details.
