# 作品集介绍：HeiTang KB Forge Skill

## 项目定位

HeiTang KB Forge Skill 是一个本地优先的 Agent 知识供应链底座。

它负责为后续 RAG Agent、导购 Agent、教育 Agent、客服 Agent、产品经理 Agent 准备可治理的知识资产。

## 为什么重要

Agent 项目在做 UI 和 Prompt 之前，首先需要可靠的知识资产。

这个项目关注：

- 资料接入
- 标准化
- 质量门禁
- 证据追踪
- Provider 治理
- Agent / Skill 导出
- Demo 证据包

## 版本演进

### v2.5.1

完成工程收敛、CI、CLI 收敛、能力状态、版本矩阵和发布清单。

### v2.6

完成真实 LLM Provider 治理、国内外 Provider Registry、安全审计、fallback、cost guard 和可选 live smoke。

### v2.7

完成最小端到端 Demo 和作品集报告。

## 架构

```text
源资料
  ↓
接入 / 解析
  ↓
知识资产包
  ↓
质量 / 证据
  ↓
Provider 治理
  ↓
Agent / Skill 导出
  ↓
Demo 报告 + Evidence Pack
```

## Demo 流程

```text
build
→ quality-gate
→ provider-security-audit
→ llm-quality-gate-assist
→ export-platform
→ release-readiness
→ portfolio_demo_report
```

## 当前限制

- 不声明完整 runtime compatibility。
- 不真实平台发布。
- 不自动启动 MCP server。
- 不做 SaaS / 权限 / 多租户。
- Live LLM 是可选能力，CI 不依赖真实 key。

## 后续路线

后续更有价值的是：

- Runtime compatibility evidence
- 领域 Skill 模板
- 产品化入口
- 团队协作设计
