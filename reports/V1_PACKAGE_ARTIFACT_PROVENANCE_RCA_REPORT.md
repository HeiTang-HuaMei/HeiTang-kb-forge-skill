# V1 Package Artifact Provenance RCA Report

Generated: 2026-06-29 23:58:00 +08:00

## 1. Scope

This report is an artifact provenance RCA only.

Current downgraded state:

`v1_package_gate_blocked_by_artifact_provenance_mismatch`

Stopped paths:

- Computer Use Acceptance Gap Closure
- DeepSeek Computer Use Review
- Final Owner Review Preparation
- release/tag/push operations

Not performed during this RCA:

- code modification
- `capability_chain_status.json` modification
- rebuild/package rerun
- `git add`
- commit
- push/tag/release
- Final Owner Review

## 2. Git State

HEAD:

`99a5a29 docs: record v1 package gate result evidence`

Branch:

`v1-clean-baseline-reconstruction`

`git status --short` at RCA start:

```text
?? output/
?? reports/V1_ACCEPTANCE_AND_HARDENING_MASTER_PLAN.md
?? reports/V1_COMPUTER_USE_ACCEPTANCE_DEEPSEEK_REVIEW_PACKET.md
?? reports/V1_COMPUTER_USE_ACCEPTANCE_GAP_CLOSURE_DEEPSEEK_PACKET.md
?? reports/V1_COMPUTER_USE_ACCEPTANCE_GAP_CLOSURE_REPORT.md
?? reports/V1_COMPUTER_USE_ACCEPTANCE_REPORT.md
?? reports/V1_FINAL_OWNER_REVIEW_PREPARATION_PACK.md
```

`capability_chain_status.json` diff:

`empty`

Tracked diff:

`none`

## 3. Package Artifact Metadata

NSIS installer:

`desktop/tauri/src-tauri/target/release/bundle/nsis/HeiTang KB Forge Desktop_1.2.3_x64-setup.exe`

| Field | Value |
| --- | --- |
| Size | `1992001` bytes |
| Modified time | `2026-06-29 22:55:01 +08:00` |
| SHA256 | `A329BE28F3949469EEDC2F9CA128F89FBA9FF9C43A415A23D5F3B33882E92148` |

Desktop release exe:

`desktop/tauri/src-tauri/target/release/heitang-kb-forge-desktop.exe`

| Field | Value |
| --- | --- |
| Size | `8401408` bytes |
| Modified time | `2026-06-29 22:55:01 +08:00` |
| SHA256 | `6A4858DBC9561B75CFD501C2FB3CFA88AB945F58AA1E8EE83525566C0B4FF0EC` |

Frontend dist directory used by Tauri:

`desktop/tauri/dist`

| Path | Modified time |
| --- | --- |
| `desktop/tauri/dist/index.html` | `2026-06-29 22:54:00 +08:00` |
| `desktop/tauri/dist/assets/index-CbYU6hy9.js` | `2026-06-29 22:54:00 +08:00` |
| `desktop/tauri/dist/assets/index-D-fQwAVp.css` | `2026-06-29 22:54:00 +08:00` |
| `desktop/tauri/dist/assets/cat-head-jMezwttM.png` | `2026-06-29 22:54:00 +08:00` |

Flutter web build directory:

`web/workbench/flutter_app/build/web`

Result:

`missing`

## 4. Observed Packaged App UI

Computer Use launched the explicit release exe path:

`desktop/tauri/src-tauri/target/release/heitang-kb-forge-desktop.exe`

Observed packaged window title:

`HeiTang KB Forge Desktop`

Observed navigation from the packaged app screenshots:

- `首页`
- `新建知识包`
- `批量处理`
- `工作区`
- `更新与增量`
- `质量与验收`
- `知识包详情`
- `问答测试`
- `发布导出`
- `规划准备`
- `桌面设置`

Observed shell brand/subtitle:

- `HeiTang`
- `Skill 本地桌面壳`
- `面向 Agent 知识供应链的本地桌面工具`

Observed Agent-adjacent controls:

- `Agent 对接目标`
- `generic_rag`
- `mcp_server_future`
- `对接模式`
- `export_only`
- `local_runtime_future`
- `remote_api_future`

Screenshots captured before this RCA:

- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_packaged_shell_initial.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_packaged_shell_qa_test.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_agent_target_dropdown.png`
- `output/v1_computer_use_acceptance/gap_closure_screenshots/gap_b_agent_mode_dropdown.png`

No HeiTang process was running at RCA inspection time, so no live process path could be rechecked after the earlier app close.

## 5. Current Source UI Summary

Expected current V1 UI source inspected:

- `web/workbench/flutter_app/lib/main.dart`
- `web/workbench/flutter_app/lib/app/workbench_pages.dart`
- `web/workbench/flutter_app/lib/features/`

Current Flutter workbench page definitions in `web/workbench/flutter_app/lib/app/workbench_pages.dart`:

| Page id | Chinese title | English title |
| --- | --- | --- |
| `dashboard` | `任务工作台` | `Task Workbench` |
| `workbook` | `工作区` | `Workbook` |
| `document-library` | `导入资料` | `Import Materials` |
| `knowledge-package-management` | `知识库` | `Knowledge Base` |
| `retrieval-verification` | `知识库验证` | `Knowledge Verification` |
| `document-generation` | `文档生成` | `Document Generation` |
| `skill-factory` | `Skill` | `Skill` |
| `agent-factory-runtime` | `Agent` | `Agent` |
| `artifact-center` | `成果中心` | `Outputs` |
| `reports-audit` | `操作记录` | `Operation Records` |
| `workspace` | `配置` | `Configuration` |

Primary navigation page ids:

- `document-library`
- `knowledge-package-management`
- `skill-factory`
- `agent-factory-runtime`
- `document-generation`
- `dashboard`
- `workspace`

Current Flutter features present:

- `features/agent/agent_product_workflow.dart`
- `features/artifacts/artifact_center_product_workflow.dart`
- `features/dashboard/dashboard_product_workflow.dart`
- `features/import_parsing/import_product_workflow.dart`
- `features/knowledge_base/knowledge_base_product_workflow.dart`
- `features/settings/settings_product_workflow.dart`
- `features/skill/skill_builder_product_workflow.dart`
- `features/workbook/workbook_product_workflow.dart`

Important current Flutter Agent source markers:

- page id `agent-factory-runtime`
- visible title `Agent`
- assistant creation/action controls in `features/agent/agent_product_workflow.dart`
- product guidance such as model-service setup in settings before real model replies

## 6. Tauri Package Input Path

Build script:

`packaging/desktop/build_tauri.ps1`

Observed behavior:

- Sets `$Root` to the repository root.
- Sets `$TauriDir` to `$Root\desktop\tauri`.
- `Set-Location $TauriDir`.
- Runs `npm.cmd run tauri:build`.
- Does not run `flutter build web`.
- Does not copy `web/workbench/flutter_app/build/web` into the Tauri frontend directory.

Tauri config:

`desktop/tauri/src-tauri/tauri.conf.json`

Relevant build configuration:

```json
"beforeBuildCommand": "npm run build",
"frontendDist": "../dist"
```

Tauri package script:

`desktop/tauri/package.json`

Relevant scripts:

```json
"build": "vite build --config vite.config.mjs",
"tauri:build": "tauri build"
```

Package Gate retry2 logs:

- `reports/package_gate_b1_retry2_logs/build_tauri_retry2_20260629_225356.stdout.log`
- `reports/package_gate_b1_retry2_logs/build_tauri_retry2_20260629_225356.stderr.log`

Relevant log facts:

- Tauri ran `beforeBuildCommand` as `npm run build`.
- `npm run build` ran `vite build --config vite.config.mjs`.
- Vite emitted:
  - `dist/index.html`
  - `dist/assets/cat-head-jMezwttM.png`
  - `dist/assets/index-D-fQwAVp.css`
  - `dist/assets/index-CbYU6hy9.js`

Conclusion:

The Package Gate build path packages `desktop/tauri/dist`, produced from `desktop/tauri/src` by Vite/React. It does not package the Flutter V1 workbench UI from `web/workbench/flutter_app`.

## 7. Tauri React Shell Source Match

The observed packaged UI matches `desktop/tauri/src`, not the current Flutter workbench source.

`desktop/tauri/src/components/Sidebar.tsx` defines:

- `dashboard` -> `nav.dashboard`
- `buildPackage` -> `nav.build`
- `batchProcessing` -> `nav.batch`
- `workspace` -> `nav.workspace`
- `lifecycleUpdate` -> `nav.lifecycle`
- `qualityGate` -> `nav.quality`
- `packageDetail` -> `nav.packageDetail`
- `askRuntime` -> `nav.ask`
- `publishExport` -> `nav.publish`
- `planningReadiness` -> `nav.planning`
- `settings` -> `nav.settings`

`desktop/tauri/src/i18n.ts` maps those labels to the observed Chinese navigation:

- `首页`
- `新建知识包`
- `批量处理`
- `工作区`
- `更新与增量`
- `质量与验收`
- `知识包详情`
- `问答测试`
- `发布导出`
- `规划准备`
- `桌面设置`

`desktop/tauri/src/pages/AskRuntime.tsx` defines the observed Agent-adjacent selectors:

- `generic_rag`
- `mcp_server_future`
- `export_only`
- `local_runtime_future`
- `remote_api_future`

The compiled `desktop/tauri/dist/assets/index-CbYU6hy9.js` contains the same React shell strings and page map.

## 8. Installed App / Residual Path Check

Common installed locations checked:

- `%LOCALAPPDATA%\HeiTang KB Forge Desktop`
- `%LOCALAPPDATA%\Programs\HeiTang KB Forge Desktop`
- `%APPDATA%\HeiTang KB Forge Desktop`
- `%ProgramFiles%\HeiTang KB Forge Desktop`
- `%ProgramFiles(x86)%\HeiTang KB Forge Desktop`

Result:

No matching installed directory was found in those checked locations.

Computer Use launch attribution from the earlier gap pass:

- It launched the explicit target exe path under the clean reconstruction worktree.
- The observed window belonged to `process:...\desktop\tauri\src-tauri\target\release\heitang-kb-forge-desktop.exe`.

Conclusion:

The available evidence does not support "Computer Use launched old installed app" as the primary root cause.

## 9. Root Cause Classification

Selected classification:

`D. package artifact genuinely contains old UI`

Supporting findings:

- The observed packaged UI exactly matches `desktop/tauri/src` and `desktop/tauri/dist`.
- The current expected V1 UI source lives under `web/workbench/flutter_app` and defines different primary pages and labels.
- `packaging/desktop/build_tauri.ps1` does not run `flutter build web`.
- `tauri.conf.json` points `frontendDist` to `../dist`, meaning `desktop/tauri/dist`.
- `desktop/tauri/package.json` builds that `dist` via Vite, not Flutter.
- `web/workbench/flutter_app/build/web` is missing.
- No installed-app residue was found in common locations, and prior launch evidence points to the target release exe.

Contributing classifications:

- `A. build script did not rebuild current Flutter web assets`
- `B. tauri.conf points to stale frontend directory`

Rejected as primary:

- `C. Computer Use launched old installed app instead of current artifact`

Reason:

The target exe was launched directly from the clean worktree, and the packaged frontend matches the Tauri React shell source in this same worktree.

## 10. Stale Asset Risk

Stale asset risk:

`high`

Reason:

Even though `desktop/tauri/dist` was freshly emitted at `2026-06-29 22:54:00 +08:00`, it was freshly emitted from the wrong frontend source for the intended V1.0 acceptance target. This is not merely an old timestamp problem; it is a package-input provenance mismatch.

## 11. Package Gate Impact

Package Gate result must be invalidated for V1.0 UI/artifact acceptance.

Reason:

Package Gate retry2 validated that the Tauri React shell can be built into an NSIS installer with exit code `0`, no tracked drift, empty `capability_chain_status.json` diff, and clean ready-claim classification. It did not validate that the generated artifact contains the current V1 clean baseline Flutter workbench UI.

The prior technical build success remains useful build-chain evidence, but it cannot be used as V1.0 package acceptance evidence until the package input points to and embeds the intended current UI.

Current status remains:

`v1_package_gate_blocked_by_artifact_provenance_mismatch`

## 12. Recommended Next Action

Recommended sequence:

1. Fix the package input path so the Package Gate builds the intended current V1 UI.
2. Update `build_tauri.ps1` or the package wiring to run the correct frontend build step, likely `flutter build web` for `web/workbench/flutter_app`.
3. Clean frontend build output and rebuild package from the clean worktree.
4. Ensure `tauri.conf.json` `frontendDist` points to the verified current UI output, or copy the Flutter web output into the Tauri `frontendDist` directory in a controlled script step.
5. Rerun Package Gate from a clean worktree.
6. Rerun Computer Use acceptance against the verified artifact.

Do not proceed to Final Owner Review preparation until a new Package Gate run proves the packaged artifact contains the intended current V1 UI.

## 13. Ready-Claim Scan

Ready-claim scan result:

`clean / non-claim only`

Classification:

- No positive current-state readiness claim was introduced in `capability_chain_status.json`.
- Report mentions of forbidden readiness terms are negative, gated, historical, or RCA scope statements.
- Existing source/test readiness field names are not treated as current V1 acceptance claims in this RCA.

## 14. Completion State

RCA completion state:

`v1_package_artifact_provenance_rca_completed_pending_owner_decision`
