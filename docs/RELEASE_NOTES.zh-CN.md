# Release Notes

## v4.0.0

Stable `v4.0.0` 在 P1 Final Gate Re-run、Pre-v4 External Project Registry、S/A Contract Inclusion、rc.1 acceptance 与 release hardening 完成后启动。Core pre-v4 RC readiness 作为历史证据继续保留。最新 Core P0 证明显示 `ready_for_v4_rc=true` 且 `P0 blockers=0`，最新 P1 final gate re-run 也显示 `ready_for_v4_rc=true`。

本 stable release 保持 local-first 边界：Core tests 不需要真实 LLM/API/network 调用，外部项目除非单独实现，否则仍是 visibility 或 planned-adapter boundary，provider secrets 不进入提交输出。

## v4.0.0-rc.1

本 release candidate 在 P1 Final Gate Re-run、Pre-v4 External Project Registry 与 S/A Contract Inclusion 完成后启动。最新 Core P0 证明显示 `ready_for_v4_rc=true` 且 `P0 blockers=0`，最新 P1 final gate re-run 也显示 `ready_for_v4_rc=true`。

这不是 stable `v4.0.0` release。stable `v4.0.0` 需要 rc.1 acceptance 与 hardening evidence。

## 当前 main

## P1 Final Gate Re-run

- 新增 `docs/audits/p1_final_gate_rerun/`。
- 复验 P1-RWF-V1、P1-RWF-V2、57 个 ready local action execution、10 条 user path、UI consumption、drift count 和 provider/secret/network blocked boundary。
- 在不启动 v4.0、不创建 tag、不写 release 的前提下，将 `ready_for_v4_rc_candidate=true` 推进为 `ready_for_v4_rc=true`。

## P0.6 GitHub Documentation Governance

- 瘦身 GitHub-facing 文档表面。
- 保留当前产品入口、当前真值、命令使用、版本矩阵、最终架构真值、final gate JSON 和 latest P0 proof。
- 历史版本细节回到 git history 和 tags，而不是继续作为 main 顶层文档堆放。
- 增加文档治理和 README link checks。
