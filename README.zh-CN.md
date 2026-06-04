# HeiTang KB Forge Skill

中文说明 | [English](README.md)

## 项目简介

`heitang-kb-forge-skill` 是一个面向 Agent 构建的知识供应链底座。

它可以把 PDF、DOCX、Markdown、TXT、图片、扫描 PDF、表格等多格式资料，标准化加工成可追溯、可检索、可审计、可评估、可复用的知识资产包，并作为后续 RAG 系统、问答 Agent、导购 Agent、教育 Agent、产品经理 Agent、企业知识库 Agent 等下游 Agent 的前置知识底座。

项目默认离线运行。OCR、LLM 抽取、RAG 导出、Embedding / Vector Export、Agent Runtime MVP、Web UI、真实 provider validation、知识包运营治理等能力均为显式可选能力。

## Skill-first 架构

桌面 UI 不是项目核心，只是本地可视化入口。HeiTang KB Forge 的核心仍然是 Agent 知识供应链前置 Skill，可被 OpenClaw、Claude Code、Codex 或其他 Agent 框架调用。

架构优先级：

```text
Core Skill / Python package
> CLI
> Config / Pipeline
> Agent-callable skill interface
> Desktop UI
```

所有入口共享同一套标准知识包输出契约，不会为了 UI 改成桌面私有格式。

### Headless CLI 使用

```powershell
heitang-kb-forge build --input .\input --output .\output
python -m heitang_kb_forge.cli pipeline --config .\examples\configs\kb_forge.build.yaml
```

### Agent / Skill 调用

```text
Agent receives documents
-> calls heitang-kb-forge
-> gets standardized knowledge package
-> uses package for RAG / Q&A / planning / downstream export
```

OpenClaw、Claude Code、Codex、Generic Agent 和 MCP-ready 接入说明见 `docs/AGENT_INTEGRATION.md`。

后续 Skill 接口预留：

```text
skills/
  heitang-kb-forge-skill/
    SKILL.md
    skill.json
    examples/
    prompts/
```

### Desktop 表现层

```text
Desktop UI
-> calls Python CLI
-> produces the same standard package
```

桌面 UI 不承载核心业务逻辑，不替代 Python CLI，不生成只有 UI 能消费的私有数据格式。

## 这个项目做什么

HeiTang KB Forge 负责：

- 解析多格式源资料
- 生成标准知识资产包
- 保留 source_path、chunk_id、citation
- 生产确定性的本地知识资产
- 生成质量、风险、评估、readiness 文件
- 导出 RAG / Agent 可消费的中间格式
- 生成 Agent Template
- 支持本地知识包运营治理

## 这个项目不做什么

本项目不提供：

- Tool Runtime
- 真实业务系统集成
- CRM / 商品 / 订单系统调用
- 权限系统
- SaaS 多租户
- 生产级 Web 部署
- 真实发布 API 调用
- 复杂 Agent Planning 执行器

## 安装方式

PowerShell：

    cd HeiTang-kb-forge-skill
    python -m venv .venv
    .venv\Scripts\activate
    pip install -e ".[dev]"

安装 OCR extra：

    pip install -e ".[ocr]"

安装文本型 PDF 表格抽取 extra：

    pip install -e ".[pdf-table]"

安装 Web UI extra：

    pip install -e ".[web]"

安装完整本地 optional 能力：

    pip install -e ".[all]"

OCR 说明：`ocr` extra 只安装 Python 包。Tesseract OCR 本体是系统依赖，中文 OCR 需要 `chi_sim.traineddata`。

## Doctor 环境检查

检查安装和 optional 环境：

    python -m heitang_kb_forge.cli doctor --output .\doctor_out

`doctor` 会把基础 Skill 能力缺失标记为 fail，把 OCR / PDF table 等 optional 缺失标记为 warning。

## 快速使用

运行完整 quickstart：

    .\examples\quickstart\run_quickstart.ps1

生成知识包：

    heitang-kb-forge build --input .\examples\input --output .\examples\output --domain education --mode teaching

通过 Python module 运行：

    python -m heitang_kb_forge.cli build --input .\examples\input --output .\examples\output --domain education --mode teaching

