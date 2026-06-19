# Skill 与 Agent 生成说明

当前事实以 v3 三基线为准。本文说明 UI 中 Skill、单 Agent 和 A2A 的产品边界。

## KB / Skill / Agent 关系

```text
文档库 → 知识库 → 索引层 → RAG → 编排层 → Skill / Agent / A2A
```

一个 KB 可以生成多个 Skill，也可以绑定多个 Agent。一个 Agent 可以绑定多个 KB 和多个 Skill。A2A 必须记录总工作区、子 Agent、议题、轮次、冲突点、汇总规则和导出报告。

## Skill

Skill 是可复用方法论和操作规则，不等于自动发布 runtime。UI 应展示来源 KB、外部 Skill、平台适配、版本、验证样例和导出状态。

## 单 Agent

单 Agent 需要明确工作区、KB、Skill、模型、记忆、工具和权限边界。Agent 工作区不能越权访问未绑定资源。

## A2A

A2A 是多 Agent 协作编排，不是普通聊天记录。每次讨论必须留下编排记录、参与 Agent、议题、轮次、引用证据、冲突和总结。

## 禁止误写

- Agent package 不等于 executable runtime。
- Agent Runtime ready 不得作为当前已完成事实。
- Redis config 不等于短期记忆完成。
- Vector DB config 不等于长期记忆完成。
- OKF 不是 Agent runtime，不是一级页面。
