# 架构

## Skill-first 架构

HeiTang KB Forge 首先是 Agent 知识供应链 Skill。桌面 UI 只是表现层。

```text
Core Skill / Python package
> CLI
> Config / Pipeline
> Agent-callable skill interface
> Desktop UI
```

## v2.0 稳定版底座

v2.0 在现有 headless package、CLI、config 和 pipeline runner 之上增加稳定版底座，包括 `studio-run`、`stable-check`、`provider-health`、`reliability-score`、`release-package` 和 extension readiness metadata。

Extension readiness 是预留契约。v2.0 不实现母版 Skill 拆解学习，也不实现平台上传；这些能力分别规划到 v2.2 和 v2.4。

## v2.1 输入与质量层

v2.1 在解析和知识包生成后增加 opt-in 输入与质量层，写出 coverage、parser hardening、knowledge quality、review、retrieval evaluation 和 evidence benchmark 文件，不改变默认输出契约。

## v1.6 多模态与 Contract 层

```text
source files
-> text package
-> multimodal_assets.jsonl
-> multimodal_evidence_map.json
-> Contract v2 files
-> contract checker
```

该层用于保留证据、标记需要人工复核的资产，并让输出结构可被后续 Skill / Agent 检查。它不是视觉理解模型，也不会把低置信 fallback 内容声明为原文事实。
# v1.7 治理与证据层

v1.7 位于知识包生成之后：

Documents -> Core Skill / CLI -> Standard Knowledge Package -> Governance -> Retrieval Index -> Evidence Gate -> Agent/RAG/Desktop consumption。

桌面 UI 仍然只是 presentation layer。治理、检索和证据检查都可以通过 CLI 和配置文件 pipeline 调用。

# v1.8 Skill 与 Agent Factory

v1.8 在治理和证据检查之后增加 factory 层：

Knowledge Package -> Skill Package -> Skill Validation -> Agent Package。

生成结果仍然是标准本地文件。v1.8 不部署 Agent，也不运行 Tool Runtime。

# v1.9 Workspace Architecture

Workspace registries 位于生成包之上，追踪 knowledge_package、skill_package、agent_package、provider 元数据、prompt profiles 和 LLM call audit。Registry 只保存路径和元数据，不保存密钥。
# v2.3 批量治理层

v2.3 batch governance layer 位于现有 build pipeline 之上。它读取标准知识包输出，并写出 `batch_job_manifest.json`、`batch_item_status.jsonl`、`package_version_graph.json`、`curated_package/` 和 update impact 报告。

该层仍然是 file-first 和 headless。UI 只读取这些文件，不拥有核心治理逻辑。
