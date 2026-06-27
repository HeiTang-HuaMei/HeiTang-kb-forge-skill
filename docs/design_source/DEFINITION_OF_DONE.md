# Definition of Done

## 目的

本文件定义任务完成标准。代码写完不等于完成，测试通过也不一定等于产品通过。

## 通用 DoD

每个任务完成必须满足：

- 用户问题已复现或明确无法复现原因。
- 根因定位到页面、服务、runtime 或数据。
- 改动最小且只覆盖当前问题。
- UI 文案使用用户语言。
- 无内部实现词泄漏到普通 UI。
- 后台真值一致。
- 重启后状态一致。
- 失败路径可解释。
- 验证结果记录清楚。

## UI 任务 DoD

必须满足：

- latest running UI 中可见。
- 默认窗口不截断关键操作。
- 中文可读。
- 英文可读。
- 空、加载、成功、失败、禁用态完整。
- 按钮点击有反馈。
- 删除有确认。
- 导出显示路径。

不能只靠 widget test。

## 数据任务 DoD

必须满足：

- 写入正确 manifest / catalog / jsonl。
- 删除不误删来源。
- 合并不修改 parent KB。
- 引用可追溯。
- 操作记录完整。
- 重启后 reload 一致。

必须有后台真值对账。

## Runtime 任务 DoD

必须满足：

- 输入、输出、错误结构清楚。
- 不泄露密钥。
- 外部服务失败可降级或可解释。
- 本地基础链路不被外部配置阻断。
- 中断后不留下可用半成品。

Runtime test 通过后仍需 UI 映射检查。

## 测试任务 DoD

必须满足：

- 覆盖正常路径。
- 覆盖至少三个扰动动作，除非任务极小并说明原因。
- 覆盖失败路径。
- 覆盖重启恢复。
- 覆盖后台真值。
- 测试样本带 `UI008_` 或其他明确 test marker。

## 文档任务 DoD

必须满足：

- 写清目的。
- 写清边界。
- 写清职责。
- 写清验收。
- 不重复历史报告。
- 不声明未验证通过。

## 禁止完成声明

以下情况不得声明完成：

- 只改源码未跑验证。
- 只跑 widget test 未看 running UI。
- running UI provenance 不明。
- 后台真值未对账。
- 重启恢复未检查。
- 失败路径没有下一步。
- 旧 EXE 或旧 app.so 可能仍在运行。
- Owner 看到的窗口不是测试窗口。

## 完成报告格式

每个任务完成报告应包含：

```text
目标：
改动文件：
用户可见变化：
后台数据变化：
验证：
running UI：
后台真值：
重启恢复：
未验证项：
风险：
```

## 验收等级

done：

- 满足全部 DoD。

blocked：

- 发现 blocker，不能继续声明通过。

partial：

- 部分完成，但 running UI、后台真值或重启恢复缺一项。

not_started：

- 未开始或只有计划。

## Owner confirmation 前 DoD

请求 Owner confirmation 前必须满足：

- blocker_count = 0
- ordinary_user_task_chains_passed = true
- no_placeholder_as_real_content = true
- no_internal_artifacts_in_results = true
- zh_cn_layout_passed = true
- en_us_layout_passed = true
- running_ui_verified_latest = true
- old_build_not_used = true
- owner_visible_ui_tested = true
- backend_oracle_matched = true
- restart_recovery_passed = true
