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
- 知识资产质量报告 `quality_report.json`
- `ingest_report.md` 中的 Quality Summary
- 文本型 PDF 优先直接解析；扫描版 PDF / 图片型 PDF 在文本抽取为空或过短时进入 OCR fallback
- DOCX 仅支持文本抽取
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
- 不做 Agent Template。
- PDF / DOCX 内嵌表格抽取放到 v0.4.3。

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
- 不做 PDF / DOCX 内嵌表格抽取。
- 不做图片表格 OCR。
- 不做扫描表格结构识别。
- 不做公式计算。
- 不做复杂数据分析。
- 不接 LLM。
- 不接向量库。
- PDF / DOCX 内嵌表格抽取放到 v0.4.3。
- LLM 结构化抽取放到 v0.5.0。

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

v0.3.1 仍然是离线规则版本：

- 不接 OCR
- 不接 LLM
- 不接向量库
- 不做 Agent Template
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
- DOCX 仅支持文本抽取
- 图片 OCR 仅支持 PNG、JPG、JPEG
- 表格文件仅支持 CSV、TSV、XLSX
- 不支持图片内容解析
- 不支持复杂表格结构还原

## License

MIT License. See LICENSE for details.
