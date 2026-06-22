# 工业级验收缺口修补计划

生成日期：2026-06-22

Gate：`industrial_acceptance_gap_repair_gate`

## 收敛原则

本 Gate 只修补工业级黑盒验收覆盖缺口，不把未完成能力强行补成已完成。

```text
已承诺可用能力：必须通过 Windows EXE 黑盒自动化验证。
未完整落地能力：必须显示为需要设置 / 暂不可用 / 本地模式，并在报告中标记 gated / not_implemented / blocked。
不得伪造成果中心数据。
不得伪造使用记录。
不得把 gated 能力写成 passed。
```

适用 gated 能力包括：

```text
热插拔配置的细粒度目录/Skill/Agent/记忆隔离
A2A / 多助手协作依赖项
Redis / 向量库外部记忆服务
外部 Skill 导入
DOCX / PDF / PPTX 导出
外部链接读取 / OCR
```

## 修补清单

| 阻断项 | 当前状态 | 根因 | 修补方式 | 涉及页面 | 涉及脚本 | 是否改产品代码 | 是否改 UI 视觉 | 预期验证方式 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 逐按钮全量 EXE UI 点击矩阵未完成 | 主链路按钮已验证，完整按钮矩阵不足 | Windows 原生自动化无法可靠读取 Flutter 控件语义树 | 采用页面相对坐标、稳定快捷键、真实产物与 audit 记录交叉验证；未配置按钮标记 gated | 11 个主页面 | `run_button_matrix.ps1`、`run_windows_exe_smoke.ps1 -Mode button_matrix` | 否，沿用已补自动化识别入口 | 否 | 生成 `button_acceptance_matrix.json` 与中文矩阵报告 |
| 使用记录逐条机器映射不足 | 使用记录页面可打开，但旧 smoke 依赖产物推断 | 缺少动作到记录字段的机器级映射 | 使用 `audit_report.json` 中 `action_type/time/object/result` 字段逐项映射；可选能力只标记 gated | 使用记录、成果中心、设置 | `run_usage_mapping_matrix.ps1` | 是，补真实 usage event 字段，不写静态假数据 | 否 | 生成 `usage_record_mapping_results.json` 与中文报告 |
| 异常输入 / 边界输入未完成 EXE 自动化 | 核心真实输入通过，边界矩阵不足 | 系统文件选择器不稳定，旧路径导入快捷入口不足 | 通过真实“导入本地路径”入口和 F5/剪贴板自动化覆盖空路径、不存在路径、中文/空格路径、重复导入、不支持格式、空文件、损坏文件等 | 文档库 | `run_edge_input_matrix.ps1` | 是，使用真实导入路径入口和用户可理解 gate | 否 | 生成 `edge_input_results.json` 与中文报告 |
| 热插拔项目配置 A/B、回滚、损坏 fallback 未完成 EXE 黑盒验证 | 配置能力已有历史报告，但 EXE 矩阵不足 | 细粒度配置隔离未全部作为普通用户能力落地 | 运行 profile persistence smoke；验证创建/切换/删除保护/损坏 fallback；未实现细粒度隔离标记 gated/not_implemented | 设置 | `run_hotplug_config_matrix.ps1` | 是，补配置 fallback 和真实状态记录 | 否 | 生成 `hotplug_project_config_results.json` 与中文报告 |
| 工作区 A/B 隔离矩阵未完成 | 单工作区主链路通过，多物理工作区矩阵不足 | 当前产品处于本地单工作区/工作本模式 | 验证当前工作区真实产物和权限矩阵；多物理工作区互不可见能力标记 gated/not_implemented | 工作区、成果中心、使用记录 | `run_workspace_isolation_matrix.ps1` | 否 | 否 | 生成 `workspace_isolation_matrix.json` 与中文报告 |
| Agent 记忆隔离矩阵未完成 | 单 Agent 对话和清空确认已通过，跨 Agent/跨工作区记忆未完整自动化 | 显式 Agent B 私有记忆和外部记忆服务不是当前完整承诺能力 | 验证 Agent A 真实产物、对话、清空二次确认；A2A/Redis/向量库/跨 Agent 记忆标记 gated/not_implemented | 我的助手、设置 | `run_agent_memory_isolation_matrix.ps1` | 否 | 否 | 生成 `agent_memory_isolation_results.json` 与中文报告 |
| 单实例运行约束未纳入 full verifier | 单独验证已通过，full 聚合未覆盖 | 新增产品约束未进入工业矩阵 | Windows runner 使用 named mutex；verifier 增加 `single_instance` 模式并纳入 `full` | EXE 启动窗口 | `run_single_instance_check.ps1`、`run_windows_exe_smoke.ps1 -Mode single_instance/full` | 是，Windows runner 最小启动入口修复 | 否 | 第二次启动退出、首个窗口还原、运行实例数为 1 |

## 验证顺序

```text
1. flutter analyze
2. flutter test --concurrency=1
3. flutter build windows
4. git diff --check
5. run_windows_exe_smoke.ps1 -Mode single_instance
6. run_windows_exe_smoke.ps1 -Mode button_matrix
7. run_windows_exe_smoke.ps1 -Mode usage_mapping
8. run_windows_exe_smoke.ps1 -Mode edge_input
9. run_windows_exe_smoke.ps1 -Mode hotplug
10. run_windows_exe_smoke.ps1 -Mode workspace_isolation
11. run_windows_exe_smoke.ps1 -Mode memory_isolation
12. run_windows_exe_smoke.ps1 -Mode full
```

## 提交范围

允许提交：

```text
必要的产品最小修复
Windows 原生 Product Verifier 脚本
docs/audits/current/industrial_acceptance_gap_repair_plan.md
docs/audits/current/*_acceptance_zh-CN.md
docs/audits/current/industrial_acceptance_gap_repair_report.md
```

不允许提交：

```text
web/workbench/flutter_app/output/
web/workbench/flutter_app/build/
logs/
screenshots/
D:\HeiTang-Codex-WorkSpace\input 原文件
docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md
```
