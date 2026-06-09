# P1 UI Core Parity

P1 现在是 local Workbench evidence gate，已通过 v4 RC readiness。项目已通过 `v4.0.0-rc.1` acceptance 与 hardening，进入 stable `v4.0.0`。

## 目标

证明 UI 能引导或操作 Core 已证明的主要 workflow：

- workspace setup
- file selection
- KB build
- query and verification
- document generation
- Agent and Skill creation
- local runtime flows
- storage and memory lifecycle views
- release and gate report review
- provider settings，且不提交 secrets

## 验收边界

P1 需要 Core V1/V2 evidence、UI consumption、drift-free assets，以及明确的 provider/secret/network blocked boundary。只有 contract view 或 minimal bridge wiring 不足以通过。

## 当前状态

- Core pre-v4 RC readiness 已完成。
- P1-RWF-V2 evidence 与 UI consumption 已复验为 `ready_for_v4_rc=true`。
- stable `v4.0.0` 是 rc.1 acceptance 与 hardening evidence 之后的当前 release line。
