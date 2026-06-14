# Campaign 6 外部运行时参考队列

## 定位

本文件登记 Campaign 6 Agent Runtime / Memory 及相关后续 Campaign 的外部参考候选。所有项目默认是 `reference_only` 或 `needs_verification`，不得直接接入，不得声明已集成，不得写成已完成 runtime。

真实接入必须另开 verification gate，核验 license、安装方式、依赖体积、安全风险、API/运行依赖、活跃度、官方性、CI 成本、Windows 可运行性和 EXE 体积影响。

## 候选队列

| 候选 | 用户提供地址或名称 | 用途 | 建议级别 | 状态 | 禁止 |
| --- | --- | --- | --- | --- | --- |
| GBrain | `https://github.com/garrytan/gbrain` | Campaign 6 Agent Runtime / Memory / graph-style reasoning 参考 | A / runtime-memory reference candidate | `needs_verification` | 不得直接接入；不得写成已完成 memory runtime |
| CodeGraph | CodeGraph | 代码知识图谱、项目结构理解、Campaign 5/8 审查辅助 | A / architecture reference candidate | `reference_only` | 不得作为 Campaign 4 runtime 依赖 |
| claude-plugins-official | claude-plugins-official | 插件化工作流、工具链集成参考 | A / plugin workflow reference candidate | `reference_only` | 不得声明与 Claude 插件系统兼容或已接入 |
| `andrej-karpathy-skills` | andrej-karpathy-skills | Skill 规则组织、MD-based assistant rules 参考 | S / core methodology reference candidate | `reference_only` | 不得直接复制规则体系 |
| Understand Anything | Understand Anything | 代码库导航、项目关系可视化、Campaign 4/8 UI 展示参考 | A / UI-workflow reference candidate | `reference_only` | 不得作为已集成能力 |
| Presenton | Presenton | PPT 生成、后续输出格式扩展参考 | B/A / post-v4 output reference candidate | `reference_only` | 不进入 Campaign 4 核心路径 |
| NVlabs/LongLive | NVlabs/LongLive | 长视频生成、高性能模型工程参考 | future reference only | `future_reference_only` | 不得进入 EXE 默认依赖，不得进入 Campaign 4-7 主路径 |
| TasteSkill | `https://github.com/Leonxlnx/taste-skill` | Campaign 4 UI / Skill workflow / task-card interaction 参考 | UI-workflow reference candidate | `needs_verification` | 不得直接 npm/npx 接入生产流程 |
| `openai/role-based-plugins` | `https://github.com/openai/role-based-plugins` | 设计 brief 到 prototype 流程参考 | design workflow reference candidate | `needs_verification` | 不得把 Figma/Canva/plugin marketplace 能力写成已接入 |
| HeiTang-governance-skill | HeiTang-governance-skill | LongRun、Scope Lock、Evidence Gate、Pitfall Memory 治理参考 | governance reference candidate | `reference_only` | 不得作为 runtime dependency，不复制目录结构 |

## Verification Gate 要求

任何候选从 reference queue 进入真实接入前，必须核验：

- license。
- 安装方式。
- 依赖体积。
- 安全风险。
- API / CLI 行为。
- 是否需要外部服务。
- Windows runner 可用性。
- clean checkout 可复现性。
- CI 成本。
- EXE 打包体积影响。
- optional / dependency-gated 方案。

未通过 verification gate 的项目不得写成 `integrated`、`ready`、`complete` 或 `runtime dependency`。

## Campaign 6 Runtime 边界

Campaign 6 才允许进入 Agent Runtime / Memory。Campaign 4/5 中不得提前声明：

- Agent Runtime complete。
- Memory Runtime complete。
- Redis / Vector DB memory runtime complete。
- Multi-Agent executable complete。
- external runtime integrated。

Agent package 只是 package/spec/handoff，不等于 executable runtime。

## EXE 体积边界

所有外部 runtime 候选默认不得进入 EXE 默认依赖：

- OCR、视频、PPT、GPU、外部 runtime 必须 optional / dependency-gated。
- 大型模型、示例素材、历史审计文件、测试 fixture 不得打进 EXE。
- NVlabs/LongLive 只能是 future reference，不得进入 Campaign 4-7 主路径或 Campaign 9 默认包。
- Presenton 只能作为后续输出扩展参考，不进入 Campaign 4 核心路径。

Campaign 9 前必须建立 size budget、dependency inventory、asset manifest、optional dependency exclusion list。

## HeiTang-governance-skill 借鉴

Campaign 6 及后续 Campaign 可以借鉴 `HeiTang-governance-skill` 的治理思想：

- LongRun Guard。
- Scope & Plan Lock Guard。
- Implementation Reality Guard。
- Evidence & Test Gate Guard。
- Integration Boundary Guard。
- Pitfall Memory Guard。
- Full Guard Profile。
- checkpoint / resume / next-safe-action 机制。

但不得将其作为 `kb-forge-skill` runtime dependency，不得复制其目录结构，不得恢复当前项目已经清理掉的旧 evidence pile。若后续需要真实接入，必须另开 verification gate。

## 状态转换规则

| 当前状态 | 允许下一状态 | 条件 |
| --- | --- | --- |
| `reference_only` | `needs_verification` | 用户或计划明确进入验证队列 |
| `needs_verification` | `verified_candidate` | verification gate 全部通过 |
| `verified_candidate` | `integration_planned` | 对应 Campaign Entry Gate 通过 |
| `integration_planned` | `integrated` | 实现完成且 Acceptance Gate 通过 |

不得跳过验证直接进入 `integrated`。
