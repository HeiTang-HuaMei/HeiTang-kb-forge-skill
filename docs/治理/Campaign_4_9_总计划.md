# Campaign 4-9 总计划

## 任务边界

本文件定义 Campaign 4-9 Master Planning Gate。它只承接 Campaign 1-3 稳定基线后的后续路线，不启动 Campaign 4 implementation，不进入 Campaign 5/6/7/8/9 implementation，不创建 GitHub Release，不创建 rc tag、stable tag 或 product version tag，不修改 `campaign-1-3-baseline`。

稳定基线：

| 项目 | 状态 |
| --- | --- |
| stable tag | `campaign-1-3-baseline` |
| commit | `8559eb57b0f4482cfe678e40ecf9fa57b5d56218` |
| CI | passed |
| Release Check | passed |
| GitHub Release | not_created |
| Campaign 4 | not_started |

Campaign 4-9 不得推翻 Campaign 1-3 成果：v4.2 clean public repository reset、中文治理文档结构、root-level JSON only `skill.json`、forbidden legacy tracked paths 不得恢复、旧审计证据不再作为 public main 文件堆、运行证据只进入 ignored runtime record，以及当前产品定位为 Agent 知识供应链底座而不是单纯文档转知识库工具。

## 产品方向

产品趋势判断：AI 工具正在从单点功能转向完整工作流整合。

对应到 HeiTang KB Forge：

| Campaign | 方向 | 边界 |
| --- | --- | --- |
| Campaign 4 | 完整 UI Workbench | 只做 UI workbench planning / UI implementation boundary；未来主要改动在 `kb-forge-skill-ui` |
| Campaign 5 | 稳定 Core Bridge | 不在 Campaign 4 宣称 Bridge complete |
| Campaign 6 | Agent Foundation 完整闭环 | Agent 是一级功能区；Agent package 只是导出产物；必须闭环创建、模式、绑定、基础配置、验证、保存、预览和导出 |
| Campaign 7 | Configuration System Engineering | 只工程化 Campaign 6 已定义配置；不得首次加入模型、工具、权限、工作分区或模式核心字段 |
| Campaign 8 | clean clone / Windows runner / UI-Core / docs consistency 全面审查 | 不用局部 smoke 代替 Full Review；不得补做缺失的大型 Campaign 6/7 能力 |
| Campaign 9 | 可下载、可运行、可校验的 Windows EXE 包 | 不提前宣称 EXE packaging 或 GitHub Release complete |
| Final Release | Campaign 9 acceptance 后发布 | 不在 Campaign 9 前创建 GitHub Release |

## 顺序总锁

1. Campaign 4：Goal-Oriented Product UI Workbench。
2. Campaign 5：Chain-Level Local Core Bridge。
3. Campaign 6：Agent Foundation。
4. Campaign 7：Configuration System Engineering。
5. Campaign 8：Full Testing / Full Review。
6. Campaign 9：EXE Packaging。
7. Final Release：Campaign 9 acceptance 后才允许开始。

当前 Campaign 未通过，不得进入下一个 Campaign。CI、Release Check、clean checkout mismatch 或 429 失败后必须停止，不得自动继续修到下个阶段。

## Owner 批准后的 Campaign 6+ 纠偏锁

Campaign 6 只有在以下条件全部满足后才允许开启：

1. Campaign 4 Page-Level UI Redesign 获得 owner visual acceptance。
2. Campaign 4+5 UI-Bridge Realignment Gate accepted。
3. Campaign 6 Entry Gate 冻结 simple-mode field matrix、advanced-mode field matrix、Agent schema。
4. Campaign 6 Entry Gate 为每个可见动作冻结 capability classification：`enabled_real`、`disabled_boundary`、`display_only` 或 `omitted`。

Campaign 6 必须一次完成 Agent Foundation 完整用户链路：

```text
创建 Agent
→ 选择简易模式或复杂模式
→ 绑定知识库和多个 Skill
→ 配置模型、工具、权限和工作分区
→ 验证
→ 保存 / 版本管理
→ 预览
→ 导出 Agent package
```

