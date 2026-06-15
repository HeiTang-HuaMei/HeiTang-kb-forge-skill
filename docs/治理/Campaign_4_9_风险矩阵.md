# Campaign 4-9 风险矩阵

## 总体风险

| 风险 | 触发条件 | 防范规则 | 验收检查 | 失败后停止动作 |
| --- | --- | --- | --- | --- |
| 顺序漂移 | 当前 Campaign 未通过却进入下一 Campaign | 强制 Entry / Implementation / Acceptance / Review-Handoff 四段门禁 | 顺序锁审查、checkpoint 审查 | 停止在当前 Campaign，写 failure_report |
| 假完成 | `blocked`、`skipped`、`deferred` 写成 `passed` | 状态必须保留真实失败和阻塞 | 验收矩阵、failure matrix | 回滚错误状态，停止 |
| 假接入 | `reference_only` 或 `needs_verification` 写成 `integrated` | 外部项目先入 reference queue | 外部参考队列审查 | 移除集成声明，停止 |
| 本地假绿 | 污染工作区或 ignored evidence 让本地 pytest green | clean checkout / CI parity 前置 | clean worktree / clean clone pytest | 停止，记录 mismatch |
| 旧 public evidence 恢复 | 为兼容测试恢复 tracked artifacts / docs/audits | 运行证据只进 ignored runtime record | forbidden tracked paths check | 移除越界文件，停止 |
| root JSON 误杀或漏杀 | 使用 `git ls-files *.json` 当 root-only 检查 | 使用 root-only 正则命令 | root-only JSON check | 停止，修正检查命令 |
| GitHub tag 被误当 Release | tag 存在后宣称 Release complete | tag 和 GitHub Release 分开验收 | `gh release view` 非阻断检查 | 若 release 被误创，停止上报 |
| UI runtime overclaim | UI 显示 Bridge/Runtime/EXE 已完成 | Campaign 4 只做 UI workbench boundary | UI 文案审查、状态审查 | 停止，改回 planned / blocked |
| UI 仓库 dirty diff 混入 | 将既有 `kb-forge-skill-ui` dirty diff 当 Campaign 4 实现 | Entry Gate 前只读审查，不修改 UI 仓库 | `git -C ..\kb-forge-skill-ui status --short` | 停止，单独开 UI 审查 |
| future 功能堆叠 | 当前 UI 堆出 Teams/Subagent/Computer Use/Sandbox/A2A 等不可用功能 | future 能力优先 `omitted`，必要时只写最小 boundary | capability classification 审查 | 停止，改为 omitted 或 disabled_boundary |
| EXE 体积失控 | Campaign 4-8 引入重型 runtime 或素材 | optional / dependency-gated，size budget 前置 | dependency inventory、asset manifest | 停止，移除默认依赖 |

## 重复踩坑记忆区

| 历史踩坑 | 触发条件 | 防范规则 | 验收检查 | 失败后停止动作 |
| --- | --- | --- | --- | --- |
| stable tag 过早创建并失败 | 本地或局部 gate green 后直接 tag | 不允许本地 pytest green 后直接 tag | CI-equivalent clean clone / worktree 验证 | 停止，不再连续打 tag |
| 本地 ignored evidence 导致 pytest 假绿 | 测试依赖 ignored runtime 文件 | 不允许 ignored generated evidence 掩盖 clean checkout 问题 | clean checkout pytest | 停止，修测试兼容层 |
| clean checkout 和 GitHub CI 不一致 | 本地缓存、ignored 文件、环境差异 | CI parity 前置 | clean worktree pytest、Windows runner parity | 停止，记录 mismatch |
| `git ls-files *.json` 被误当 root-only JSON 检查 | Git pathspec 递归匹配 JSON | 使用 `git ls-files | Where-Object { $_ -match '^[^/\\]+\.json$' }` | 只输出 `skill.json` | 停止，修验收命令 |
| `session fixture` 太晚 | collection/import 阶段已需要兼容证据 | 兼容证据必须在 collection 前可用 | clean checkout test bootstrap | 停止，修 bootstrap |
| Release readiness 仍依赖旧英文 docs | 测试或脚本引用 `docs/governance` 等旧路径 | 只允许 `docs/治理/` 中文治理路径 | forbidden path check、docs structure tests | 停止，更新引用 |
| 旧 public evidence pile 被重新带回 main | 为兼容旧测试提交 `docs/audits` 或 `artifacts` | 兼容层可生成 ignored evidence，不得 track | `git ls-files artifacts docs/audits ...` 无输出 | 停止，移除 tracked evidence |
| 计划模式被误解为完全 read-only | Planning Gate 需要落地文档却没有写入 | Planning Gate 可生成允许文档，不启动 implementation | 8 个计划文档存在 | 停止，补文档 |
| UI 仓库存在 dirty diff | 未审查就开始 Campaign 4 | UI Entry Gate 前单独审查 dirty diff | UI status 只读记录 | 停止，开审查 gate |
| GitHub Release 与 tag 混淆 | tag 存在后宣称 release 完成 | Release 必须用 `gh release view` 验证 | release not found = pass for baseline | 停止，纠正文案 |

