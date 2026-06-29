# V1 Package Artifact Provenance Fix Report

Generated: 2026-06-30

## 1. Scope

Current input state:

`v1_package_gate_invalidated_by_artifact_provenance_mismatch`

This report records the Owner-authorized packaging provenance fix that removes the stale Tauri React/Vite shell from the Package Gate input and rewires Tauri packaging to the current Flutter V1 UI build output.

This is a packaging provenance fix only. It does not change Flutter product behavior or UI business logic.

Not performed:

- Package Gate retry
- build/package retry beyond script/config preparation
- push
- tag/release
- Final Owner Review
- `capability_chain_status.json` modification
- Flutter product feature/code modification

## 2. RCA Summary

RCA report:

`reports/V1_PACKAGE_ARTIFACT_PROVENANCE_RCA_REPORT.md`

RCA conclusion:

`D. package artifact genuinely contains old UI`

Prior Package Gate build success is invalid for V1.0 UI/artifact acceptance because Tauri packaged the old `desktop/tauri/src` React/Vite shell instead of the intended Flutter V1 workbench UI.

## 3. Old UI Path

Old stale UI path:

`desktop/tauri/src`

Old shell characteristics:

- React/Vite app.
- Sidebar labels included `首页`, `新建知识包`, `批量处理`, `工作区`, `更新与增量`, `质量与验收`, `知识包详情`, `问答测试`, `发布导出`, `规划准备`, and `桌面设置`.
- Agent-adjacent controls included `generic_rag`, `mcp_server_future`, `export_only`, `local_runtime_future`, and `remote_api_future`.
- This shell matched the Computer Use observed packaged UI and did not match the current Flutter V1 workbench source.

Deleted/stopped content:

- `desktop/tauri/src/**`

The directory deletion is limited to the stale Tauri React/Vite shell. `desktop/tauri/src-tauri` remains intact.

## 4. Current Flutter V1 UI Path

Current effective UI source:

`web/workbench/flutter_app`

Flutter build output expected by Package Gate:

`web/workbench/flutter_app/build/web`

Current Flutter V1 page source includes:

- `web/workbench/flutter_app/lib/main.dart`
- `web/workbench/flutter_app/lib/app/workbench_pages.dart`
- `web/workbench/flutter_app/lib/features/`

Current Flutter primary navigation page ids:

- `document-library`
- `knowledge-package-management`
- `skill-factory`
- `agent-factory-runtime`
- `document-generation`
- `dashboard`
- `workspace`

## 5. `build_tauri.ps1` Modification Summary

File:

`packaging/desktop/build_tauri.ps1`

Changes:

- Adds `$FlutterAppDir = $Root\web\workbench\flutter_app`.
- Adds `$FlutterWebDist = $FlutterAppDir\build\web`.
- Enters the Flutter app directory before packaging.
- Runs `flutter.cmd build web`.
- Immediately captures `$LASTEXITCODE` as `$flutterBuildExitCode`.
- Fails with that exit code if Flutter build fails.
- Verifies `web/workbench/flutter_app/build/web/index.html` exists after Flutter build.
- Enters `desktop/tauri`.
- Runs `npm.cmd run tauri:build`.
- Preserves the existing native-command exit-code capture for `tauri:build`.
- Preserves the NSIS artifact presence check.
- Does not swallow real Flutter or Tauri failures.

## 6. `tauri.conf.json` Modification Summary

File:

`desktop/tauri/src-tauri/tauri.conf.json`

Old frontend input:

`../dist`

New frontend input:

`../../../web/workbench/flutter_app/build/web`

Removed old build hooks:

- `beforeDevCommand: npm run dev`
- `beforeBuildCommand: npm run build`

Reason:

Flutter web build is now controlled by the Package Gate script before `tauri build`. Tauri then consumes the verified Flutter web output directly.

## 7. `package.json` Modification Summary

File:

`desktop/tauri/package.json`

Changes:

- Removed old Vite scripts:
  - `dev`
  - `build`
  - `typecheck`
- Kept Tauri scripts:
  - `tauri:dev`
  - `tauri:build`
- Removed old React/Vite dependencies from active package metadata:
  - `@tauri-apps/api`
  - `react`
  - `react-dom`
  - `@vitejs/plugin-react`
  - `@types/react`
  - `@types/react-dom`
  - `typescript`
  - `vite`
- Kept `@tauri-apps/cli`.

`desktop/tauri/package-lock.json` was intentionally not modified in this commit scope.

## 8. Generated Output Cleanup

No generated build/package outputs were cleaned in this fix-preparation stage.

Reason:

Owner authorized removal of stale UI source and packaging input rewiring, but also explicitly prohibited Package Gate retry in this stage. Existing generated artifacts are retained as historical evidence until the next Owner-authorized clean Package Gate retry.

Generated output cleanup can be handled during the retry preflight if Owner authorizes it.

Historical evidence retained:

- `reports/**`
- `output/**`

## 9. Why This Is Not a Product Feature Change

This change only alters what Tauri packages:

- Removes stale React/Vite packaging frontend.
- Builds Flutter web output from the already-existing current V1 UI.
- Points Tauri `frontendDist` at that Flutter web output.

It does not modify:

- Flutter product source under `web/workbench/flutter_app/lib`.
- product workflows.
- user-facing Flutter behavior.
- `capability_chain_status.json`.

## 10. Validation Before Commit

`capability_chain_status.json` diff:

`empty`

Ready-claim scan:

`clean / non-claim only`

Classification:

- No positive current-state readiness claim was introduced.
- Report mentions are negative, historical, or authorization-gated.
- Existing schema/test/fixture readiness fields remain non-claim domain/test vocabulary.

Package Gate retry:

`not run`

## 11. Next Step

Next required Owner action:

Authorize a clean Package Gate retry from the current worktree.

Retry must verify:

- `flutter build web` runs successfully.
- `web/workbench/flutter_app/build/web/index.html` exists.
- Tauri packages `web/workbench/flutter_app/build/web`, not `desktop/tauri/src` or `desktop/tauri/dist`.
- The produced desktop app displays the current Flutter V1 UI.
- No tracked drift appears.
- `capability_chain_status.json` diff remains empty.
- ready-claim scan remains clean / non-claim only.

Completion state after this fix commit:

`v1_stale_tauri_shell_removed_pending_package_gate_retry_authorization`
