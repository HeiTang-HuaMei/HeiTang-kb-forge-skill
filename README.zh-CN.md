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

Agent Template 边界：

- 不部署真实 Agent。
- 不调用外部 Agent 平台。
- 不做工具执行。
- 不做 Web UI。
- Agent 类型后续可继续扩展。

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

## License

MIT License. See LICENSE for details.
