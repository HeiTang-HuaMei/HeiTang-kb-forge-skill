# Skill 与 Agent 生成说明

## Campaign 3 Supplement 4.0 当前结论

Campaign 3 Supplement 4.0 的完整产品边界是 `Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`。它替代了早期只覆盖 `Knowledge-to-Skill Template Generator` 的窄范围，但仍属于 Campaign 3 内部补充项，不是 Campaign 4 UI，也不是 Campaign 5 Bridge。

当前状态：

- Plan state: `accepted_for_campaign_3_final_consistency_gate`
- Current active phase: `Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`
- Current completed item: `Campaign 3 Supplement 4.0 Acceptance Gate`
- Current business item: `Campaign 3 Final Consistency Gate only`
- Supplement 3.0 Acceptance Gate、Pre-4.0 gate、bounded industrial-grade Entry Reconciliation Gate、4.0B Verified Knowledge-to-Skill Template、4.0C Skill Import & Dedicated Skill Composer、4.0D-I Product Handoff Contract Bundle、Supplement 4.0 Acceptance Gate 均已通过。
- Campaign 3 Final Consistency Gate 是 4.0 后唯一 next safe action。

4.0B 不 profile real knowledge base，不发布 Skill，不在 4.0B 创建 Agent Package。4.0C 已作为 bounded industrial-grade Skill Import & Dedicated Skill Composer implementation 通过。

## 4.0 产品链路

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

## Skill 输出

Skill 输出面向可复用工作方法，不等于自动发布 runtime。当前产品基线支持：

- Skill Template
- Skill Suite
- methodology rules
- style profile
- workflow rules
- quality checklist
- evaluation cases

## Agent 创建包

Agent Creation Package 是可交接的本地包，不等于完整 Agent Runtime。它可以包含：

- agent_profile / `agent_profile.yaml`
- KB binding metadata
- Skill binding metadata
- `manifest.json`
- memory policy
- retrieval config
- quality_report.json
- handoff notes
- evaluation hints / evaluation cases

## 边界

- Skill draft 不等于 published。
- Agent package 不等于 executable runtime。
- Multi-agent workflow spec 不等于可运行编排系统。
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

## Skill 类型与状态

支持的 Skill 类型：

- `domain_expert_skill`
- `research_learning_skill`
- `product_business_skill`
- `operation_growth_skill`
- `literary_skill`
- `visual_video_skill`
- `general_personal_skill`

`visual_video_skill` is one subtype only。

状态必须区分：

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

## Handoff 边界

- UI Handoff Contract is not Campaign 4 UI completion。
- Bridge Handoff Contract is not Campaign 5 Bridge completion。
- `future_allowlist_candidate` 不会自动进入 Campaign 5 allowlist；Every new allowlist action must have separate acceptance。
- Campaigns 4-9, EXE packaging, final release 均未在 Supplement 4.0 中启动。
- `not_goal_complete = true`

## Supplement 4.0 Acceptance Gate 摘要

Acceptance Gate 已验证：

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
