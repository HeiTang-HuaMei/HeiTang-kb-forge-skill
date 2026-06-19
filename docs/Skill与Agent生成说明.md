# Skill 与 Agent 生成说明

当前事实以 v3 三基线为准。本文说明 Skill、单 Agent 和 A2A 在“文档库 → 知识库 → 索引层 → RAG → 编排层 → 文档/Skill/Agent/A2A”链路中的边界。

## 绑定关系

```text
Document Library
  → Knowledge Base
  → Index Layer
  → RAG Context
  → Skill / Agent / A2A Orchestration
```

一个知识库可以生成多个 Skill，可以绑定多个 Agent；一个 Agent 可以绑定多个 KB 和多个 Skill；A2A 必须记录总工作区、子 Agent、议题、轮次、汇总规则和审计。

## Skill 输出

Skill 输出面向可复用工作方法，不等于自动发布 runtime。当前产品基线支持或规划验收：

- 从 KB 生成 Skill。
- 从多 KB 生成 Skill。
- 外部 Skill 导入、解析和本地化。
- Skill + KB 融合。
- 平台适配：Codex、Claude Code、OpenClaw、Markdown、Internal Agent。
- Skill metadata、草稿编辑、验证、导出和版本管理。

历史术语继续保留：

- Skill Template
- Skill Suite
- methodology rules
- style profile
- workflow rules
- quality checklist
- evaluation cases

## 单 Agent 边界

单 Agent 必须基于工作区、KB、Skill、模型、记忆和权限配置创建。Agent 创建或运行产物应记录：

- `manifest.json`
- agent_profile / `agent_profile.yaml`
- KB binding metadata
- Skill binding metadata
- model / provider config
- memory policy
- retrieval config
- quality_report.json
- handoff notes
- evaluation hints / evaluation cases

Agent Creation Package 是可交接的本地包，不等于完整 Agent Runtime。

## A2A 边界

A2A 是多 Agent 协作编排产物，不是无审计的普通聊天记录。A2A 至少需要记录：

- 多 Agent 总工作区。
- 子 Agent 工作区。
- 每个子 Agent 的 KB / Skill / 模型边界。
- 议题、轮次、冲突点、汇总规则。
- 讨论报告、引用证据和导出记录。

## 当前禁止误写

- Agent package 不等于 executable runtime。
- Agent Runtime ready 只能作为历史边界词出现，不得写成当前已完成事实。
- Multi-agent workflow spec 不等于可运行编排系统。
- Redis config existence is not Agent short-term memory completion。
- Vector DB config existence is not Agent long-term memory completion。
- `agent_package_ready` must not be written as `agent_executable`。
- OKF 不作为 Agent runtime，不作为一级页面。

## 历史兼容说明

旧测试和旧文档可能仍出现以下历史口径。它们仅作追溯，不覆盖 v3：

- Campaign 3 Supplement 4.0 的完整产品边界是 `Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`。
- 它替代了早期只覆盖 `Knowledge-to-Skill Template Generator` 的窄范围。
- Plan state: `accepted_for_campaign_3_final_consistency_gate`
- Current active phase: `Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`
- Current completed item: `Campaign 3 Supplement 4.0 Acceptance Gate`
- Current business item: `Campaign 3 Final Consistency Gate only`
- Supplement 3.0 Acceptance Gate、Pre-4.0 gate、bounded industrial-grade Entry Reconciliation Gate、4.0B Verified Knowledge-to-Skill Template、4.0C Skill Import & Dedicated Skill Composer、4.0D-I Product Handoff Contract Bundle、Supplement 4.0 Acceptance Gate 均已通过。
- Campaign 3 Final Consistency Gate 是 4.0 后唯一 next safe action。
- 4.0B 不 profile real knowledge base，不发布 Skill，不在 4.0B 创建 Agent Package。
- 4.0C 已作为 bounded industrial-grade Skill Import & Dedicated Skill Composer implementation 通过。
- 不是 Campaign 4 UI。
- 不是 Campaign 5 Bridge。
- Campaign 6 曾作为 Agent Runtime / Memory 计划名。
- `Agent package 不等于 executable runtime`。
- `runtime ready` 一律按“不得将 Agent Creation Package 写成 runtime ready”的否定边界理解。
- `not_goal_complete = true`。

### 历史 4.0 产品链路

```text
Verified Knowledge Base
→ Skill Template
→ Dedicated Skill
→ Agent Package
→ Workspace-bound Agent
→ Multi-Agent Workflow Spec
→ UI Handoff Contract
→ Bridge Handoff Contract
```

Supplement 4.0 must not stop at `Knowledge Base -> Skill Template`。

### 历史 Agent Package 边界

- `agent_package_ready = true`
- `agent_runtime_ready = false`
- `agent_executable_platform_ready = false`
- `agent_memory_runtime_ready = false`
- `multi_agent_runtime_ready = false`
- `KB + Skill -> Agent Package` 是包生成能力，不是 runtime ready。
- `agent_package_ready` must not be written as `agent_executable`。
- `workspace_basic_supported = true / not_proven`，`runtime_enforcement_ready = false`。
- `agent_memory_spec_ready = true`
- `agent_short_term_redis_runtime_ready = false`
- `agent_long_term_vector_runtime_ready = false`
- `agent_memory_isolation_runtime_ready = false`
- `cross_agent_memory_leak_tests_required = true`
- Redis config existence is not Agent short-term memory completion。
- Vector DB config existence is not Agent long-term memory completion。

### 历史 Skill 类型与状态

- `domain_expert_skill`
- `research_learning_skill`
- `product_business_skill`
- `operation_growth_skill`
- `literary_skill`
- `visual_video_skill`
- `general_personal_skill`

`visual_video_skill` is one subtype only。

- `skill_draft`
- `skill_generated_from_kb`
- `skill_validated`
- `skill_needs_review`
- `skill_reference_only`
- `skill_imported`
- `skill_composed`
- `skill_publish_ready`
- `agent_draft`
- `agent_package_ready`
- `agent_bound_to_kb`
- `agent_bound_to_skill`
- `agent_runtime_not_integrated`
- `agent_executable_not_ready`

### 历史 Handoff 边界

- UI Handoff Contract is not Campaign 4 UI completion。
- Bridge Handoff Contract is not Campaign 5 Bridge completion。
- `future_allowlist_candidate` 不会自动进入 Campaign 5 allowlist；Every new allowlist action must have separate acceptance。
- Campaigns 4-9, EXE packaging, final release 均未在 Supplement 4.0 中启动。
- `not_goal_complete = true`

### 历史 Supplement 4.0 Acceptance Gate

- Verified Knowledge-to-Skill passed
- Skill Import / Composer passed
- Existing Agent Package capability reconciled
- KB + Skill -> Agent Package passed
- Agent Workspace Binding Spec passed
- Agent Memory Isolation Spec passed
- Single / Multi-Agent Mode Spec passed
- Multi-Agent Workflow Spec passed
- Campaign 4 UI Handoff Contract generated
- Campaign 5 Bridge Handoff Contract generated
- Agent runtime not claimed ready
- Redis/Vector Agent memory runtime not claimed ready
