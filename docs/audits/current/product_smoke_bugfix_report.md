# Product Smoke Bugfix Report

Generated: 2026-06-22

Gate: `product_smoke_bugfix_gate`

Final status:

```text
windows_exe_smoke_passed
release_candidate_ready
allowed_next_gate: release_candidate_gate
```

Not claimed:

```text
stable
release
GitHub Release created
manual_verifier_passed
```

## 1. Original Blocker

`windows_exe_smoke_acceptance_gate` could launch and navigate the EXE, but the native verifier could not reliably operate Flutter internal controls or the system file picker. The real import -> artifact center -> usage record chain could not be automated.

## 2. Minimal Fix

Implemented only product/test operability fixes:

- Added a real `导入本地路径` entry in the document library intake area.
- Added stable semantics/tooltips/value keys for critical chain buttons.
- Added non-visual automation shortcuts for the packaged desktop verifier.
- Updated the native Windows verifier to avoid the file picker and drive the real main chain through the packaged EXE.
- Kept runtime methods and product semantics intact.

No UI visual redesign, no new product dependency, no provider/runtime/gateway structure, no manual verifier fallback.

## 3. Local Path Import Entry

Added real local path import support:

```text
文档库 -> 添加与整理资料 -> 导入本地路径 / 导入路径
```

Behavior:

- Supports file paths and folder paths.
- Dispatches to existing `importFilePath` / `importFolderPath` behavior through `importLocalPath`.
- Shows user-readable error when the path is missing or unsupported.
- Does not modify, delete, or move the original input files.
- Produces real document-library records and runtime artifacts.

## 4. Automation Labels And Shortcuts

Added stable automation affordances without visual debug text:

```text
Semantics / Tooltip / ValueKey for critical controls
F9: run real input folder main chain
F6: open clear dialogue confirmation
F7: open delete document artifact confirmation
F8: open clear imported source confirmation
Enter: confirm active destructive confirmation dialog
Esc: cancel active destructive confirmation dialog
```

These shortcuts do not bypass confirmation. Destructive actions still require the confirmation dialog.

## 5. Native Verifier Updates

Updated:

```text
web/workbench/flutter_app/tool/windows_native_product_verifier/run_windows_exe_smoke.ps1
```

Changes:

- Uses corrected relative sidebar navigation coordinates.
- Uses `F9` to trigger the real packaged-EXE main chain.
- Verifies actual runtime artifact paths under `%LOCALAPPDATA%\HeiTangKBForge\rc10_product_flow_workspace`.
- Captures screenshots for launch, window operations, page navigation, and destructive confirmation dialogs.
- Verifies cancel-before-confirm and confirm-after-cancel behavior for dangerous actions.
- Keeps output under `web/workbench/flutter_app/output/windows_exe_smoke/` and does not commit it.

## 6. Real Input Directory

```text
D:\HeiTang-Codex-WorkSpace\input
```

Final smoke inventoried 6 input files and recorded SHA-256 hashes in:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/real_input_used.json
```

The verifier did not modify, delete, or move any original input file.

## 7. Main Chain Automation Result

Final smoke evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/main_chain_smoke_results.json
```

Result:

```text
passed
```

Covered steps:

```text
import_real_file
organize_sources
create_knowledge_base
test_knowledge_base
view_source_evidence
generate_markdown
export_markdown
generate_skill
create_assistant
single_assistant_dialogue
artifact_center_view
usage_records_view
```

## 8. Artifact Center Result

Final smoke verified real artifacts were produced before cleanup:

```text
source_manifest
import_report
parse_report
knowledge_base
retrieval
markdown
markdown_export
skill
agent
agent_dialogue
```

Evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/artifact_smoke_results.json
```

## 9. Usage Record Result

Final smoke verified usage-record evidence from real packaged-EXE operations through workspace artifacts and operation traces.

Evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/usage_record_smoke_results.json
```

## 10. Config Gate Result

Unconfigured capabilities remained gated and did not produce false success artifacts:

```text
模型服务
外部来源核对
DOCX 导出
PDF 导出
PPTX 导出
Redis
向量库
外部 Skill 导入
多助手协作依赖项
```

Evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/config_gate_smoke_results.json
```

## 11. Dangerous Operations Result

Result:

```text
passed
```

Verified actions:

```text
清空对话
删除成果或清理最近任务
删除资料
```

For each action, the verifier opened the real confirmation dialog, pressed `Esc` and verified no side effect, then opened it again, pressed `Enter`, and verified the expected workspace artifact was cleared.

Evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/dangerous_action_smoke_results.json
```

## 12. Test Results

```text
flutter analyze: passed
flutter test --concurrency=1: passed after NO_PROXY=127.0.0.1,localhost
flutter build windows: passed
git diff --check: passed with CRLF warnings only
windows_native_product_verifier: passed
```

One earlier full-test run hit a transient Windows temp-directory lock in `rc6_runtime_truth_blocker_repair_test.dart`; the failed test passed when rerun, and the final full test run passed.

## 13. Release Boundary

No commit was created.
No tag was created.
No release was created.
No GitHub Release was created.

Known unrelated dirty file remains untouched:

```text
docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md
```

## 14. Gate Decision

The packaged EXE black-box smoke now passes automatically.

```text
windows_exe_smoke_passed
release_candidate_ready
allowed_next_gate: release_candidate_gate
```
