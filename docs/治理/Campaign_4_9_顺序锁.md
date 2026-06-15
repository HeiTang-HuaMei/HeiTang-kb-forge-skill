# Campaign 4-9 顺序锁

## 基线锁定

Campaign 4-9 从以下稳定基线之后开始规划：

| 项目 | 状态 |
| --- | --- |
| stable tag | `campaign-1-3-baseline` |
| commit | `8559eb57b0f4482cfe678e40ecf9fa57b5d56218` |
| CI | passed |
| Release Check | passed |
| GitHub Release | not_created |
| Campaign 4 | not_started |

不得修改 `campaign-1-3-baseline`，不得创建新的 rc tag、stable tag、product version tag 或 GitHub Release。

## Campaign 顺序

| 顺序 | Campaign | 名称 | 允许开始条件 | 不得提前宣称 |
| --- | --- | --- | --- | --- |
| 1 | Campaign 4 | Goal-Oriented Product UI Workbench | Entry Gate passed | Bridge complete、Agent Runtime complete、EXE complete、Release complete |
| 2 | Campaign 5 | Chain-Level Local Core Bridge | Campaign 4 Review / Handoff Gate passed | Agent Runtime complete、Memory Runtime complete |
| 3 | Campaign 6 | Agent Foundation | Campaign 4 Page-Level UI Redesign owner visual acceptance、Campaign 4+5 UI-Bridge Realignment Gate accepted、Campaign 5 Review / Handoff Gate passed | Agent Runtime complete、Memory Runtime complete、Teams/Subagent complete、Sandbox complete、EXE complete |
| 4 | Campaign 7 | Configuration System Engineering | Campaign 6 Review / Handoff Gate passed | 首次加入 Agent 核心配置字段、Full Review complete、EXE complete |
| 5 | Campaign 8 | Full Testing / Full Review | Campaign 7 Review / Handoff Gate passed | Packaging complete、Release complete |
| 6 | Campaign 9 | EXE Packaging | Campaign 8 Review / Handoff Gate passed | GitHub Release complete |
| 7 | Final Release | GitHub Release after Campaign 9 acceptance | Campaign 9 Acceptance Gate passed | 无 |

当前 Campaign 未通过，不得进入下一个 Campaign。不得用计划文档、截图、局部 smoke、单条 green command 或 ignored generated evidence 代替实现验收。

## Campaign 6 专项开始锁

Campaign 6 不得因为 Campaign 4+5 acceptance report 中出现 `accepted_for_campaign_6_entry_gate` 而自动开始。Campaign 6 Entry Gate 只有在以下硬锁全部满足后才允许打开：

1. Campaign 4 Page-Level UI Redesign receives owner visual acceptance。
2. Campaign 4+5 UI-Bridge Realignment Gate is accepted。
3. Campaign 6 Entry Gate 冻结 simple-mode field matrix。
4. Campaign 6 Entry Gate 冻结 advanced-mode field matrix。
5. Campaign 6 Entry Gate 冻结 Agent schema。
6. Campaign 6 Entry Gate 为每个可见动作冻结 capability classification：`enabled_real`、`disabled_boundary`、`display_only` 或 `omitted`。

Campaign 6 内的删除行为只能是 archive 或 recoverable soft deletion，不得实现 irreversible physical deletion。

Campaign 6 必须闭环 Agent 定义所需的基础配置：模型、工具、权限、工作分区、简易模式字段、复杂模式字段、验证、保存、版本管理、预览和 Agent package 导出。不得把这些核心字段推迟到 Campaign 7 首次加入。

Campaign 7 只做配置系统工程化：Profile 文件化、配置来源优先级、加载、覆盖、合并、迁移、向后兼容、Secret 安全注入、诊断、Runtime availability check 和批量复用 Agent Profile。

## 每个 Campaign 的阶段

每个 Campaign 必须按以下阶段执行：

1. Entry Gate。
2. Implementation。
3. Acceptance Gate。
4. Review / Handoff Gate。

任何阶段失败时必须停止在当前 Campaign。CI failure、Release Check failure、clean checkout mismatch、Windows runner parity mismatch、429 或 timebox 超时都必须写入 checkpoint / failure_report，不得自动扩展范围或推进下一个 Campaign。

## 长任务顺序控制

- 单次无人值守任务最长 10 小时。
- 单次执行优先只跑一个 Campaign。
- 每 30-60 分钟写 checkpoint / resume prompt。
- 超过预估时间 50% 必须输出 progress report。
- 超过 timebox 必须停止并输出 failure_report。
- checkpoint 必须记录当前 Campaign、当前 Gate、当前状态、已完成内容、未完成内容、失败原因、下一安全动作、禁止动作、是否允许恢复执行。
- 所有 clean checkout / CI parity 验证必须前置，不能只相信污染工作区本地测试。

## 公共面顺序锁

`docs/治理/` 是本 Planning Gate 唯一允许的 governance documentation path。不得恢复旧英文 `docs/governance/`。

不得恢复或提交：

- `docs/product/`
- `docs/bridge/`
- `docs/governance/`
- `docs/testing/`
- `docs/audits/`
- `.agents/`
- tracked `artifacts/audits/` public evidence pile

运行证据只允许进入 ignored `artifacts/audits/current_run/` 或 campaign run output，不得进入 tracked main。

## JSON 顺序锁

Root-level JSON is limited to skill.json. Nested JSON is allowed only for code, tests, examples, packaging, schema, or runtime-required contracts.

root-only JSON 检查命令：

```powershell
git ls-files | Where-Object { $_ -match '^[^/\\]+\.json$' }
```

预期输出只允许：

```text
skill.json
```

不得使用 `git ls-files *.json` 判断 root-level JSON，因为 Git pathspec 可能匹配递归 JSON 文件。Tauri/package/example/schema/test/runtime-required contract JSON 不应被误杀，历史 report JSON 堆不得恢复。

## 外部参考顺序锁

TasteSkill、`openai/role-based-plugins`、`andrej-karpathy-skills`、CodeGraph、Understand Anything、Presenton、NVlabs/LongLive、claude-plugins-official、GBrain、HeiTang-governance-skill 只允许进入 reference queue 或 `needs_verification`。

不得把 `reference_only` 写成 `real_integration`，不得把 `needs_verification` 写成 `integrated`。真实接入必须另开 verification gate，核验 license、安装方式、依赖体积、安全风险、API/运行依赖、CI 成本和 EXE 体积影响。

## Campaign 4 专项锁

Campaign 4 的 UI 改动未来主要发生在 `kb-forge-skill-ui`，但本 Planning Gate 不修改 `kb-forge-skill-ui`。

Campaign 4 Entry Gate 前必须只读盘点：

- 页面结构。
- 导航数量。
- 组件状态。
- 现有未提交改动。
- 可复用组件。
- 不可复用组件。

当前已知 `kb-forge-skill-ui` 有未提交改动。后续不得将这些 dirty diff 直接视为 Campaign 4 正式实现。

## Stop Rule

本 Planning Gate 完成验证、commit、push 后立即停止。不得继续启动 Campaign 4 implementation，不得创建任何 tag，不得创建 GitHub Release，不得修改 UI 仓库。
