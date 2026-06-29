# V1 Acceptance and Hardening Master Plan

## 1. 当前阶段定义

当前阶段：

`v1_package_gate_evidence_committed_pending_final_owner_review_preparation_authorization`

当前事实：

- Package Gate 已通过。
- DeepSeek 已确认 `PASS_PACKAGE_GATE_RESULT`。
- 当前 commit：`99a5a29 docs: record v1 package gate result evidence`。
- `capability_chain_status.json` diff empty。
- ready-claim scan clean / non-claim only。
- Computer Use 自动验收已有部分证据，但仍有缺口。
- 当前不能直接进入 Final Owner Review。
- 当前目标是生成完整验收与深水测试计划。

Computer Use 当前缺口：

1. NSIS installer wizard 未完全自动化验收。
2. Agent 新建助手 / 未配置模型服务失败态未在 packaged shell 中自动化验收。

## 2. V1.0 产品定位

V1.0 定义为：

本地可安装、主链路可跑、失败可解释、证据可追溯、后续可演进的稳定基线版本。

V1.0 不等于：

- 完整商业版
- 全功能 AI 知识供应链
- `production_ready`
- `release_ready`
- `runtime_ready`
- V1.1/V1.2/V2 能力完成

## 3. V1.0 必过验收范围：L0 Baseline Acceptance

L0 是 V1.0 Final Owner Review 前的必过验收。

### L0-1 安装包验收

验收项：

- NSIS EXE 是否存在
- 文件路径、大小、hash、时间戳是否记录
- Package Gate exit code 是否为 0

通过标准：

- EXE 存在
- Package Gate B1 retry2 exit code = 0
- 无 tracked drift
- `capability_chain_status.json` diff empty
- ready-claim scan clean

失败标准：

- EXE 缺失
- exit code 非 0
- build 后出现 tracked code/config drift
- 状态文件污染
- ready 正向声明污染

### L0-2 启动 / 关闭验收

验收项：

- packaged app 能否启动
- 是否白屏 / 黑屏 / 崩溃
- 是否能正常关闭

通过标准：

- 应用窗口打开
- 页面可见
- 关闭行为正常

失败标准：

- 启动失败
- 白屏 / 黑屏
- 关闭崩溃
- 退出异常无法解释

### L0-3 页面入口验收

验收项：

- 首页 / Dashboard
- 资料导入 / 文档库
- 知识库
- 成果 / Artifact
- Skill
- Agent
- 设置
- 任务工作台，如当前 UI 有入口

通过标准：

- 可点击
- 页面不崩
- 空状态可读
- 不出现内部异常词

失败标准：

- 点击崩溃
- 页面空白
- 内部错误直接暴露给用户

### L0-4 Agent 失败态验收

验收项：

- 进入 Agent / 新建助手入口
- 未配置模型服务时触发失败态

预期：

- 显示用户友好提示，例如“请先配置模型服务”
- 不暴露 Provider / Adapter / stack trace / internal exception

证据来源：

- packaged app Computer Use，如可自动化
- widget_test 证据，如 packaged shell 无法触达
- Owner spot-check，如自动化仍无法覆盖

### L0-5 状态与证据安全

验收项：

- `capability_chain_status.json` diff
- ready-claim scan
- git status
- Package Gate evidence
- DeepSeek evidence

通过标准：

- `capability_chain_status.json` empty diff
- ready-claim scan clean / non-claim only
- 不出现 `production_ready` / `release_ready` / `runtime_ready` / `final_owner_review_passed` 正向声明
- push/tag/release/Final Owner Review 均未执行

## 4. Computer Use Acceptance Gap Closure：L0 补证计划

当前 Computer Use 已完成：

- packaged app launch captured
- 11 visible navigation entries captured
- screenshots captured
- internal-error-term scan captured
- close behavior captured

当前缺口：

1. NSIS installer wizard 未完全自动化。
2. Agent missing-model failure state 未在 packaged shell 中自动化。

### Gap A：NSIS Installer Wizard

操作：

- 尝试启动安装器。
- 捕获安装向导首页 / 安装路径页 / 完成页。
- 不要求覆盖安装已有应用，避免破坏环境。

结果分类：

- pass
- blocked
- needs_owner_spot_check

如果无法自动化：

- 记录原因。
- 降级为 Owner spot-check。
- 不阻塞全部 V1，除非安装器根本无法打开。

### Gap B：Agent Missing-Model Failure State

操作：

- 进入 Agent / 技能与助手 / 新建助手入口。
- 尝试触发未配置模型服务提示。

