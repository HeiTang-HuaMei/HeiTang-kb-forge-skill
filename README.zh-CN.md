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
- PDF/DOCX 仅支持文本抽取
- 不支持 OCR、图片内容解析、复杂表格结构还原
- 检查空 chunk、重复 chunk、缺失字段

## 安装方式

```bash
cd HeiTang-kb-forge-skill
python -m venv .venv
.venv\Scripts\activate
pip install -e ".[dev]"
```

macOS 或 Linux 使用：

```bash
source .venv/bin/activate
```

## 使用方式

将 `.md`、`.txt`、文本型 `.pdf` 或文本型 `.docx` 文件放入 `examples/input`，然后运行：

```bash
heitang-kb-forge build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

也可以直接通过 Python module 运行：

```bash
python -m heitang_kb_forge.cli build --input ./examples/input --output ./examples/output --domain education --mode teaching
```

## 输出文件说明

输出目录会生成：

- `chunks.jsonl`：清洗和切片后的文本块，包含稳定 ID 与来源信息
- `cards.jsonl`：由 chunk 派生的基础知识卡片
- `qa_pairs.jsonl`：由 chunk 派生的确定性问答对
- `glossary.jsonl`：从文本中识别出的简单术语候选
- `manifest.json`：知识库包元数据与统计信息
- `ingest_report.md`：可读的导入报告与告警信息

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
- PDF/DOCX 仅支持文本抽取
- 不支持 OCR
- 不支持图片内容解析
- 不支持复杂表格结构还原

## License

MIT License. See LICENSE for details.
