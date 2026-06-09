# 项目一页纸：HeiTang KB Forge Skill

## 项目是什么

HeiTang KB Forge Skill 是一个本地优先的 Agent / RAG 知识供应链工具。

它可以把多格式资料加工成标准化、可追溯、可检索、可评估、可导出、可接入 LLM 的知识资产包，作为后续 RAG Agent、导购 Agent、教育 Agent、产品经理 Agent 等系统的前置知识底座。

## 解决的问题

很多 Agent / RAG 项目只关注模型调用和聊天界面，但知识进入 Agent 之前往往没有治理：

- 文档格式不统一。
- 来源证据不可追踪。
- 质量检查不稳定。
- 知识包难复用。
- LLM Provider 接入缺少安全边界。
- Demo 结果不可复现。

## 解决方案

HeiTang KB Forge 提供一条本地闭环：

资料输入 → 知识包生成 → 质量门禁 → 证据治理 → Provider 安全检查 → Agent / Skill 导出 → Demo 证据包。

## 目标用户

- AI 产品经理，用于 Agent Demo 和作品集展示。
- 开发者，用于构建 RAG / Agent 上游知识资产。
- 需要本地可审计知识包的团队。
- 需要可复现端到端 Demo 的项目。

## 当前版本

当前 checkpoint：v4.0.0-rc.1 release candidate preparation。

近期能力：

- v2.5.1：工程收敛、CI、CLI 收敛。
- v2.6：国内外 LLM Provider 治理。
- v2.7：最小端到端作品集 Demo。
- P1：final gate evidence、external project registry 可见边界与 S/A contract inclusion 可见边界。

## 当前边界

- 默认离线 / mock。
- 不保存 API key。
- 默认不真实联网。
- 不真实发布平台内容。
- 不做 SaaS / 权限 / 多租户。
- 不声称所有 Provider 或 Runtime 都已实测。

## 项目价值

它不是普通文档解析器，而是 Agent 构建前的知识资产生产层。
