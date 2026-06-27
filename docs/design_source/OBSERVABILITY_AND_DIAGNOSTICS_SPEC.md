# 可观测性与诊断规范

## 目的

本文件定义操作记录、事件、日志和支持诊断包的边界。

## 三类记录

| 类型 | 面向对象 | 是否普通 UI 可见 |
| --- | --- | --- |
| 操作记录 | 用户 | 是 |
| 工程日志 | 开发者 | 否 |
| 审计 / 诊断报告 | 支持与验收 | 仅高级诊断 |

## 操作记录

每个用户动作建议记录：

- record_id
- workspace_id
- action
- target_type
- target_id
- status
- user_message
- retryable
- created_at

失败记录额外记录：

- error_code
- next_actions
- diagnostic_ref

## Event Ledger

Event Ledger 可记录内部事件，但不得直接作为普通成果。

用途：

- 审计。
- 重启恢复。
- 问题定位。
- 支持诊断包。

## Artifact Catalog

普通 artifact catalog 只记录：

- 知识库。
- 文档。
- Skill 包。
- Agent 包。

工程报告只能进入诊断或审计 catalog。

## 支持诊断包

诊断包应包含：

- 操作历史摘要。
- 失败记录。
- 脱敏配置状态。
- 对象 id 和状态。
- 相关 manifest 摘要。
- running UI provenance 摘要。

不得包含：

- 密钥。
- Token。
- Cookie。
- Authorization header。
- 未经确认的完整私密正文。

## 用户表达

普通 UI 使用：

- 操作历史。
- 导出操作历史。
- 导出支持诊断包。
- 查看失败原因。

避免：

- audit evidence。
- validation artifact。
- runtime report。

## 验收

必须验证：

- 失败有操作记录。
- 失败可重试或忽略。
- 操作记录可清理。
- 支持诊断包说明导出位置和包含内容。
- 普通成果页不混入诊断文件。