Campaign 6 必须包含 Agent 创建、编辑、复制、版本管理、简易模式、复杂模式、知识库绑定、多 Skill 绑定、基础模型配置、基础工具配置、基础权限配置、工作分区声明、Agent spec / manifest、保存、验证、预览和导出。Agent package 只是 Agent 的导出产物，不得作为一级功能区名称。

Campaign 6 删除行为只允许 archive 或 recoverable soft deletion。不得实现不可逆物理删除。

Campaign 7 只承接配置系统工程化：Profile 文件化、配置来源优先级、加载与合并、迁移和向后兼容、Secret 安全注入、配置诊断、Runtime availability check、批量复用 Agent Profile。Campaign 7 不得首次加入模型配置、工具配置、权限配置、工作分区、简易模式或复杂模式核心字段。

工作分区边界：

- Campaign 6：工作分区模型、权限声明、路径绑定。
- Campaign 7：配置加载、迁移、诊断、复用。
- Post-9：真实运行隔离、Sandbox 和跨 Agent 共享执行。

Campaign 8 允许修复缺陷和一致性问题，但不得实现缺失的大型 Campaign 6/7 能力。若 Full Review 发现大型能力缺失，必须失败并退回所属 Campaign。

Agent Teams、Subagent 策略、Memory Runtime、Compaction、Model Router runtime、Computer Use、Sandbox、A2A 和真实跨 Agent 执行均后置到 Post-9 或独立 future gate。当前 UI 中 future 能力优先 `omitted`，不得堆叠成一页不可用功能。

## 长任务保障

本 Planning Gate 自身有 90 分钟 timebox。若 8 个计划文档、验证、commit、push 未在 90 分钟内完成，必须停止，只允许写 ignored runtime `failure_report`，不得扩展范围。

Campaign 4-9 后续长任务规则：

- 单次无人值守任务最长 10 小时。
- 单次执行优先只跑一个 Campaign。
- 每 30-60 分钟写入 checkpoint / resume prompt。
- 每个 Campaign 必须拆成 Entry Gate、Implementation、Acceptance Gate、Review / Handoff Gate。
- checkpoint 必须记录当前 Campaign、当前 Gate、当前状态、已完成内容、未完成内容、失败原因、下一安全动作、禁止动作、是否允许恢复执行。
- 若任务超过预估时间 50%，必须输出 progress report。
- 若超过 timebox，必须停止并输出 failure_report，不得自动继续。
- 所有 clean checkout / CI parity 验证必须前置，不能只相信污染工作区本地测试。

运行证据只允许进入 ignored `artifacts/audits/current_run/` 或 campaign run output，不得成为 tracked public evidence pile。

## 公共仓库面

`docs/治理/` 是本 Planning Gate 唯一允许的 governance documentation path。不得恢复旧英文 `docs/governance/`。

不得恢复或提交：

- `docs/product/`
- `docs/bridge/`
- `docs/governance/`
- `docs/testing/`
- `docs/audits/`
- `.agents/`
- tracked `artifacts/audits/` public evidence pile

Root-level JSON is limited to skill.json. Nested JSON is allowed only for code, tests, examples, packaging, schema, or runtime-required contracts.

嵌套 JSON 可以用于 Tauri/package/example/schema/runtime-required contract，但不得引入历史 report JSON 堆。

## Campaign 4 UI 总边界

Campaign 4 不是零散按钮堆叠，而是完整工作台规划。它必须保留并继承现有 UI，不凭空重做。Campaign 4 Entry Gate 前必须只读盘点 `kb-forge-skill-ui` 的页面结构、导航数量、组件状态、现有未提交改动、可复用组件和不可复用组件。

已知只读盘点结论：

- `kb-forge-skill-ui` 当前已有未提交改动，后续 Campaign 4 Entry Gate 前必须单独审查。
- 当前 UI 形态偏 `MaterialApp + StatefulWidget + setState/FutureBuilder`。
- 当前导航数量超过 Campaign 4 目标上限，Campaign 4 顶层导航必须收敛到不超过 7 个入口。

