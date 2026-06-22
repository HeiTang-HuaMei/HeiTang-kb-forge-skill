# Windows EXE Smoke Automation Unblock Report

Generated: 2026-06-22

Gate: `windows_exe_smoke_automation_unblock_gate`

Final status:

```text
windows_exe_smoke_automation_unblocked
automation_path: windows_native_product_verifier
allowed_next_gate: windows_exe_smoke_acceptance_gate
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

Preflight:

| Item | Result |
| --- | --- |
| Branch | `feature/workbench-ui-prototype` |
| Commit | `30db6ba docs: record windows exe packaging gate` |
| Known unrelated dirty file | `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md` |
| Existing smoke blocked report | `docs/audits/current/windows_exe_smoke_acceptance_report.md` |
| This gate touched unrelated dirty file | No |
| Commit created | No |
| Tag created | No |
| Release created | No |
| GitHub Release created | No |

## 2. EXE Path

```text
D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\build\windows\x64\runner\Release\heitang_workbench.exe
```

## 3. Computer Use Diagnosis

Diagnosis output:

```text
web/workbench/flutter_app/output/windows_exe_smoke_automation/computer_use_diagnosis.json
```

Findings:

| Check | Result |
| --- | --- |
| Current Codex CUA runtime path | `C:\Users\Administrator\AppData\Local\OpenAI\Codex\runtimes\cua_node\a89897d3d9baa117` |
| `@oai/sky` package exists | Yes |
| `@oai/sky` version | `0.4.13` |
| `@oai/sky` exports | Only `"."` |
| Computer Use client exists | Yes |
| Computer Use client imports internal subpath | Yes |
| Failing internal subpath file exists | Yes |
| Failure reason | Node package exports blocks the internal subpath import |
| Public `@oai/sky` entry import | Works |
| Public entry exports | `sky` |

Blocking import:

```text
@oai/sky/dist/project/cua/sky_js/src/targets/windows/internal/computer_use_client_base.js
```

Error:

```text
Package subpath './dist/project/cua/sky_js/src/targets/windows/internal/computer_use_client_base.js' is not defined by exports in @oai/sky package.json
```

## 4. Computer Use Repair Result

Computer Use was not repaired.

Attempted recovery:

```text
node_repl js_reset
rerun Computer Use bootstrap
inspect public @oai/sky entry
```

Result:

```text
failed_same_exports_error
```

Reason no project-level repair was applied:

- The missing export is inside the Codex Computer Use / CUA runtime packaging boundary.
- The project must not modify plugin or runtime package exports as a product workaround.
- The project must not import `@oai/sky` internal paths.
- The project must not add this workaround to HeiTang product code or package metadata.

## 5. Windows Native Automation Result

Windows native automation was enabled as:

```text
windows_native_product_verifier_smoke
```

Evidence directory:

```text
web/workbench/flutter_app/output/windows_exe_smoke_automation/windows_native_product_verifier_20260622_165002/
```

Generated files:

```text
automation_manifest.json
window_probe_result.json
navigation_results.json
real_input_results.json
main_chain_results.json
artifact_results.json
usage_record_results.json
config_gate_results.json
dangerous_action_results.json
screenshots/
logs/
```

## 6. Automation Method

Automation method used:

```text
PowerShell
.NET System.Windows.Forms
.NET System.Drawing
Win32 window handle APIs
relative-coordinate mouse input
window screenshots
process checks
```

This automation is outside product runtime. It did not add product dependencies and did not modify the EXE.

## 7. Automation Coverage

Completed during unblock probe:

| Coverage item | Result |
| --- | --- |
| Start EXE | Passed |
| Process alive after 5 seconds | Passed |
| MainWindowHandle non-zero | Passed |
| Window title contains `HeiTang Workbench` | Passed |
| Maximize | Passed |
| Restore after maximize | Passed |
| Minimize | Passed |
| Restore after minimize | Passed |
| Screenshot capture | Passed |
| WM_CLOSE process exit | Passed |
| 11 relative-coordinate navigation clicks | Passed as automation capability probe |
| 11 page screenshots captured | Passed as automation capability probe |

Navigation probe pages:

```text
首页
工作区
文档库
知识库
测试知识库
文档生成
技能生成
我的助手
成果中心
使用记录
设置
```

## 8. Not Covered In This Unblock Gate

This unblock gate proves that Windows native automation can drive the EXE. It does not replace the full smoke acceptance gate.

Not completed here:

```text
real input import
document parsing / organizing
knowledge base creation
knowledge base testing
source / evidence inspection
Markdown generation and export
Skill generation
assistant creation
knowledge base / Skill binding
single-assistant dialogue
artifact center real-output verification
usage-record verification
unconfigured capability gate verification
dangerous operation secondary confirmation
raw-error text inspection
```

These must be covered by rerunning `windows_exe_smoke_acceptance_gate` using the `windows_native_product_verifier` automation path.

## 9. Blockers

Remaining blocker:

| Blocker | Impact | Required next action |
| --- | --- | --- |
| Computer Use remains blocked by CUA runtime package exports | Cannot use Computer Use for EXE smoke | Use `windows_native_product_verifier` for the next smoke gate unless the Codex runtime/plugin is updated |

No blocker was found for the Windows native automation path during the unblock probe.

## 10. Rerun Decision

Allowed next gate:

```text
windows_exe_smoke_acceptance_gate
```

Required automation path:

```text
windows_native_product_verifier
```

The next smoke gate must still decide:

```text
windows_exe_smoke_passed
```

or:

```text
windows_exe_smoke_blocked
```

based on full automated Product Verifier coverage.

## 11. Safety Confirmation

| Check | Result |
| --- | --- |
| Did not modify business code | Passed |
| Did not modify UI | Passed |
| Did not modify runtime semantics | Passed |
| Did not add product dependencies | Passed |
| Did not delete `D:\HeiTang-Codex-WorkSpace\input` | Passed |
| Did not tag | Passed |
| Did not release | Passed |
| Did not create GitHub Release | Passed |
| Did not declare smoke passed | Passed |
| Did not enter RC | Passed |
| Did not use manual verifier fallback | Passed |

Owner explicitly prohibited manual acceptance fallback, so no manual fallback was used or proposed as a passing path.
