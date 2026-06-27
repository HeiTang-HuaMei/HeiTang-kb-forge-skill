# Local Running Baseline Check

## Scope

- Phase: Module-by-Module Post-Closure UI Bug Repair Plan / Phase 1
- Objective: confirm the running UI is current code before module repair.
- Startup method: `flutter run -d windows`
- Git HEAD: `dd8d7d8`
- Dirty marker: `true`

## Result

```text
running_ui_verified_latest = true
old_heitang_process_closed = true
owner_visible_ui_tested = true
source_or_data_origin_known = true
capability_chain_status_json_unchanged = true
phase1_status = pass_with_environment_residual_risk
```

## Evidence

```text
app_process_id = 7988
app_path = D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\build\windows\x64\runner\Debug\heitang_workbench.exe
startup_log = D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\output\module_repair\phase1_local_running_baseline\flutter_run_20260627_213945.log
startup_meta = D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\output\module_repair\phase1_local_running_baseline\local_running_baseline_meta_20260627_213945.json
```

The running UI accessibility text showed the fixed primary navigation:

```text
导入资料
知识库
Skill
Agent
文档生成
任务工作台
配置
```

The same running UI showed:

```text
位置: 新知识工作本
当前工作区 新知识工作本
UI008_DeleteTmp absent
```

## Dirty Worktree

The repository is intentionally dirty from prior UI closure repair work. Phase 1 records this as the active repair worktree, not as a clean release candidate.

Dirty areas include:

```text
web/workbench/flutter_app/lib/**
web/workbench/flutter_app/test/**
docs/audits/current/post_p2_ui_*.md
docs/governance/PRE_LAUNCH_FINAL_ACCEPTANCE_RELEASE_DATA_AND_LAUNCH_READINESS_DRILL.md
docs/product/POST_P2_UI_POLISH_AND_CLOSURE_PLAN.md
```

No diff exists for:

```text
capability_chain_status.json
```

## Environment Residual Risk

Several historical `flutter_tester.exe` processes remain visible. Their command lines are `flutter_test_listener...listener.dart.dill`, so they are stale test-runner processes, not Owner-visible product UI windows.

Attempts to stop them with `Stop-Process` and `taskkill /F /T` did not remove the parent process entries; `taskkill` reported child processes terminated but parent task instances were no longer running.

This is recorded as an environment residual risk, not a product UI provenance failure.

## Gate Decision

Phase 1 can proceed to module repair because the Owner-visible product window is a fresh `flutter run -d windows` instance from the current dirty repair worktree, and the product window provenance is known.

Phase 2 must keep using this same provenance discipline and must not claim a module fixed unless the latest running UI is verified again.