预期：

- 用户友好提示。
- 不暴露 Provider / Adapter / stack trace / internal exception。

如果 packaged shell 无法触达：

- 引用 widget_test 证据。
- 标记 Owner spot-check。
- 不直接判定产品失败。

输出文件：

- `reports/V1_COMPUTER_USE_ACCEPTANCE_GAP_CLOSURE_REPORT.md`
- `reports/V1_COMPUTER_USE_ACCEPTANCE_GAP_CLOSURE_DEEPSEEK_PACKET.md`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/`

完成状态：

- `v1_computer_use_acceptance_gap_closed_pending_deepseek_review`
- `v1_computer_use_acceptance_gap_partially_closed_pending_owner_spot_check`
- `v1_computer_use_acceptance_gap_blocked_pending_owner_decision`

## 5. Final Owner Review Preparation Pack

生成：

`reports/V1_FINAL_OWNER_REVIEW_PREPARATION_PACK.md`

必须包含：

1. V1.0 范围定义
2. 当前已落地能力清单
3. 当前未落地 / 后续版本能力清单
4. L0 验收矩阵
5. Computer Use 证据索引
6. Package Gate 证据索引
7. DeepSeek 外审结论
8. 风险清单
9. Owner 抽查清单
10. 最终三选一结论模板

Final Owner Review 结论只能是：

- `PASS_FINAL_OWNER_REVIEW`
- `CONDITIONAL_PASS_WITH_FIXES`
- `BLOCK_V1_ACCEPTANCE`

注意：

Final Owner Review Preparation Pack 不是 Final Owner Review 本身。

## 6. V1.0 后置深水测试：L1 Post-Package Hardening Test

L1 不是 V1.0 默认必过项。

L1 用于发现真实使用中的 P0/P1/P2 风险。

输出文件：

`reports/V1_POST_PACKAGE_HARDENING_TEST_PLAN.md`

### L1-1 合并逻辑 / 删除假象测试

目标：

验证知识库合并后旧知识库状态是否一致。

测试点：

- 导入 PDF A，生成知识库 003。
- 导入 PDF B，合并生成知识库 005。
- 检查 UI 列表。
- 检查后台 manifest / catalog / database / vector index 中 003 的状态。

Checkpoint A：

- 003 是否只是 UI 不显示。
- 003 是否有 is_deleted。
- 003 是否物理残留。
- 005 是否正确继承 source lineage。

使坏操作：

- 合并过程中断网。
- 合并过程中强杀 EXE。
- 重启后检查是否回滚或进入一致状态。

失败标准：

- 003 半删除。
- 005 半生成。
- source_trace 丢失。
- 重启后状态不一致。
- UI 与后台状态不一致。

风险等级：

- 数据损坏：P0，阻塞 V1.0。
- 追溯粒度不足：P2，进入 V1.2。
- UI 刷新异常：P1/P2，按影响判断。

### L1-2 RAG 未命中拒答 / 幻觉测试

目标：

验证知识库未包含内容时是否拒答。

测试点：

- 问 003 未放入的问题。
- 问 005 里属于 003 老内容的问题。
- 检查答案和 citation。

通过标准：

- 未命中时明确说未找到。
- 命中时能引用来源。
- citation 能追到 source document / section / chunk。

失败标准：

- 未命中直接编造：P0/P1。
- 答案正确但 citation 错：P1/P2。
- citation 只能指向合并后 KB，不能追原文：V1.2 source_trace backlog。

### L1-3 Skill 快照 / 指针策略测试

目标：

验证 Skill 生成后是否依赖原始 PDF。

操作：

- 从 PDF 生成 skill02。
- 删除原始 PDF。
- 用 skill02 绑定 Agent。
- 触发问答。

结果分类：

- Skill 仍可用：说明有快照。
- Skill 失效：说明只存指针。
- UI 提示清楚：可接受。
- UI 无提示直接报错：P1。

判断：

- 设计上快照或指针都可行。
- 但必须明确策略。
- 如果 UI 宣称“沉淀复用能力”，但删除源文档后 Skill 失效且无提示，应进入 V1.2/V1.3 修复。

### L1-4 小组模式生成 PDF 并发测试

目标：

验证重复点击生成 PDF 是否导致 UI 卡死或文件污染。

使坏操作：

- 在小组模式讨论中连续快速点击“生成 PDF”5 次。

通过标准：

- 按钮进入 loading/disabled。
- 提示任务已提交。
- 不生成重复垃圾文件。
- 不白屏 / 不崩溃。

失败标准：

- 白屏 / 卡死：P0/P1。
- 生成 5 个重复无管理文件：P2。
- 覆盖文件但无提示：P2。
- 任务状态错乱：P1。

### L1-5 内存曲线测试

目标：

验证导入 PDF、解析、生成读书笔记后内存是否释放。

操作：

- 打开任务管理器性能面板。
- 记录 idle baseline。
- 导入 PDF。
- 构建知识库。
- 生成读书笔记。
- 关闭子窗口回到主界面。
- 记录内存回落情况。

失败标准：

- 内存只涨不降。
- 多轮操作持续增长。
- 关闭窗口后资源不释放。
- 长时间运行后卡死。

风险等级：

- 明显泄漏：P0/P1。
- 轻微增长：P2。
- 需长期压测：V1.1/V1.2 hardening backlog。

## 7. 风险分级标准

P0：

- EXE 无法启动。
- 白屏 / 黑屏。
- 数据损坏。
- 状态文件污染。
- 关键主链路不可用。
- 删除 / 合并导致不可恢复错误。
- 明显幻觉且无拒答保护。

是否阻塞 V1.0：

是。

P1：

- 主链路行为明显错误。
- 失败态吓人。
- 重复操作导致崩溃。
- 引用严重错乱。
- Skill / Agent 失效但 UI 未提示。

是否阻塞 V1.0：

Owner 判断。

P2：

- UI 文案不清。
- 来源粒度不足。
- 文件重复管理不优雅。
- 部分后续能力未完全可操作。

是否阻塞 V1.0：

否，进入 V1.1/V1.2。

P3：

- UI polish。
- 性能优化。
- 架构债。
- 内部代码拆分。

是否阻塞 V1.0：

否，后续版本处理。

## 8. 当前落地能力 vs 后续版本

### V1.0 当前落地

- 本地 EXE 打包链路。
- Package Gate。
- 应用可启动证据。
- 主要导航入口截图证据。
- Agent missing-model widget test 证据。
- rc6 regression。
- widget_test。
- flutter analyze。
- npm typecheck。
- capability_chain_status safety。
- ready-claim safety。
- DeepSeek Package Gate 外审。

### V1.0 待补证

- NSIS installer wizard 自动化或 Owner spot-check。
- packaged shell 中 Agent missing-model failure state 自动化或 Owner spot-check。
- Final Owner Review Preparation Pack。

### V1.1

Product Workflow Operator Thinning：

- workflow/operator 瘦身。
- actions / sections / state helpers / text constants。
- 不改变产品行为。
- 保持测试稳定。

### V1.2

Implemented Capability -> UI Operability Matrix：

- 已实现能力盘点。
- UI 是否可操作。
- 用户入口在哪。
- 产物是否可见。
- 是否可导出。
- source_trace / evidence 是否可见。
- 任务工作台表达改为：基础准备 -> 并列产物 -> 成果管理。

### V1.2 / V1.3

OKF Semantic Chunking：

- ParsedDocument canonical structure。
- OKF semantic chunks。
- source_doc_id。
- block_ids。
- heading_path。
- semantic_unit_type。
- source_trace_id。
- lineage。

### V2

Modular Runtime Architecture：

- repository extraction。
- service extraction。
- Rc6RuntimeController thinning。
- runtime module boundary。
- 更完整的数据一致性 / 合并 / 删除 / 追溯测试。

## 9. 推荐执行顺序

必须按以下顺序：

1. Computer Use Acceptance Gap Closure。
2. DeepSeek Computer Use Acceptance Review。
3. Final Owner Review Preparation Pack。
4. Owner 抽查。
5. Owner 给出 Final Owner Review 结论。
6. 如通过，再决定是否 push/tag/release。
7. V1 Post-Package Hardening Test Plan。
8. Owner 决定是否执行 L1 深水测试。
9. L1 测出 P0/P1/P2 后，按风险分级进入：
   - V1.0 blocker fix。
   - V1.1。
   - V1.2。
   - V1.3。
   - V2。

## 10. 当前禁止事项

- 不直接进入 Final Owner Review。
- 不 release。
- 不 tag。
- 不 push。
- 不声明 `production_ready`。
- 不声明 `release_ready`。
- 不声明 `runtime_ready`。
- 不把 L1 深水测试当成 V1.0 默认必过。
- 不把 V1.1/V1.2/V2 能力塞回 V1.0。
- 不修改 `capability_chain_status.json`。

## 11. 本计划生成后的完成状态

完成状态：

`v1_acceptance_and_hardening_master_plan_created_pending_owner_scope_decision`