## 标准输出文件

标准 build 会生成：

- `chunks.jsonl`
- `cards.jsonl`
- `qa_pairs.jsonl`
- `glossary.jsonl`
- `manifest.json`
- `ingest_report.md`
- `quality_report.json`

## 支持的输入格式

支持：

- Markdown
- TXT
- 文本型 PDF
- 文本型 DOCX
- PNG / JPG / JPEG OCR
- 扫描 PDF OCR fallback
- CSV / TSV / XLSX 结构化表格
- DOCX 内嵌表格
- 文本型 PDF 表格
- 扫描 PDF / 图片 OCR 表格 best-effort

## 常用命令示例

RAG 导出：

    heitang-kb-forge build --input .\input --output .\output --rag-export

Agent Template：

    heitang-kb-forge build --input .\input --output .\output --agent-template --agent-type product_manager_agent

Demo 报告：

    heitang-kb-forge build --input .\input --output .\output --rag-export --agent-template --demo-report

配置文件驱动：

    heitang-kb-forge run --config .\examples\configs\kb_forge.build.yaml

Pipeline 工作流：

    heitang-kb-forge pipeline --config .\examples\configs\kb_forge.build.yaml

最小 ask runtime：

    heitang-kb-forge ask --package .\examples\demo_product_manager_agent\output_sample --query "这个知识包适合做什么 Agent？"

知识包工作区 / 注册表：

    heitang-kb-forge workspace init --workspace .\workspace
    heitang-kb-forge workspace register --workspace .\workspace --package .\output_sample
    heitang-kb-forge workspace status --workspace .\workspace

刷新检测：

    heitang-kb-forge refresh-check --workspace .\workspace

人工审核 / 校正：

    heitang-kb-forge review-create --package .\output_sample --output .\review
    heitang-kb-forge review-apply --package .\output_sample --decisions .\review\review_decisions.jsonl --output .\curated_output

发布 profile：

    heitang-kb-forge publish --package .\output_sample --profile generic_rag --output .\publish_output

Agent Planning Readiness：

    heitang-kb-forge planning-readiness --package .\output_sample --output .\planning_output

质量门：

    heitang-kb-forge build --input .\input --output .\output --quality-gate
    heitang-kb-forge build --input .\input --output .\output --quality-gate-strict

运行追踪：

    heitang-kb-forge build --input .\input --output .\output --run-manifest

Batch hardening：

    heitang-kb-forge batch --input .\input --output .\output --continue-on-error --fail-fast

桌面工具：

    .\packaging\desktop\dev_tauri.ps1
    .\packaging\desktop\build_tauri.ps1

## 逻辑版本能力索引

本节按“预期未合并版本”的逻辑版本顺序记录能力。部分能力在实际开发中使用压缩 commit 合并实现，但文档中按逻辑版本单独列出，方便理解演进过程。

### v0.1.0 核心 CLI 底座

- Typer CLI
- 本地 build 命令
- 基础输入输出结构
- UTF-8 输出契约

### v0.2.0 确定性知识包

- deterministic chunk 生成
- 稳定 `chunk_id`
- 基础 cards / QA / glossary 输出
- manifest 与 ingest report

### v0.3.0 Batch / Merge 工作流

- batch processing
- 同序号 merge workflow
- 每个 item 独立输出知识包
- 默认离线包生成

### v0.3.1 质量报告

- `quality_report.json`
- `ingest_report.md` 中的 Quality Summary
- 空值 / 重复 / coverage 检查
- quality score 与 quality level

### v0.4.0 图片 OCR

- PNG / JPG / JPEG 可选 OCR
- OCR 文本进入标准 pipeline
- 不做图片语义理解

### v0.4.1 扫描 PDF OCR Fallback

- 扫描 PDF OCR fallback
- 文本型 PDF 优先直接解析
- PDF 文本为空或过短时触发 OCR

### v0.4.2 CSV / TSV / XLSX 表格接入

- 结构化表格文件解析
- XLSX 多 sheet
- 表头归一化
- 行转文本

### v0.4.3 DOCX 内嵌表格抽取

