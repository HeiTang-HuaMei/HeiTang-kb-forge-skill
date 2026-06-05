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
- 为工业化本地任务提供进度事件和大文件 / OCR 性能报告
- 运行稳定版 Studio workflow、stable check、provider health、reliability score 和 release package snapshot

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

## v2.0 稳定版底座

v2.0 新增稳定版 Agent 知识供应链底座：

- `studio-run`：本地端到端 Studio 工作流
- `stable-check`：稳定版 workspace contract 检查
- `provider-health`：离线 provider registry 健康检查
- `reliability-score`：发布就绪评分
- `release-package`：本地发布快照
- `extension_readiness`：后续能力预留字段

PowerShell：

    python -m heitang_kb_forge.cli studio-run --input .\examples\quickstart\input --workspace .\tmp_v20_workspace --project-name demo_project --profile stable
    python -m heitang_kb_forge.cli stable-check --workspace .\tmp_v20_workspace
    python -m heitang_kb_forge.cli provider-health --workspace .\tmp_v20_workspace
    python -m heitang_kb_forge.cli reliability-score --workspace .\tmp_v20_workspace
    python -m heitang_kb_forge.cli release-package --workspace .\tmp_v20_workspace --output .\tmp_v20_release

v2.0 不实现母版 Skill 拆解学习，也不实现平台上传。母版 Skill 拆解学习预留到 v2.2，平台导出和上传适配预留到 v2.4。

## v2.1 知识底座补强

v2.1 新增 opt-in 知识底座补强能力：

- 输入覆盖和增强 source inventory
- 轻量 HTML / EPUB / ZIP 文本接入
- parser hardening reports
- 规则型知识质量评分
- review workflow 和 curated chunks
- retrieval evaluation cases / results
- evidence benchmark reports
- 可选 mock/fallback LLM quality assist

PowerShell：

    python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_v21_package --contract-version v2 --check-contract --quality-score --retrieval-eval --evidence-benchmark
    python -m heitang_kb_forge.cli quality-score --package .\tmp_v21_package --output .\tmp_v21_quality
    python -m heitang_kb_forge.cli review-workflow --package .\tmp_v21_package --output .\tmp_v21_review
    python -m heitang_kb_forge.cli retrieval-eval --package .\tmp_v21_package --output .\tmp_v21_retrieval_eval
    python -m heitang_kb_forge.cli evidence-benchmark --package .\tmp_v21_package --output .\tmp_v21_evidence_benchmark

LLM quality assist 是可选辅助，不替代证据链，也不替代人工复核。

## v2.2 母版 Skill 拆解学习

v2.2 新增 opt-in 母版 Skill 拆解学习：

- `import-skill` 生成 `master_skill_inventory.json`
- `analyze-skill` 生成 decomposition、capability、workflow、style、strategy、task pattern、boundary 和 prompt pattern profiles
- `generate-derived-skill` 基于学习到的结构和用户自己的知识包生成新 Skill
- `skill-safety-check` 检查危险本地模式
- `skill-similarity-check` 写出派生相似度报告

PowerShell：

    python -m heitang_kb_forge.cli import-skill --input .\master_skills\sample --output .\tmp_v22_master_import
    python -m heitang_kb_forge.cli analyze-skill --skill .\master_skills\sample --output .\tmp_v22_skill_analysis
    python -m heitang_kb_forge.cli generate-derived-skill --master-skill .\tmp_v22_skill_analysis --knowledge-package .\tmp_v21_package --output .\tmp_v22_derived_skill

母版 Skill 学习只学习结构、工作流、风格和边界，不能把第三方 Skill 内容复制成用户自己的知识范围。

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

## v1.6 真实资料接入收口

v1.6 收口真实资料接入层：进度与大文件 / OCR 性能、多模态知识资产、Contract v2、contract checker，以及最小 Knowledge Package Builder UI v1。

启用多模态与 Contract v2：

    heitang-kb-forge build --input .\examples\quickstart\input --output .\tmp_v16_verify --profile fast --progress-jsonl --multimodal --contract-version v2 --check-contract

