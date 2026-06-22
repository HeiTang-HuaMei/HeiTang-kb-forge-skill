# Lazy Builder And Semantic Layer Planning Report

Generated: 2026-06-22

Gate: `lazy_builder_and_semantic_layer_planning_gate`

Final status:

```text
semantic_layer_and_lazy_builder_plan_pending_owner_review
```

Not claimed:

```text
feature_implemented
runtime_ready
stable
release
packaging_ready
```

## 1. Scope

This task only performs governance and architecture planning.

It did not change:

- UI code.
- Runtime semantics.
- Provider / Gateway / ModelRoute behavior.
- Dependencies.
- Visual design.
- Product implementation.
- SQL DataAgent behavior.
- External tool integrations.

It did not tag, release, create a GitHub Release, or enter packaging.

## 2. Documents Added

| Document | Purpose |
| --- | --- |
| `docs/dev/HEITANG_LAZY_BUILDER_GATE.md` | Defines Ponytail-style lazy builder discipline: delete/reuse/minimize before implementation. |
| `docs/architecture/KNOWLEDGE_SEMANTIC_LAYER.md` | Defines HeiTang knowledge semantic layer planning without SQL DataAgent implementation. |
| `docs/product/KNOWLEDGE_INBOX_VNEXT_PLAN.md` | Defines Tabbit-style collection-to-knowledge-loop planning without binding external tools. |
| `docs/product/USER_PATH_FIRST_UI_GOVERNANCE.md` | Defines UI governance to protect the accepted user path from technical-entry sprawl. |

No same-name or near-name documents were found before this gate.

## 3. Lazy Builder Gate

`docs/dev/HEITANG_LAZY_BUILDER_GATE.md` defines the required pre-code discipline:

```text
先删重复，再补缺口。
先复用现有能力，再新增能力。
先保证真实调用，再做 UI 展示。
先普通用户路径，再技术按钮。
先最小闭环，再扩展架构。
能不写代码就不写。
能配置解决就不新增功能。
能复用组件就不新建组件。
能用现有 runtime 就不新增 runtime。
```

Future code changes must answer the 10 pre-change questions before implementation. If the answer is unknown, implementation must stop and produce a risk note.

## 4. Knowledge Semantic Layer

`docs/architecture/KNOWLEDGE_SEMANTIC_LAYER.md` defines a HeiTang-specific semantic layer:

```text
用户自然语言任务
-> 知识语义层
-> 本地文件 / SQLite / 向量库 / Redis / 外部链接 / manual evidence
-> 结构化结果
-> 文档 / Skill / Agent / 检索答案 / 报告
```

It defines:

- Source types.
- Knowledge units.
- Metadata.
- Source trace.
- Confidence.
- Freshness.
- Permission boundary.
- Lifecycle.
- Query paths.
- Output targets.

It explicitly does not implement SQL DataAgent, add dependencies, bind a vector backend, or claim runtime readiness.

## 5. Knowledge Inbox vNext

`docs/product/KNOWLEDGE_INBOX_VNEXT_PLAN.md` defines a future knowledge intake path:

```text
导入到知识收件箱
-> 自动识别来源类型
-> 自动打标签
-> 自动整理
-> 进入文档库
-> 生成知识库
-> 生成文档 / Skill / Agent
-> 来源与可信度检查
```

Planned sources include chat records, code change records, web links, video notes, documents, speech-to-text transcripts, Obsidian Markdown, Notion exports, Feishu exports, WeChat exports, and manual evidence.

The plan does not require Plaud, Obsidian, Weflow, Notion, platform login, or a complex sync center.

## 6. User Path First UI Governance

`docs/product/USER_PATH_FIRST_UI_GOVERNANCE.md` protects the accepted ordinary-user path:

```text
我的资料
-> 我的知识库
-> 测试知识库
-> 生成文档
-> 生成 Skill
-> 我的助手
-> 成果中心
-> 使用记录
-> 设置
```

It prevents these technical concepts from becoming ordinary primary UI:

```text
Provider
Gateway
ModelRoute
Runtime
Audit
Campaign
Operation Gate
Capability Matrix
OKF
A2A
Embedding
Qdrant
Redis
```

These terms remain limited to advanced settings, developer diagnostics, audit reports, code, test fixtures, or internal state mappings.

## 7. Current Version Impact

This gate does not change current accepted states:

```text
ui_restructure_accepted
interaction_operability_verified
real_input_real_output_verified
crud_operability_verified
industrial_readiness_candidate
```

It does not block:

```text
full_product_regression_before_packaging_gate
```

In this thread, `full_product_regression_before_packaging_gate` has already completed. This planning report does not retroactively modify that evidence. Future repair and implementation tasks must reference:

```text
docs/dev/HEITANG_LAZY_BUILDER_GATE.md
```

## 8. Repository State

Preflight:

| Item | Result |
| --- | --- |
| Branch | `feature/workbench-ui-prototype` |
| HEAD before this planning gate | `36f52db test: verify workbench industrial readiness candidate` |
| Pre-existing tracked dirty file | `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md` |

This gate did not modify the pre-existing unrelated dirty file.

## 9. Release Boundary

This gate did not:

- Commit.
- Tag.
- Release.
- Create GitHub Release.
- Enter EXE packaging.
- Claim stable status.
- Claim packaging-ready status.

## 10. Decision

Planning status:

```text
semantic_layer_and_lazy_builder_plan_pending_owner_review
```

Allowed mainline remains:

```text
full_product_regression_before_packaging_gate
```

Because full product regression has already completed in this thread, the next operational gate remains governed by the previously completed regression result. This planning gate only adds future engineering discipline and vNext architecture direction.
