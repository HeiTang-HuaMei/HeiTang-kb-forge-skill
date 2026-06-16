# Campaign 4 入口计划

## 入口定位

Campaign 4 是 Goal-Oriented Product UI Workbench。它只在 Campaign 1-3 稳定基线之后开启，不修改基线，不创建 GitHub Release，不创建 tag，不声明 Bridge、Agent Runtime、Memory Runtime、Multi-Agent executable、EXE packaging 或 Release complete。

稳定基线：

| 项目 | 状态 |
| --- | --- |
| stable tag | `campaign-1-3-baseline` |
| commit | `8559eb57b0f4482cfe678e40ecf9fa57b5d56218` |
| CI | passed |
| Release Check | passed |
| GitHub Release | not_created |
| Campaign 4 | 历史技术验收存在，但 Owner Visual Acceptance 未通过，当前等待重新授权 Entry Gate |

Campaign 4 的未来 UI 改动主要发生在 `kb-forge-skill-ui`。本 Planning Gate 不修改 `kb-forge-skill-ui`，只记录只读盘点和风险。

## Entry Gate 前置条件

Campaign 4 Entry Gate 只有在以下条件全部满足后才允许开启：

1. Campaign 1-3 稳定基线保持不变。
2. `docs/治理/` 中文计划文档已提交并推送。
3. forbidden legacy tracked paths 无输出。
4. root-level JSON 只有 `skill.json`。
5. `kb-forge-skill-ui` dirty diff 已单独审查，不再将既有未确认改动误当成 Campaign 4 正式实现。
6. clean checkout / CI parity 验证前置通过。
7. Campaign 4 范围只包含 UI Workbench，不包含 Campaign 5 Bridge、Provider Runtime implementation、Campaign 6 Runtime / Memory、Campaign 9 EXE。

## UI Inventory 必做项

Campaign 4 Entry Gate 前必须对 `kb-forge-skill-ui` 做只读 inventory：

| 项目 | 必查内容 | 输出 |
| --- | --- | --- |
| 页面结构 | 当前入口、页面、模块组织 | 页面 inventory |
| 导航数量 | 顶层导航数量和分组 | 必须且仅为：工作台 / 知识库 / 文档 / Skill / Agent / 验证与导出 / 设置与模板 |
| 组件状态 | 可复用组件、不可复用组件、状态管理方式 | 组件 inventory |
| 未提交改动 | `git -C ..\kb-forge-skill-ui status --short` 和 diff summary | dirty diff review |
| 可复用组件 | 现有 task/action/card/progress/error/report 相关组件 | reuse list |
| 不可复用组件 | 与 Campaign 4 目标冲突或会造成 overclaim 的组件 | replace / defer list |

已知只读盘点结论：

- `kb-forge-skill-ui` 当前已有未提交改动。
- 当前 UI 形态偏 `MaterialApp + StatefulWidget + setState/FutureBuilder`。
- 当前导航数量不符合 Campaign 4 固定七入口定义。

## Campaign 4 Scope

Campaign 4 允许规划：

- 顶层导航必须且仅为 7 个一级入口：工作台 / 知识库 / 文档 / Skill / Agent / 验证与导出 / 设置与模板。
- task-card driven UI。
- 知识库创建、文档生成、Skill generation、Agent package generation、validation 的进度展示；导入资料只是知识库创建入口，不作为一级导航。
- pending、running、completed、failed、retryable、cancelled、blocked 状态。
- 输入区、任务进度区、输出结果区、证据/报告区、错误与重试区。
- UI 不宣称底层 runtime 已完成。未完成能力必须隐藏或禁用，不伪装可用。

Campaign 4 禁止规划为已完成：

- Bridge complete。
- Provider Runtime complete。
- Agent Runtime complete。
- Memory Runtime complete。
- Multi-Agent executable complete。
- EXE packaging complete。
- GitHub Release complete。

## Entry Gate 验收

| 验收项 | 检查 | 通过条件 |
| --- | --- | --- |
| UI 仓库只读 | `git -C ..\kb-forge-skill-ui status --short` | 只记录，不修改、不格式化、不提交 |
| 导航收敛方案 | 页面 inventory | 顶层入口必须且仅为：工作台 / 知识库 / 文档 / Skill / Agent / 验证与导出 / 设置与模板 |
| 状态模型 | 状态与进度条规范 | 不包含 fake completed states |
| runtime 边界 | 文案和任务卡审查 | 不宣称 Bridge / Runtime / EXE / Release 完成 |
| clean checkout 前置 | clean worktree / CI parity plan | 不依赖污染工作区 |

## LongRun 入口规则

Campaign 4 启动后必须采用 LongRun 风格控制：

- 单次无人值守最长 10 小时。
- 单次只执行 Campaign 4，不顺带进入 Campaign 5。
- 每 30-60 分钟写 checkpoint / resume prompt。
- checkpoint 记录当前 Gate、已完成内容、失败原因、下一安全动作、禁止动作、是否允许恢复执行。
- 遇到 429、CI failure、Release Check failure、clean checkout mismatch 必须停止。

## HeiTang-governance-skill 借鉴

Campaign 4 Entry Gate 借鉴 `HeiTang-governance-skill` 的 Scope & Plan Lock Guard、Implementation Reality Guard、Evidence & Test Gate Guard、Pitfall Memory Guard，但不得把它作为 runtime dependency 接入，不复制其目录结构，不恢复旧 evidence pile。

## 下一安全动作

Campaign 4 Entry Gate 的下一安全动作是：只读审查 `kb-forge-skill-ui` 当前 dirty diff 和页面结构，形成 UI inventory，再决定 Campaign 4 implementation plan。不得直接编辑 UI 仓库。
