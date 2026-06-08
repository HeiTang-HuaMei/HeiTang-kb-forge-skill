# 多知识库、多 Agent 与记忆隔离架构

## 1. 为什么必须设计记忆隔离

多 Agent 系统最大风险之一是记忆混淆。

如果多个 Agent 默认共享记忆，会出现：

- 客服 Agent 读取产品经理 Agent 的草稿判断。
- 法务 Agent 混入运营 Agent 的创意内容。
- 教育 Agent 使用了非教材证据。
- 一个 Agent 的错误结论污染其他 Agent。
- Agent 回答时无法判断信息来自哪个知识库、哪个会话、哪个协作流程。

因此系统必须采用：

默认隔离，显式共享。

## 2. 记忆类型

### 2.1 Workspace Memory

工作区级记忆。

存储：

- 用户长期偏好。
- 全局项目配置。
- 默认 Provider 配置。
- 默认 parser backend。
- 全局安全策略。
- 全局 answer_policy 默认值。

路径建议：

memory/workspace/

不能存储：

- 单个 Agent 的私有推理。
- 未授权共享的 Agent 会话。
- 某个 workflow 的临时结论。

### 2.2 Knowledge Base Memory

知识库级记忆。

存储：

- kb_id。
- 版本历史。
- source inventory。
- quality status。
- review status。
- corrected text history。
- domain rules。
- citation policy。

路径建议：

memory/kb/{kb_id}/

用途：

- 知识库更新。
- 版本对比。
- 回答证据边界。
- 知识库质量追踪。

### 2.3 Agent Private Memory

Agent 私有记忆。

存储：

- agent profile。
- role-specific rules。
- private conversation memory。
- task preferences。
- agent-specific evaluation history。
- agent-specific failures and fixes。

路径建议：

memory/agents/{agent_id}/private/

默认规则：

- 其他 Agent 不可读取。
- Orchestrator 只能读取摘要，不读取完整私有记忆。
- 只有明确授权的 handoff 才能共享指定片段。

### 2.4 Session Memory

单次会话记忆。

存储：

- 当前用户请求。
- 当前上下文。
- 临时检索结果。
- 当前输出草稿。
- 当前引用证据。

路径建议：

memory/sessions/{session_id}/

生命周期：

- 默认短期。
- 任务完成后可归档摘要。
- 不自动进入长期 Agent memory。

### 2.5 Workflow Shared Memory

多 Agent 协作共享记忆。

存储：

- workflow_id。
- 参与 Agent。
- handoff 记录。
- 共享任务目标。
- 已确认的中间结论。
- 可共享证据。
- 最终交付物。
- trace report。

路径建议：

memory/workflows/{workflow_id}/shared/

规则：

- 只有 workflow 中声明的 Agent 可以读写。
- 共享内容必须带来源。
- 私有记忆不能自动进入 shared memory。
- shared memory 需要 expiration / archive policy。

### 2.6 Handoff Memory

Agent 交接记忆。

存储：

- from_agent
- to_agent
- handoff_reason
- shared_context
- required_action
- evidence_refs
- memory_scope
- allowed_read_paths
- forbidden_paths

路径建议：

memory/workflows/{workflow_id}/handoffs/{handoff_id}.json

用途：

- 控制 Agent 间交接边界。
- 防止私有记忆泄露。
- 让交接可审计。

### 2.7 Long-term Experience Memory

长期经验记忆。

存储：

- 成功 workflow 模式。
- 失败原因。
- 用户选择偏好。
- 高质量模板。
- 常见修正。
- Agent 改进建议。

路径建议：

memory/experience/

规则：

- 必须脱敏。
- 必须来源明确。
- 不能混入未确认事实。
- 不能覆盖知识库事实。

## 3. 记忆访问规则

### 默认规则

- Agent 只能读取自己的 private memory。
- Agent 只能读取自己绑定的 knowledge base memory。
- Agent 可以读取当前 session memory。
- Agent 不能读取其他 Agent private memory。
- Agent 不能读取未绑定知识库。
- Agent 不能读取其他 workflow shared memory。

### 允许共享的情况

只有满足以下条件才允许共享：

1. 存在 workflow_id。
2. workflow 声明参与 Agent。
3. handoff_policy 允许共享。
4. shared_context 明确列出内容。
5. shared memory 带来源。
6. trace report 记录共享行为。

## 4. Agent 配置字段

每个 Agent 必须包含：

agent_id: 唯一 ID
role: Agent 角色
bound_knowledge_bases: 绑定知识库
private_memory_path: 私有记忆路径
allowed_shared_memory_scopes: 可访问共享记忆范围
provider_profile: 用户自配置 Provider Profile
answer_policy: 回答策略
tools: 可调用工具
handoff_policy: 交接策略

示例：

agent_id: product_agent
role: product_manager
bound_knowledge_bases:
  - kb_product
  - kb_user_research
private_memory_path: memory/agents/product_agent/private
allowed_shared_memory_scopes:
  - workflow_shared
provider_profile: custom_http
answer_policy: knowledge_first
handoff_policy: explicit_only

## 5. 多 Agent Workflow 配置

workflow_id: product_plan_generation
agents:
  - product_agent
  - user_research_agent
  - document_agent
  - review_agent
shared_memory_path: memory/workflows/product_plan_generation/shared
handoff_policy: explicit_only
memory_merge_policy: no_private_memory_merge
trace_required: true

## 6. 禁止行为

禁止：

- Agent 默认共享全部记忆。
- Agent 读取其他 Agent 私有记忆。
- 私有记忆自动进入长期全局记忆。
- 无来源内容进入 shared memory。
- 工作流结束后自动把 shared memory 写入所有 Agent。
- 模型补充内容伪装成知识库事实。
- 未授权跨知识库检索。

## 7. 外部记忆项目接入建议

### Mem0

用途：

- Agent persistent memory。
- 用户偏好。
- 长期个性化记忆。
- Agent-specific memory store。

接入方式：

- optional memory backend。
- 不作为默认强依赖。
- 必须按 agent_id / workspace_id 隔离 namespace。

GitHub：

https://github.com/mem0ai/mem0

### Zep / Graphiti

用途：

- temporal knowledge graph memory。
- 多会话上下文。
- 关系型记忆。
- 时间变化事实。

接入方式：

- optional graph memory backend。
- 适合 v3.4 以后接入。
- 必须按 workspace / agent / workflow 分图或命名空间。

GitHub：

https://github.com/getzep/zep
https://github.com/getzep/graphiti

### LangGraph Checkpointer / Store

用途：

- 多 Agent 状态保存。
- workflow state。
- short-term / long-term memory 接入。

接入方式：

- v3.2 multi-agent orchestration 可选后端。
- 不替代本项目自己的 memory policy。

GitHub：

https://github.com/langchain-ai/langgraph
https://github.com/langchain-ai/langgraph-supervisor-py

## 8. 版本落地

v3.2 Multi-KB & Multi-Agent Orchestration 必须实现：

- multi-kb registry
- agent registry
- agent private memory path
- workflow shared memory
- handoff memory
- memory access policy
- multi-agent trace report

v3.4 Product Hardening 可接入：

- Mem0 optional backend
- Zep / Graphiti optional backend
- LangGraph checkpointer optional backend