## Campaign 4 风险

| 风险 | 触发条件 | 防范规则 | 验收检查 | 失败后停止动作 |
| --- | --- | --- | --- | --- |
| 顶层导航继续膨胀 | 直接沿用现有多页面列表 | 顶层导航必须收敛到不超过 7 个入口 | UI inventory、导航规划审查 | 停止，重做导航规划 |
| 功能按钮堆叠 | 用按钮列表替代工作流 | 使用 task-card 驱动完整用户流程 | 页面与任务卡规划审查 | 停止，重做交互方案 |
| 无视觉层级 | 输入、进度、输出、证据、错误混杂 | 明确输入区、任务进度区、输出结果区、证据/报告区、错误与重试区 | UI focused tests / review | 停止，调整 UI plan |
| 假进度 | 没有真实任务状态却显示 completed | 不允许 fake completed states | 状态与进度条规范审查 | 停止，改为 pending / blocked |
| 高成本资源包 | 为展示效果引入大素材或重库 | Campaign 4 UI 不得引入高成本资源包 | dependency / asset inventory | 停止，移除资源 |

## Campaign 5-8 风险

| Campaign | 风险 | 防范规则 | 验收检查 | 失败后停止动作 |
| --- | --- | --- | --- | --- |
| Campaign 5 | 将孤立 CLI 调用写成 Core Bridge complete | Bridge 必须覆盖稳定任务链路，不允许 arbitrary shell execution | Bridge flow tests、allowlist review | 停止在 Campaign 5 |
| Campaign 6 | 将 Agent package 写成一级功能区或 executable runtime | Agent 是一级功能区；Agent package 只是导出产物；不宣称 runtime complete | Agent Foundation capability review、no-overclaim audit | 停止在 Campaign 6 |
| Campaign 6 | Agent Foundation 切得过细，完成后仍只是更复杂的 Agent 包生成器 | Campaign 6 必须闭环创建、模式、KB/Skill 绑定、基础模型/工具/权限/工作分区配置、验证、保存、预览、导出 | Campaign 6 acceptance matrix | 停止在 Campaign 6，不得推给 Campaign 7 |
| Campaign 6 | 实现不可逆物理删除 | 只允许 archive 或 recoverable soft deletion | deletion behavior tests、rollback review | 停止在 Campaign 6，移除物理删除 |
| Campaign 7 | 将 Agent 核心字段推迟到配置工程化阶段首次加入 | Campaign 7 只能工程化 Campaign 6 已定义配置 | profile lifecycle tests、field provenance review | 停止在 Campaign 7，退回 Campaign 6 |
| Campaign 7 | 将硬编码配置写成配置系统 | 配置必须 Profile 化并验证 secret boundary | configuration tests、secret boundary tests | 停止在 Campaign 7 |
| Campaign 8 | 用 Fast Gate 代替 Full Review | Full Review 必须含 clean clone、Windows runner、UI-Core、docs consistency | full gate evidence | 停止在 Campaign 8 |
| Campaign 8 | 在 Full Review 中补做缺失的大型 Campaign 6/7 能力 | Campaign 8 只修缺陷和一致性；大型缺失必须退回 owning Campaign | capability gap review、handoff evidence | Fail review，退回所属 Campaign |

## Campaign 9 EXE 体积风险

| 风险 | 触发条件 | 防范规则 | 验收检查 | 失败后停止动作 |
| --- | --- | --- | --- | --- |
| EXE 过大 | 重型 runtime、模型、素材、历史审计文件进入包 | size budget 前置，optional dependency exclusion list | package size report、asset manifest | 停止，缩减包 |
| 默认依赖过重 | OCR、视频、PPT、GPU、外部 runtime 默认启用 | 默认 optional / dependency-gated | dependency inventory | 停止，改为 optional |
| 测试文件进包 | examples、fixtures、历史 report JSON 被打包 | packaging allowlist | package manifest diff | 停止，修 package manifest |
| 只做临时压缩包 | 未验证 clean machine run | Campaign 9 必须含 portable、installer 评估、launch smoke、clean machine smoke | launch smoke、clean machine smoke | 停止，不得 release |

## HeiTang-governance-skill 参考边界风险

| 风险 | 触发条件 | 防范规则 | 验收检查 | 失败后停止动作 |
| --- | --- | --- | --- | --- |
| 参考变依赖 | 将 HeiTang-governance-skill 加入 runtime dependency | 只作为治理方法论参考 | dependency diff | 停止，移除依赖 |
| 复制目录结构 | 为借鉴治理思想复制其目录 | 不复制目录结构，不恢复旧 evidence pile | public surface check | 停止，移除目录 |
| 写成已集成 | 文档宣称 governance skill 已接入 | 状态只能是 `reference_only` | 文案审查 | 停止，改文案 |