Campaign 4 不得宣称 Bridge complete、Agent Runtime complete、Memory Runtime complete、Multi-Agent executable complete、EXE packaging complete 或 GitHub Release complete。

## Campaign 9 体积预控

Campaign 9 虽然后置，但 Campaign 4-8 必须提前控制 EXE 体积风险：

- 不得在 Campaign 4-8 随意引入重型 runtime。
- OCR、视频、PPT、GPU、外部 runtime 能力默认 optional / dependency-gated。
- 不得把大型模型、示例素材、历史审计文件、测试 fixture 打进 EXE。
- Campaign 4 UI 不得为了展示效果引入高成本资源包。
- EXE 打包前必须建立 size budget。

Campaign 9 必须包含 portable package 方案、installer 方案评估、asset manifest、checksum、dependency inventory、optional dependency exclusion list、launch smoke、clean machine smoke。

## 外部参考队列

以下项目只作为 reference queue 或 `needs_verification` 候选，不作为当前 Campaign 4 implementation 依赖，不得写成已集成：

| 候选 | 用途 | 状态 | 禁止 |
| --- | --- | --- | --- |
| TasteSkill | Campaign 4 UI / Skill workflow / task-card interaction 参考 | `needs_verification` | 不得直接 npm/npx 接入生产流程 |
| `openai/role-based-plugins` | 设计 brief 到 prototype 流程参考 | `needs_verification` | 不得写成 Figma/Canva/plugin marketplace 已接入 |
| `andrej-karpathy-skills` | Skill 规则组织、MD-based assistant rules 参考 | `reference_only` | 不得直接复制规则体系 |
| CodeGraph | 代码知识图谱、项目结构理解、Campaign 5/8 审查辅助 | `reference_only` | 不得作为 Campaign 4 runtime 依赖 |
| Understand Anything | 代码库导航、关系可视化、Campaign 4/8 UI 展示参考 | `reference_only` | 不得写成已集成能力 |
| Presenton | PPT 生成、后续输出格式扩展参考 | `reference_only` | 不进入 Campaign 4 核心路径 |
| NVlabs/LongLive | 长视频生成、高性能模型工程参考 | `future_reference_only` | 不进入 EXE 默认依赖或 Campaign 4-7 主路径 |
| claude-plugins-official | 插件化工作流、工具链集成参考 | `reference_only` | 不声明与 Claude 插件系统兼容或已接入 |
| GBrain | Post-9 Agent runtime / Memory / graph-style reasoning 参考 | `needs_verification` | 不得直接接入或写成 memory runtime complete |
| HeiTang-governance-skill | Campaign 4-9 治理方法论参考 | `reference_only` | 不得作为 runtime dependency 或复制目录结构 |

## HeiTang Governance Skill 借鉴边界

Campaign 4-9 借鉴 `HeiTang-governance-skill` 的治理思想，但不得作为本项目运行时依赖直接接入。若后续需要真实接入 governance skill，必须另开 verification gate，核验 license、安装方式、CLI 行为、体积、依赖、安全边界和 CI 成本。

必须吸收：

- LongRun Guard。
- Scope & Plan Lock Guard。
- Implementation Reality Guard。
- Evidence & Test Gate Guard。
- Integration Boundary Guard。
- Pitfall Memory Guard。
- Full Guard Profile。
- checkpoint / resume / next-safe-action 机制。
- 假完成、漏测试、假接入、目标漂移、重复踩坑防控规则。

## 完成条件

本 Planning Gate 只在以下条件全部满足后完成：

1. 8 个中文计划文档位于 `docs/治理/`。
2. 未修改 `kb-forge-skill-ui`。
3. 未创建 GitHub Release、rc tag、stable tag、product version tag。
4. 未恢复 forbidden legacy tracked paths。
5. root-level JSON 仍只有 `skill.json`。
6. 指定验证通过。
7. 只提交并推送 8 个允许计划文档的新增或更新。
