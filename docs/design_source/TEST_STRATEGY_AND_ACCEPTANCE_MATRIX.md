# 测试策略与验收矩阵设计源

## 目的

本文件定义 UI closure 和后续产品验收的测试分层、通过标准和红线。测试目标是验证真实产品闭环，不是证明测试脚本能跑通。

## 测试对象硬规则

所有 UI closure 测试必须在最新 running UI 执行。

执行前必须确认：

- 旧 EXE / 旧进程已关闭。
- 当前窗口来自最新源码或最新 review build。
- 已记录启动方式：flutter run -d windows / fresh local review build。
- 已记录 git HEAD、dirty marker、源码时间、exe/app.so 时间。
- Owner 看到的 UI 与测试运行的是同一个实例。

每个测试报告必须写明：

- running_ui_verified_latest = true
- old_build_not_used = true
- owner_visible_ui_tested = true

不能证明当前 UI 是最新的，就不能声明 Phase passed、UI closure passed 或 Owner confirmation ready。

## 测试分层

| 层级 | 目的 | 是否可替代 running UI |
| --- | --- | --- |
| 静态扫描 | 找禁用词、占位文案、内部术语 | 否 |
| 单元 / controller 测试 | 验证业务规则和状态映射 | 否 |
| widget / UI smoke | 验证组件状态和入口 | 否 |
| running UI E2E | 验证 Owner 看到的真实界面 | 不可替代 |
| 后台真值对账 | 验证数据真实一致 | 否 |
| 重启恢复 | 验证持久化和恢复 | 否 |

## 七页审计

必须覆盖：

- 导入资料
- 知识库
- Skill
- Agent
- 文档生成
- 任务工作台
- 配置

每页输出：

- 页面主任务是什么。
- 当前显示哪些能力和成果。
- 数据是否来自真实当前工作区。
- 是否有占位摘要、正文、问题、成果。
- 是否后台有产物但 UI 未绑定。
- 是否按钮不可点或点后无反馈。
- 是否混入工程报告、诊断、测试证据。
- 是否能删除、重试、导出、打开位置。
- 是否中英文完整切换。
- 是否有空、失败、成功、加载、下一步状态。
- blocker 列表。
- 最小修复方案。

## 问题分级

blocker：

- 知识库外问题编造答案。
- 删除或合并误删来源资产。
- running UI 不是最新实例却声明通过。
- 普通成果页混入工程报告并误导用户。
- UI 显示成功但后台失败。
- 半成品知识库显示为可用。
- 用户无法恢复工作区或核心数据。

major：

- 按钮无反馈但不损坏数据。
- 失败状态没有足够清楚的下一步动作。
- 重要长文本截断影响理解。
- 中英文切换残留明显系统 UI 文案。
- 导出路径不清楚。

minor：

- 视觉密度不均。
- 个别文案可读性可提升。
- 非关键 tooltip 缺失。

## Golden E2E 008

Golden E2E 008 必须包含：

- 正常链路。
- 重复导入。
- 删除源资产。
- 合并中断。
- 知识库外问题。
- 引用追溯。
- 并发点击。
- 重启恢复。
- 后台数据对账。
- 内存观察。

合并知识库必须验证：

- merge_creates_new_kb = true
- source_kbs_not_modified = true
- source_docs_union_correct = true
- chunk_dedup_rule_applied = true
- lineage_preserved = true
- conflicts_not_silently_dropped = true
- interrupted_merge_recovers_cleanly = true
- duplicate_merge_handled = true
- merged_kb_delete_safe = true
- merged_kb_citation_trace_ok = true
- out_of_scope_query_refuses = true

## 反机械测试

每条测试必须包含至少三个非 happy path 动作。

可选扰动：

- 返回。
- 切页。
- 重复点击。
- 取消。
- 改名。
- 删除前取消。
- 删除后重建。
- 切语言。
- 缩窗口。
- loading 时切页。
- 关闭后重启。
- 导出路径不可写。
- 外部服务未配置或配置错误。

通过结论必须包含：

```text
正常路径 + 至少三个扰动动作 + UI/后台/重启后三方一致
```

## 反作弊层

最终 closure 前至少跑一次：

- 随机顺序测试。
- 双人视角复验。
- 无说明书测试。
- 截图审计。
- running UI 可见文本或 accessibility tree 旧词扫描。
- 验收样本污染检查。
- 失败证据保留。
- 无口头解释通过标准。
- 交叉入口一致性。
- 验收前冷启动。

## 禁用词与占位

普通 UI、配置页、高级诊断页不得出现会误导用户的内部实现词和测试占位。

禁用或需隔离的表达包括：

- Provider
- Adapter
- Parser
- Router
- OCR Provider
- Vector Adapter
- Provider Matrix
- Capability Matrix
- dependency_gated
- needs_secret_config
- ready_for_user_selection
- heitang-rc6-needle
- 0/x
- audit report
- acceptance report
- validation report
- UI taste gate
- responsive review

工程术语可以出现在代码、内部日志、审计报告、测试报告和开发者调试文件中，但不得进入普通产品 UI。

## 最终通过条件

只有同时满足以下条件，才允许重新请求 Owner confirmation：

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

## 最小验证命令

代码变更后通常需要：

- flutter analyze
- targeted widget/UI smoke
- task-chain E2E smoke
- forbidden/internal wording scan
- placeholder scan
- artifact classification scan
- zh/en switch smoke
- default window smoke
- restart recovery smoke
- current workspace data smoke

具体运行哪些命令应根据改动范围选择。不得用更宽的测试掩盖没有验证 running UI 的事实。