- DOCX 段落抽取
- DOCX 内嵌表格抽取
- 表格行转可读文本

### v0.4.3B PDF / OCR 表格抽取

- 文本型 PDF 表格抽取
- 扫描 PDF / 图片 OCR 表格 best-effort
- fallback-safe 表格抽取
- 不做完美版面还原

### v0.5.0 LLM 结构化抽取

- 可选 `--llm`
- fake provider 本地测试
- LLM cards / QA / glossary / frameworks / cases / metrics
- fallback / strict 模式

### v0.5.1 LLM Provider Readiness

- provider metadata
- token usage metadata
- cache key
- OpenAI-compatible provider skeleton

### v0.5.2 LLM Prompt Profile

- `--prompt-profile`
- prompt profile metadata
- prompt profile hash 进入 cache key
- config 支持 prompt profile

### v0.5.3 LLM 抽取质量评估

- `--llm-quality-report`
- `llm_quality_report.json`
- `llm_quality_summary.md`
- citation / metadata / duplicate / empty-output 检查

### v0.6.0 RAG 导出

- `--rag-export`
- `embedding_input.jsonl`
- `retrieval_metadata.jsonl`
- `citation_map.json`
- `rag_manifest.json`

### v0.6.1 Embedding Provider 适配

- `--embedding`
- fake embedding provider
- OpenAI-compatible embedding provider skeleton
- `embeddings.jsonl`
- `embedding_manifest.json`

### v0.6.2 Vector Export Adapter

- `--vector-export`
- `--vector-store`
- local JSON vector export
- `vector_store_records.jsonl`
- `vector_store_manifest.json`

### v0.7.0 Agent Template 生成

- `--agent-template`
- `agent_profile.yaml`
- `system_prompt.md`
- `retrieval_config.yaml`
- `tools.yaml`
- `eval_cases.jsonl`

### v0.7.1 更多 Agent Template

- `book_marketing_agent`
- `publisher_sales_agent`
- `enterprise_kb_agent`
- 扩展业务型 Agent Template

### v0.7.2 Agent Tool Config 标准化

- 增强 `tools.yaml`
- runtime_required / input_schema / output_schema
- placeholder tools
- 不执行工具

### v0.8.0 Demo / Eval 报告

- `--demo-report`
- `demo_report.md`
- `demo_manifest.json`
- `eval_summary.json`
- pass / warning / fail readiness status

### v0.8.1 作品集 Demo 包

- 产品经理 Agent d
emo
- 购物导购 Agent demo
- 教育陪练 Agent demo
- output samples

### v0.8.2 配置文件驱动执行

- `run --config`
- YAML / YML config
- build / batch / merge / LLM / RAG / Agent / Demo 映射

### v0.8.3 Pipeline 一键工作流

- `pipeline --config`
- `pipeline_report.md`
- `pipeline_manifest.json`
- stage status

### v0.9.0 Runtime Connector Pack

- LLM provider readiness
- embedding provider adaptation
- vector export adapter
- Agent tool config standardization
- 默认不做真实 runtime execution

### v1.0.0 Stable Agent Knowledge Supply Chain

- 输入覆盖补全
- PDF / OCR 表格抽取
- package validation / readiness report
- downstream export formats
- optional live provider validation
- 稳定 docs 与 smoke tests

### v1.1.0 Knowledge Runtime & Web MVP

- package versioning / diff
- incremental build / safe reuse
- chunk strategy profiles
- knowledge graph export
- retrieval eval dataset export
- risk labels
- minimal ask runtime
- optional Streamlit Web UI MVP

### v1.2.0 Knowledge Ops & Governance Platform

- 知识包工作区 / 注册表
- Refresh / Staleness Detection
- Human Review / Curation Loop
- Evaluation Dashboard Data
- Web UI Upgrade
- Publish / Export Profiles
- Agent Planning Readiness Pack

### v1.2.1 Industrial Hardening & Batch Quality

- `--quality-gate` 与 `--quality-gate-strict`
- package acceptance report
- 可选 run manifest 与 stage trace
- batch run summary、failed items、retry manifest
- source hash refresh detection
- batch fail-fast 与资源保护参数