检查知识包契约：

    heitang-kb-forge check-contract --package .\tmp_v16_verify --contract-version v2

多模态输出：

- `multimodal_assets.jsonl`
- `multimodal_evidence_map.json`
- `multimodal_report.md`
- 成功抽取 slide 文本时生成 `slide_chunks.jsonl`

Contract v2 输出：

- `evidence_map.json`
- `source_inventory.json`
- `quality_report.md`
- `contract_check_result.json`
- `contract_check_report.md`

多模态抽取是 bounded best-effort。图片、图表、流程图、思维导图、slide、公式类资料在无法可靠抽取时也会被保留为可复核资产。低置信或 fallback asset 会标记 `review_required: true`。

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

进度与大文件性能：

    heitang-kb-forge build --input .\input --output .\output --progress --progress-jsonl --profile fast --ocr-mode first-pages --max-ocr-pages 10 --ocr-cache --resume

Pipeline 进度：

    heitang-kb-forge pipeline --config .\examples\configs\kb_forge.build.yaml --progress-jsonl --profile fast

## 进度可视化与大文件提速

v1.6.2 把进度可视化和大文件 / OCR 提速合并为同一版能力。它不是只加进度条，而是让长时间本地任务可观察、可恢复、可调优。

进度参数：

- `--progress` 输出终端进度。
- `--progress-jsonl` 写出 `progress_events.jsonl`。
- `--progress-log PATH` 写出自定义进度 JSONL 文件。
- `--verbose` 在终端进度中显示更多文件细节。

大文件和 OCR 参数：

- `--profile fast|production`
- `--ocr-mode auto|off|first-pages|selected-pages|full`
- `--ocr-lang TEXT`
- `--ocr-timeout-per-page INTEGER`
- `--max-ocr-pages INTEGER`
- `--ocr-pages TEXT`
- `--ocr-workers INTEGER`
- `--ocr-scale FLOAT`
- `--ocr-cache`
- `--ocr-cache-dir PATH`
- `--resume`
- `--skip-empty-pages`
- `--skip-low-text-pages`

启用后，知识包可额外生成：

- `progress_events.jsonl`
- `pdf_preflight_report.json`
- `pdf_page_classification.jsonl`
- `ocr_cache_manifest.json`
- `ocr_failed_pages.jsonl`
- `ocr_resume_report.md`
- `large_file_performance_report.md`

`fast` profile 在未显式指定页数时会限制 OCR 页数。OCR cache 和 resume 主要用于重复处理大型扫描 PDF。

详见 `docs/PROGRESS_AND_OBSERVABILITY.md` 和 `docs/LARGE_FILE_PERFORMANCE.md`。

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

## v1.7 可靠知识治理与 Evidence Gate

v1.7 新增可选知识治理、检索索引和 Evidence Gate 层，同时保持默认 headless 知识包构建行为不变。

新增命令：

```powershell
python -m heitang_kb_forge.cli govern --package .\output --output .\governance_output
python -m heitang_kb_forge.cli build-retrieval-index --package .\output --output .\retrieval_output
python -m heitang_kb_forge.cli evidence-gate --package .\output --query "这个知识包主要讲什么？" --output .\gate_output
```

可选 mock LLM 证据校验：

```powershell
python -m heitang_kb_forge.cli evidence-gate --package .\output --query "这个知识包主要讲什么？" --output .\gate_llm --llm --llm-provider mock --llm-evidence-validation --llm-boundary-check --llm-hallucination-check
```

mock provider 是本地确定性实现。v1.7 不调用 embedding API，不写入向量数据库，也不把桌面 UI 变成核心引擎。

## v1.8 Skill 与 Agent Package Generator

