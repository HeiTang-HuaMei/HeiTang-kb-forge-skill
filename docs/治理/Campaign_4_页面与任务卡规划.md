# Campaign 4 页面与任务卡规划

## UI 原则

Campaign 4 UI 不是零散按钮堆叠，而是面向完整工作流的 Workbench。必须保留并继承现有 UI，不允许凭空重做。任何 UI 实现前必须先完成 `kb-forge-skill-ui` 只读 inventory。

本 Planning Gate 不修改 `kb-forge-skill-ui`。后续 Campaign 4 的 UI 改动主要发生在 `kb-forge-skill-ui`，且必须先审查当前未提交改动。

## Entry Gate UI Inventory

Campaign 4 Entry Gate 前必须盘点：

| 类别 | 盘点内容 | 决策输出 |
| --- | --- | --- |
| 页面结构 | 当前页面、模块、入口、路由或 selected index 组织方式 | 页面保留、合并、延后清单 |
| 导航数量 | 当前顶层导航数量与分组 | 不超过 7 个顶层入口 |
| 组件状态 | card、action、progress、report、error、settings 组件 | 可复用组件清单 |
| 未提交改动 | `git -C ..\kb-forge-skill-ui status --short` 和 diff summary | dirty diff review |
| 可复用组件 | 现有 Material UI、task/action panel、dashboard、settings、skill workflow 组件 | reuse plan |
| 不可复用组件 | 会造成 runtime overclaim、导航膨胀或假完成的组件 | defer / replace plan |

已知现状：

- `kb-forge-skill-ui` 已有未提交改动。
- 当前 UI 形态偏 `MaterialApp + StatefulWidget + setState/FutureBuilder`。
- 当前顶层页面数量超过 7，需要收敛。

## 顶层导航规划

Campaign 4 顶层导航不超过 7 个入口。建议规划为：

| 入口 | 目的 | 包含内容 |
| --- | --- | --- |
| 工作台首页 | 任务总览和下一步 | 当前任务、阻塞项、最近输出 |
| 导入与解析 | 输入材料到可解析内容 | 文件导入、parsing、OCR optional boundary |
| 知识构建 | 知识切分和知识包 | knowledge splitting、package draft、validation |
| Skill 生成 | Knowledge 到 Skill | Skill generation、Skill Suite draft |
| Agent | Agent Foundation / Agent Package Export | Agent 是一级功能区；当前真实能力只呈现 Agent package generation / export，不显示 runtime ready |
| 验证与报告 | evidence / report | validation、报告、失败矩阵 |
| 设置与运行边界 | 配置和能力边界 | optional dependency、runtime blocked reason、future bridge status |

以上只是 Campaign 4 UI workbench 导航规划，不代表 Bridge、Agent Runtime、Memory Runtime、EXE 或 Release 已完成。Agent package 只是 Agent 功能区当前可呈现的导出产物，不是一级产品概念本身。

## Task-card 驱动流程

每张 task-card 必须表达：

- 任务名称。
- 输入要求。
- 当前状态。
- 进度条。
- 可用动作。
- 失败原因。
- 下一安全动作。
- 产物或报告位置。
- 底层能力边界。

任务卡不得展示 fake completed states。没有真实底层能力时必须显示 pending、blocked 或 planned，不得显示 completed。

## 视觉层级

Campaign 4 页面必须有清晰视觉层级：

1. 输入区：文件、目录、工作区、配置 profile 或必要参数。
2. 任务进度区：当前 task-card、进度条、阶段、耗时。
3. 输出结果区：知识包、Skill draft、Agent package draft 或 validation output。
4. 证据/报告区：manifest、report、validation result、failure matrix。
5. 错误与重试区：failed / retryable / cancelled / blocked 状态和下一安全动作。

## 任务进度条

必须规划以下进度条：

| 进度 | 描述 | 不得宣称 |
| --- | --- | --- |
| 文件导入 | 从用户材料进入工作区 | 不宣称解析完成 |
| parsing | 解析、清洗、结构化 | 不宣称知识完成 |
| knowledge splitting | 切分、索引、知识包草稿 | 不宣称 Skill 完成 |
| Skill generation | Skill Template / Skill Suite 草稿生成 | 不宣称 Agent Runtime 完成 |
| Agent package generation | Agent Creation Package 草稿 | 不宣称 executable runtime |
| validation | manifest、report、failure matrix | 不宣称 Full Review 或 Release complete |

## 状态模型

所有任务卡必须支持：

- pending
- running
- completed
- failed
- retryable
- cancelled
- blocked

`completed` 只允许用于当前 Campaign 已实现且通过验收的任务。Campaign 4 UI 中未实现的 Bridge、Runtime、Memory、Multi-Agent executable、EXE、Release 必须显示 planned、pending 或 blocked，不得显示 completed。

## 美化与交互要求

- 使用一致的卡片间距、标题层级、状态色和进度表达。
- 重要任务显示下一安全动作。
- 阻塞任务必须显示 blocked reason。
- 错误任务必须显示 retry / cancel / view report 的交互规划。
- Campaign 4 UI 不得为了展示效果引入大型素材、重型图表库、视频资源或 GPU 依赖。
- 视觉优化必须服务于工作流理解，不得掩盖能力未完成状态。

## 外部 UI 参考候选

| 候选 | 用途 | 状态 | 禁止 |
| --- | --- | --- | --- |
| TasteSkill | Skill workflow、task-card interaction 参考 | `needs_verification` | 不直接 npm/npx 接入，不写成已集成 |
| `openai/role-based-plugins` | 设计 brief 到 prototype 参考 | `needs_verification` | 不写成 Figma/Canva/plugin marketplace 已接入 |
| Understand Anything | 项目关系可视化、UI 展示参考 | `reference_only` | 不作为已集成能力 |

所有参考候选必须后续另开 verification gate，核验 license、安装方式、依赖体积、安全风险、是否适合本项目 UI。

## 禁止 overclaim

Campaign 4 页面和任务卡不得宣称：

- Bridge complete。
- Agent Runtime complete。
- Memory Runtime complete。
- Multi-Agent executable complete。
- EXE packaging complete。
- GitHub Release complete。