### v1.2.2 Tauri Desktop Utility

- 可选 Tauri / React / TypeScript 桌面脚手架
- build、batch、pipeline 的本地 UI 封装
- Windows EXE 打包脚本
- 中英文 UI 文案
- 不使用 Electron
- 不调用云服务、向量数据库或外部 Agent 平台

### v1.2.3 Desktop UI Freeze & Future-Ready Layout

- 保持 Skill-first 架构
- 桌面 UI 冻结为 presentation layer
- 默认 zh-CN，支持 en-US 切换
- 默认暗夜黑白灰工业级工具风格
- 固定 11 个页面导航
- 预留 Knowledge Lifecycle、SQLite / Vector Store、Agent Connector、Retrieval Runtime
- 文档说明 tiger/cat 图标资产拆分

### v1.2.4 Desktop UI Polish

- 修复 TopBar、Sidebar、页面和 Settings 的全局语言联动
- 修复 Settings 中英文混杂
- 区分只读字段、可编辑字段和后续预留字段
- 优化 Dashboard、Build、Batch、Lifecycle、Ask、Publish、Planning、Settings 信息层级
- 保持 11 页 IA 不变
- 保持 Skill-first 边界和 headless CLI 使用方式

### v1.3.0 Knowledge Lifecycle Core

- 可选 source registry 和源文件变化检测
- lifecycle-check 命令用于比较当前资料和已有知识包
- incremental update report 记录 reused / rebuilt / removed / stale chunks
- update quality gate 和 quality regression report
- failed sources 与 retry manifest 输出
- lifecycle 配置块支持 `run --config` 和 `pipeline --config`

```powershell
heitang-kb-forge lifecycle-check --input .\sources --package .\output --output .\lifecycle_check
```

```powershell
heitang-kb-forge build --input .\sources --output .\output --lifecycle --update-mode incremental --missing-source-policy mark_stale
```

### v1.4.0 Local Knowledge Store

- 可选本地 SQLite 知识包索引
- 支持 package import 和 workspace sync
- 支持 package list、query、status 命令
- 支持导出 store index 供 Agent / 运维流程使用
- 标准知识包文件仍然是主输出契约

```powershell
heitang-kb-forge store init --db .\kb_forge_workspace.db
heitang-kb-forge store import-package --db .\kb_forge_workspace.db --package .\output_sample
heitang-kb-forge store export-index --db .\kb_forge_workspace.db --output .\store_export
```

### v1.5.0 Agent RAG Layer

- 支持基于知识包或 SQLite store 的本地 retrieve
- 支持带 citation-required 的本地 ask
- 输出 retrieval result、retrieval trace、citation trace 和 answer
- 支持 `agent_rag` 配置块和 pipeline stage
- 不调用 embedding API，不写入真实向量库

```powershell
heitang-kb-forge retrieve --package .\output --query "What is this package about?" --top-k 5 --output .\rag_run
```

```powershell
heitang-kb-forge ask --package .\output --query "What is this package about?" --citation-required --output .\ask_run
```

### v1.6.0 Agent Tool / MCP Interface

- 本地 Agent-callable tool registry
- 支持 tool export、list、describe、invoke 命令
- 支持 retrieve_knowledge 本地工具调用
- 支持 MCP readiness config 导出
- 不部署真实 Agent，不调用外部 Agent 平台

```powershell
heitang-kb-forge tools export --output .\tool_exports
heitang-kb-forge tools invoke --name retrieve_knowledge --input .\input.json --output .\tool_run
heitang-kb-forge mcp export-config --output .\mcp_config
```

## 当前边界

- 默认离线优先
- Web UI 是可选本地管理台
- live provider validation 显式开启，不进入默认测试
- 不做 Tool Runtime
- 不做真实业务系统集成
- 不调用 CRM / 商品 / 订单系统
- 不做权限系统
- 不做 SaaS 多租户
- 不调用真实发布 API

## License

MIT License. See LICENSE for details.


## v1.2 边界补充

- 不是 Tool Runtime
- 不是业务系统集成
- 不是权限系统
- 不是 SaaS 平台
- 不调用外部平台 API