v1.8 新增可选 Skill Package 和 Agent Package 生成能力。

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_v18_package --output .\tmp_v18_skill --skill-name "Demo Knowledge Skill" --skill-type generic
python -m heitang_kb_forge.cli validate-skill --skill .\tmp_v18_skill --package .\tmp_v18_package --output .\tmp_v18_skill_validation
python -m heitang_kb_forge.cli generate-agent --package .\tmp_v18_package --skill .\tmp_v18_skill --output .\tmp_v18_agent --agent-name "Demo Knowledge Agent" --agent-type generic
```

Skill Package 输出包括 `SKILL.md`、`skill_manifest.yaml`、规则文件、`examples.md` 和 `eval_cases.jsonl`。

Agent Package 输出包括 `soul.md`、`role.md`、`system_prompt.md`、`agent_profile.yaml`、`tool_config.yaml`、`retrieval_config.yaml`、`memory_policy.md`、`safety_boundary.md` 和 `launch_checklist.md`。

可选 LLM 辅助生成可通过 `--llm --llm-provider mock --llm-skill-generation` 或 `--llm-agent-generation` 开启。LLM 输出必须受知识包范围约束，provider 配置失败时 fallback 到规则模板。

## v1.9 Portable Local Workspace

v1.9 新增 portable workspace，用于登记知识包、Skill 包、Agent 包、provider 元数据、prompt profile 和 LLM call audit。

```powershell
python -m heitang_kb_forge.cli workspace-init --workspace .\workspace
python -m heitang_kb_forge.cli workspace-register --workspace .\workspace --path .\tmp_v19_package --type knowledge
python -m heitang_kb_forge.cli workspace-health --workspace .\workspace
python -m heitang_kb_forge.cli workspace-export --workspace .\workspace --output .\workspace_export
```

Provider registry 只保存 `api_key_env`，不会把真实 API key 写入 registry 或 audit log。

## v2.3 工业级批量处理与知识治理

v2.3 增加本地工业级批量任务与知识治理协作输出，适合大批量知识生产、失败追踪、人工治理和依赖影响分析。它不改变默认 build 知识包契约，也不实现 v2.4 的平台分发能力。

新增命令：

```powershell
python -m heitang_kb_forge.cli batch-run --input .\sources --output .\batch_output --profile production --worker-pool --max-workers 4
python -m heitang_kb_forge.cli batch-retry --batch-job .\batch_output\batch_job_manifest.json --retry-only-failed
python -m heitang_kb_forge.cli package-lineage --workspace .\workspace --output .\lineage_output
python -m heitang_kb_forge.cli curate-package --package .\package --review-decisions .\review_decisions.jsonl --output .\curated_package
python -m heitang_kb_forge.cli update-impact --workspace .\workspace --package .\curated_package --output .\impact_output
```

关键输出：

- `batch_job_manifest.json`
- `batch_item_status.jsonl`
- `batch_failure_report.md`
- `batch_performance_report.md`
- `batch_quality_summary.json`
- `batch_contract_summary.json`
- `batch_governance_summary.json`
- `package_version_graph.json`
- `package_lineage_report.md`
- `curated_package/`
- `governance_decisions.jsonl`
- `impacted_skills.json`
- `impacted_agents.json`
- `update_required_report.md`
- `dependency_impact_report.md`

Batch & Governance Center 只是这些文件的只读展示层。核心逻辑仍然保留在 Python package 和 CLI 中。

## v2.3 checkpoint 后补：v2.2 工业级缺口

v2.3 checkpoint 后，本轮对 v2.2 的工业级 Skill / Agent / Workspace 缺口做本地补强，但不进入 v2.4 平台分发。

新增可选命令和参数：

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\package --output .\skill --skill-type qa_skill --enhanced-skill-template
python -m heitang_kb_forge.cli generate-agent --package .\package --skill .\skill --output .\agent --agent-compat
python -m heitang_kb_forge.cli workspace-refresh --workspace .\workspace --output .\refresh_output
python -m heitang_kb_forge.cli provider-readiness --workspace .\workspace --output .\provider_readiness
python -m heitang_kb_forge.cli prompt-profile-versioning --workspace .\workspace --output .\prompt_versions
```

