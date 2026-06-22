# Windows EXE Packaging Report

Generated: 2026-06-22

Gate: `windows_exe_packaging_gate`

Final status:

```text
windows_exe_packaging_passed
allowed_next_gate: windows_exe_smoke_acceptance_gate
```

Not claimed:

```text
windows_exe_smoke_passed
release_candidate_ready
stable
release
GitHub Release
```

## 1. Preconditions

Confirmed prerequisite states:

| State | Result |
| --- | --- |
| `full_product_regression_passed_before_packaging` | Confirmed |
| `pre_exe_packaging_cleanup_passed` | Confirmed |
| `allowed_next_gate: windows_exe_packaging_gate` | Confirmed |

This gate did not change UI, runtime semantics, product functionality, dependencies, tags, releases, or GitHub Releases.

## 2. Preflight

Commands:

```text
git status --short
git branch --show-current
git log -1 --oneline
flutter --version
flutter doctor -v
flutter devices
```

Results:

| Item | Result |
| --- | --- |
| Branch | `feature/workbench-ui-prototype` |
| Baseline commit | `47c135d docs: align opencli source connector planning` |
| Dirty state | Existing unrelated `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md` only before this report |
| Flutter | `3.44.1 stable` |
| Dart | `3.12.1` |
| Windows desktop device | Available |
| Visual Studio Build Tools | Available: 2022 17.14.33 |
| Windows SDK | Available: 10.0.26100.0 |
| Android SDK | Missing, not required for Windows packaging |
| Proxy warning | `NO_PROXY` was not globally set; build command set `NO_PROXY=127.0.0.1,localhost` for this gate |

## 3. Build Command

Command:

```powershell
$env:NO_PROXY='127.0.0.1,localhost'
flutter build windows
```

Log:

```text
web/workbench/flutter_app/build_windows_packaging_gate.log
```

Result:

```text
Building Windows application... 35.7s
Built build\windows\x64\runner\Release\heitang_workbench.exe
```

Exit code:

```text
0
```

## 4. Packaging Output

Output executable:

```text
web/workbench/flutter_app/build/windows/x64/runner/Release/heitang_workbench.exe
```

Release directory contents observed:

| File | Result |
| --- | --- |
| `heitang_workbench.exe` | Present |
| `flutter_windows.dll` | Present |
| `file_selector_windows_plugin.dll` | Present |
| `native_assets.json` | Present |
| `data/` | Present |

Executable size:

```text
57856 bytes
```

The executable timestamp reported by the filesystem was older than the gate run, which indicates the incremental Flutter/CMake build reused the runner executable while refreshing the release bundle. The build command still completed successfully and reported the expected output path.

## 5. Basic Launch Probe

Probe command:

```powershell
Start-Process build\windows\x64\runner\Release\heitang_workbench.exe -PassThru -WindowStyle Hidden
```

Result:

```text
Started: true
AliveAfter5Seconds: true
ExitCode: terminated_after_probe
```

Interpretation:

The Windows EXE launched and did not immediately crash during the 5-second process-liveness probe. The process was then terminated by the probe.

## 6. Smoke Boundary

This packaging gate verifies build creation and a basic launch probe only.

The following checks are intentionally deferred to `windows_exe_smoke_acceptance_gate`:

```text
visible non-white / non-black window check
window maximize / minimize / restore
visual layout check
sidebar and topbar visual check
page navigation
local file import
basic document library / knowledge-base chain
settings page behavior
configured and unconfigured capability gates
close / exit behavior
```

These items were not marked passed by this report.

## 7. Excluded From Commit / Package Evidence

The following generated local evidence is intentionally not submitted:

```text
web/workbench/flutter_app/build/
web/workbench/flutter_app/build_windows_packaging_gate.log
temporary local logs
```

The gate did not delete real input files and did not delete accepted reports.

## 8. Validation

Required validation:

```text
git diff --check
```

Result:

```text
Passed.
```

Note:

The only warning was an LF/CRLF warning for the unrelated dirty file `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md`.

## 9. Safety

| Check | Result |
| --- | --- |
| Did not modify UI code | Passed |
| Did not modify runtime code | Passed |
| Did not add dependencies | Passed |
| Did not delete `D:\HeiTang-Codex-WorkSpace\input` | Passed |
| Did not submit `build/` artifacts | Passed |
| Did not submit logs | Passed |
| Did not tag | Passed |
| Did not release | Passed |
| Did not create GitHub Release | Passed |

## 10. Conclusion

Windows packaging completed successfully and produced a runnable Windows release bundle.

Next gate:

```text
windows_exe_smoke_acceptance_gate
```
