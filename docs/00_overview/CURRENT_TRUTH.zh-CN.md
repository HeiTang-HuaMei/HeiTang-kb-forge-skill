# 当前真值

当前 Core 版本：`3.12.0-alpha.1`

这是面向 GitHub 读者的当前状态入口。它只描述当前 main 分支，不堆放历史版本规划。

## 门禁状态

- Core pre-v4 RC readiness：最新 Core P0 证明已完成。
- P1 local Workbench final gate re-run：已通过 v4 RC readiness。
- 最新 P1 证明目录：`docs/audits/p1_final_gate_rerun/`
- 最新证明目录：`docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- 最新根目录 gate：`final_v4_rc_gate_report.json` 和 `v4_rc_final_gate_report.json`
- `ready_for_v4_rc=true`
- `P0 blockers=0`
- P0.6 文档治理前的基线证据：Core main `053a6a6`，GitHub CI run `27140288050` success。

v4.0 尚未开始、未发布、未打 tag。P1 local Workbench gate readiness 不会创建 v4 release。

## 产品定位

HeiTang KB Forge 是 local-first、offline-first 的 Core Skill，用于把本地资料转换为可审计、可检索、Agent-ready 的知识包。Core 是 headless、Skill-first。UI 是 presentation layer，必须通过独立 full-operation gate 后才能声明完整 Workbench。

## 当前证据

- 最新 Core P0 证明：`docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`
- 最新 P1 final gate re-run 证明：`docs/audits/p1_final_gate_rerun/`
- 人工可读最终真值：`docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md`
- 能力摘要：`docs/00_overview/CAPABILITY_MATRIX.zh-CN.md`
- 文档治理：`docs/DOCUMENTATION_GOVERNANCE.zh-CN.md`

## 不能声明

- v4.0 已发布或已打 tag
- 完整用户可操作 Workbench
- P1 gate 已发布 v4.0
- P1 gate 已创建 tag 或 release
- 外部 vector database production readiness
- 默认 platform-hosted user data
- Core tests 需要真实 LLM/API/network 调用
- 保存真实用户 API key
- SaaS 多租户、团队权限或 cloud sync
