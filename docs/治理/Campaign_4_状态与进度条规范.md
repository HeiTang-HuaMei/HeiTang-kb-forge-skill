# Campaign 4 状态与进度条规范

## 状态目标

Campaign 4 必须使用真实状态驱动 UI。状态和进度条用于帮助用户理解当前任务、失败原因和下一安全动作，不得用于展示未完成能力。

Campaign 4 仍然是 UI Workbench boundary，不代表 Bridge、Agent Runtime、Memory Runtime、Multi-Agent executable、EXE packaging 或 GitHub Release 已完成。

## 状态枚举

| 状态 | 含义 | 允许动作 | 禁止 |
| --- | --- | --- | --- |
| pending | 尚未开始，等待输入或前置条件 | start、configure | 不得显示为已完成 |
| running | 正在执行 | view progress、cancel | 不得隐藏耗时任务 |
| completed | 当前 Campaign 内已完成且已验收 | view output、view report | 不得用于未实现能力 |
| failed | 执行失败且当前不可继续 | view report、next-safe-action | 不得自动推进下一阶段 |
| retryable | 失败但可重试 | retry、view report、cancel | 不得无限重试 |
| cancelled | 用户取消或安全停止 | resume plan、restart | 不得写成 failed 或 passed |
| blocked | 缺少前置条件、依赖、权限或 gate | view blocker、next-safe-action | 不得写成 completed |

`skipped`、`blocked`、`deferred` 不得写成 `passed`。`reference_only` 不得写成 `real_integration`。`needs_verification` 不得写成 `integrated`。

## 进度条清单

Campaign 4 必须规划以下进度条：

| 进度条 | 起点 | 终点 | 证据 | 不得 overclaim |
| --- | --- | --- | --- | --- |
| 文件导入 | 用户选择文件或目录 | 文件进入工作区并生成导入记录 | import report / manifest | 不宣称 parsing 完成 |
| parsing | 导入记录可用 | 解析记录生成 | parsing report | 不宣称 knowledge package 完成 |
| knowledge splitting | 解析记录可用 | 分片和知识包草稿完成 | chunk / package report | 不宣称 Skill 完成 |
| Skill generation | 知识包草稿可用 | Skill draft / Skill Suite draft 生成 | skill report | 不宣称 Agent Runtime 完成 |
| Agent package generation | Skill draft 可用 | Agent Creation Package draft 生成 | agent package manifest | 不宣称 executable runtime |
| validation | draft outputs 可用 | validation report / failure matrix 生成 | validation report | 不宣称 Full Review 或 Release complete |

## 任务卡字段

每个 task-card 至少包含：

- task id。
- task title。
- current status。
- current step。
- progress percent 或 step count。
- input required。
- output target。
- evidence / report link。
- failed reason。
- retry policy。
- cancel policy。
- next safe action。
- forbidden actions。

长任务 task-card 必须显示 elapsed time，并在超过 30 秒后显示可见进度、日志位置和恢复策略。

## LongRun 状态记录

每 30-60 分钟写 checkpoint / resume prompt。checkpoint 必须包含：

- 当前 Campaign。
- 当前 Gate。
- 当前状态。
- 已完成内容。
- 未完成内容。
- 失败原因。
- 下一安全动作。
- 禁止动作。
- 是否允许恢复执行。

单次无人值守任务最长 10 小时。单次执行优先只跑一个 Campaign。超过预估时间 50% 必须输出 progress report，超过 timebox 必须停止并输出 failure_report。

## 失败与停止规则

遇到以下情况必须停止，不得自动推进：

- CI failure。
- Release Check failure。
- clean checkout mismatch。
- Windows runner parity mismatch。
- 429。
- root-only JSON 检查失败。
- forbidden legacy tracked paths 检查失败。
- UI 仓库出现本次修改。
- 当前 Campaign Acceptance Gate 未通过。

失败后必须记录当前失败、下一安全动作、禁止动作和是否允许恢复执行。

## UI 文案规则

Campaign 4 UI 文案必须保持能力边界：

- Agent package 不等于 executable runtime。
- Multi-Agent spec 不等于 executable orchestration。
- Bridge handoff 不等于 Bridge complete。
- UI handoff 不等于 Campaign 4 UI implementation complete。
- EXE packaging 未进入 Campaign 9 前不得显示 ready。
- GitHub tag 不等于 GitHub Release。

## Evidence 规则

状态为 `completed` 时必须能关联到证据：

- 本地或 UI focused test。
- manifest 或 report。
- failure matrix 中无阻塞项。
- clean checkout / CI parity 适用项已通过。

禁止只写 `passed` 而不列证据。禁止用截图或局部 smoke 代替 full gate。