Master Skill Learning 不是复制第三方 Skill，而是拆解结构、任务模式、风格特征和边界规则，再结合用户自己的知识库或上传资料，生成用户自有的新 Skill。

平台分发、OpenClaw export stub、小红书本地 packaging、MCP platform export stub 和 mock publish 已在 v2.4 作为本地文件输出实现。

## v2.4 Skill Distribution And Platform Publishing

v2.4 新增 opt-in 本地平台分发和 mock publishing 准备能力。

支持平台：

- `openclaw`
- `xhs`
- `codex`
- `claude_code`
- `mcp`
- `generic`
- `local_registry`

命令：

```powershell
python -m heitang_kb_forge.cli export-platform --skill .\skill_package --agent .\agent_package --output .\platform_export --platform generic
python -m heitang_kb_forge.cli platform-upload-check --export .\platform_export --output .\platform_check --platform generic
python -m heitang_kb_forge.cli mock-publish --export .\platform_export --platform generic --output .\mock_publish
```

v2.4 只写本地文件：`platform_manifest.json`、`platform_upload_check_result.json`、`platform_upload_check_report.md`、`mock_publish_result.json`、`install_guide.md` 和 `upload_guide.md`。

`platform_manifest.json` 记录目标平台、来源 Skill / Agent 路径、导出文件、安装与上传说明、mock publish 输出、warnings 和本地-only 限制。`platform-upload-check` 会检查必要文件，并静态检测疑似 API key 和危险命令片段。它不会允许真实上传。

小红书方向只准备 `xhs_skill_package/`、`xhs_skill_manifest.json`、`xhs_skill_link_manifest.json`、`platform_policy.md`、`violation_risk_checklist.md` 和 mock publish 输出。它不是小红书官方上传 API，不调用真实小红书账号，也不自动发布笔记。OpenClaw、Codex、Claude Code 和 MCP 输出只是导出包或 stub，不真实运行平台 runtime，也不启动 MCP Server。

## v2.5 Release Quality Gate And Regression Certification

v2.5 新增本地发布质量检查，用于判断知识包、Skill 包、Agent 包、workspace 和平台导出包是否具备进入下一阶段验证的条件。

命令：

```powershell
python -m heitang_kb_forge.cli quality-gate --workspace .\workspace --output .\quality_gate_output
python -m heitang_kb_forge.cli release-blockers --workspace .\workspace --output .\release_blockers_output
python -m heitang_kb_forge.cli regression-check --workspace .\workspace --output .\regression_output
python -m heitang_kb_forge.cli validate-golden-samples --workspace .\examples\golden_samples --output .\golden_samples_output
python -m heitang_kb_forge.cli certify-export --export .\platform_exports --output .\export_certification_output
python -m heitang_kb_forge.cli compatibility-matrix --workspace .\workspace --output .\compatibility_output
python -m heitang_kb_forge.cli llm-quality-gate-assist --workspace .\workspace --output .\llm_quality_gate_output --provider mock
python -m heitang_kb_forge.cli release-readiness --workspace .\workspace --output .\release_readiness_output
```

v2.5 输出本地报告，例如 `quality_gate_result.json`、`release_blockers.json`、`regression_result.json`、`golden_sample_validation.json`、`platform_export_certification.json`、`compatibility_matrix.json`、`llm_quality_gate_assist_result.json` 和 `release_readiness_result.json`。

边界：v2.5 不调用真实 LLM API，不上传小红书，不真实运行 OpenClaw / Codex / Claude Code / MCP runtime，不启动 MCP Server，也不实现飞书、移动端、安装端、iOS、SaaS 或权限系统。真实 LLM 治理预留到 v2.6，runtime compatibility smoke 预留到 v2.7，飞书 / 移动端 / 安装端 / iOS 预留到 v2.9。


## v1.2 边界补充

- 不是 Tool Runtime
- 不是业务系统集成
- 不是权限系统
- 不是 SaaS 平台
- 不调用外部平台 API
