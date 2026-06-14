# Campaign 1-3 外部项目集成审查

本文件只保留公开主分支需要的简明边界。详细历史证据由 Git history 保存，不在 main 中保留审计堆。

| 项目 | 状态 | 当前边界 |
| --- | --- | --- |
| LLM Wiki v2 | real_integration | 本地记忆分离 / Knowledge Lifecycle 能力已纳入 Core |
| andrej-karpathy-skills | reference_only | Knowledge-to-Skill methodology reference，不是 runtime 接入 |
| Presenton | reference_only | Document/PPT workflow reference，不是 PPT runtime 接入 |
| CodeGraph | planned_not_active | 后续 codebase graph / developer knowledge map reference |
| Understand Anything | planned_not_active | 后续 interactive knowledge graph / Workbench UI reference |
| LongLive | stopped_or_rejected | 不进入当前产品路线，不做 GPU 视频生成 |
| claude-plugins-official | planned_not_active | future plugin ecosystem reference，不是插件 runtime |
| pi-mono | planned_not_active | future Agent Runtime architecture reference，不是当前 runtime |
| Redis / Vector DB memory store | planned_not_active | Campaign 8 future target，不属于 Campaign 1-3 已完成 |

补充状态词：`needs_verification` 项目只作为未来核查候选，不作为当前 runtime dependency。
