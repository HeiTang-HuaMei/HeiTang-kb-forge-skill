# Windows EXE Smoke Blocker Fix Report

Generated: 2026-06-22

Gate: `windows_exe_smoke_blocker_fix_gate`

Final status:

```text
windows_exe_smoke_product_bug_found
allowed_next_gate: product_smoke_bugfix_gate
```

Not claimed:

```text
windows_exe_smoke_passed
release_candidate_ready
stable
release
GitHub Release created
manual_verifier_passed
```

## 1. Branch / Commit / Dirty State

| Item | Result |
| --- | --- |
| Branch | `feature/workbench-ui-prototype` |
| Commit | `30db6ba docs: record windows exe packaging gate` |
| Known unrelated dirty file | `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md` |
| Commit created | No |
| Tag created | No |
| Release created | No |
| GitHub Release created | No |

## 2. Original Smoke Blocker

Original state:

```text
windows_exe_smoke_blocked
allowed_next_gate: none
```

Original blocker:

```text
Computer Use runtime bootstrap failed
```

Original error:

```text
Package subpath './dist/project/cua/sky_js/src/targets/windows/internal/computer_use_client_base.js' is not defined by exports in @oai/sky package.json
```

## 3. EXE Basic Launch Facts

Phase 1 evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke_fix/blocker_diagnosis.json
web/workbench/flutter_app/output/windows_exe_smoke_fix/computer_use_error.txt
web/workbench/flutter_app/output/windows_exe_smoke_fix/exe_probe_result.json
```

Confirmed facts:

| Check | Result |
| --- | --- |
| EXE exists | True |
| EXE launches | True |
| Alive after 5 seconds | True |
| Window title | `HeiTang Workbench` |
| Computer Use bootstrap failed | True |
| Blocker type | `automation_infrastructure` |
| Product bug confirmed at attribution phase | False |

## 4. Computer Use Repair Attempt

Computer Use diagnosis confirmed:

- `@oai/sky` package exists.
- The failing internal file exists.
- `@oai/sky` package exports only `"."`.
- Computer Use client imports an internal subpath not allowed by package exports.
- Public `@oai/sky` entry imports successfully but does not expose the required Windows internal client.
- `node_repl` reset and bootstrap retry failed with the same exports error.

Conclusion:

```text
Computer Use could not be repaired from project scope without modifying Codex plugin/runtime package exports.
```

No HeiTang product code, product package file, or node_modules workaround was modified.

## 5. Windows Native Automation Enabled

Because Computer Use was not repairable from project scope, this gate added a Windows native Product Verifier script:

```text
web/workbench/flutter_app/tool/windows_native_product_verifier/run_windows_exe_smoke.ps1
```

This script is a test/acceptance tool only. It is not part of product runtime and adds no product dependency.

Automation stack:

```text
PowerShell
.NET System.Windows.Forms
.NET System.Drawing
Win32 window handle APIs
relative-coordinate mouse input
screenshot capture
process checks
```

## 6. Automation Coverage

The script completed:

| Coverage | Result |
| --- | --- |
| Start EXE | Passed |
| 5-second liveness | Passed |
| MainWindowHandle non-zero | Passed |
| Window title check | Passed |
| Initial screenshot non-white / non-black | Passed |
| Maximize / restore / minimize / restore | Passed |
| 11-page navigation | Passed |
| Per-page screenshots | Passed |
| Input inventory without modifying source files | Passed |

Smoke rerun evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_165504/
```

## 7. Rerun Result

The gate reran `windows_exe_smoke_acceptance_gate` using:

```text
automation_path: windows_native_product_verifier
```

Updated report:

```text
docs/audits/current/windows_exe_smoke_acceptance_report.md
```

Rerun status:

```text
windows_exe_smoke_product_bug_found
allowed_next_gate: product_smoke_bugfix_gate
```

## 8. Product Bug / Smoke Blocker Found

After automation was restored through the native verifier, the EXE shell and navigation were automatable, but the main chain remained blocked.

Blocked area:

```text
real import and end-to-end main-chain operation targeting
```

Blocked steps:

```text
导入真实文件
整理资料
生成知识库
测试知识库
查看来源
生成 Markdown
导出 Markdown
生成 Skill
创建助手
单助手对话
成果中心查看
使用记录查看
```

Reason:

```text
The native verifier can launch, navigate, and screenshot the EXE, but it does not yet have reliable Flutter control discovery or file-dialog automation for real import/main-chain operations.
```

Classification:

```text
product_smoke_blocker
```

This is not a smoke pass. It must be handled by `product_smoke_bugfix_gate`.

## 9. Release Candidate Decision

Allowed next gate:

```text
product_smoke_bugfix_gate
```

Release Candidate is not allowed.

## 10. Safety Confirmation

| Check | Result |
| --- | --- |
| Did not manually verify | Passed |
| Did not directly mark smoke passed | Passed |
| Did not enter RC | Passed |
| Did not tag | Passed |
| Did not release | Passed |
| Did not create GitHub Release | Passed |
| Did not delete `D:\HeiTang-Codex-WorkSpace\input` | Passed |
| Did not submit output/log/build artifacts | Passed |
| Did not change UI visual design | Passed |
| Did not change business runtime | Passed |

Owner explicitly prohibited manual acceptance fallback. No manual fallback was used.
