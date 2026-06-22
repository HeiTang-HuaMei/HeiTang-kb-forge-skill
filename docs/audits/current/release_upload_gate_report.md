# Release Upload Gate Report

Generated: 2026-06-22

Gate: `release_upload_gate`

## 1. Current Branch

```text
feature/workbench-ui-prototype
```

## 2. Current HEAD

HEAD at release upload validation start:

```text
5410b8d docs: record tag candidate gate
```

RC tag target:

```text
5410b8d06363c33c80a3c5d65d7a4fff8c52caf6
```

## 3. RC Tag

```text
v4.2.0-rc.1
```

Tag type:

```text
annotated RC tag
```

This is not a stable release tag.

## 4. Tag Push Status

Remote:

```text
origin https://github.com/HeiTang-HuaMei/HeiTang-kb-forge-skill.git
```

Push result:

```text
passed
```

Remote verification:

```text
git ls-remote --tags origin "v4.2.0-rc.1^{}"
5410b8d06363c33c80a3c5d65d7a4fff8c52caf6 refs/tags/v4.2.0-rc.1^{}
```

## 5. EXE Build Result

Command:

```text
flutter build windows
```

Result:

```text
passed
exit code: 0
log: web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/logs/flutter_build_windows.log
```

EXE:

```text
web/workbench/flutter_app/build/windows/x64/runner/Release/heitang_workbench.exe
```

The EXE exists and has non-zero size.

## 6. Validation Commands

Command:

```text
flutter analyze
```

Result:

```text
passed
exit code: 0
log: web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/logs/flutter_analyze.log
```

Command:

```text
flutter test --concurrency=1
```

Result:

```text
passed
exit code: 0
log: web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/logs/flutter_test.log
```

Command:

```text
git diff --check
```

Result:

```text
passed
exit code: 0
log: web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/logs/git_diff_check.log
note: only the known CRLF warning for docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md was observed.
```

## 7. Windows EXE Smoke Result

Command:

```text
web\workbench\flutter_app\tool\windows_native_product_verifier\run_windows_exe_smoke.ps1
```

Result:

```text
passed
exit code: 0
log: web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/logs/windows_native_smoke.log
```

Smoke evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_192638/
```

Verifier summary:

```text
final_status: windows_exe_smoke_passed
allowed_next_gate: release_candidate_gate
automation_path: windows_native_product_verifier
navigation_status: passed
main_chain_status: passed
product_bug_confirmed: false
```

## 8. Release Package

Release output directory:

```text
web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/
```

ZIP file:

```text
HeiTang-Knowledge-Workbench-v4.2.0-rc.1-windows-x64.zip
```

ZIP size:

```text
13505574 bytes
```

Package source:

```text
web/workbench/flutter_app/build/windows/x64/runner/Release/
```

Required package contents were present before packaging:

```text
heitang_workbench.exe
data/
flutter_windows.dll
file_selector_windows_plugin.dll
native_assets.json
```

Excluded from the package:

```text
output/
logs/
screenshots/
.git/
D:\HeiTang-Codex-WorkSpace\input
docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md
```

## 9. SHA256

```text
150B1EC02428F27DC4A65F86A544350BF10E306699A3FB15821E312ABB8D041E
```

Checksum file:

```text
web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/SHA256SUMS.txt
```

## 10. Release Manifest

```text
web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/release_manifest.json
```

Manifest summary:

```json
{
  "product": "HeiTang Knowledge Workbench",
  "version": "4.2.0",
  "flutter_version": "4.2.0+1",
  "rc_tag": "v4.2.0-rc.1",
  "commit": "5410b8d06363c33c80a3c5d65d7a4fff8c52caf6",
  "platform": "windows-x64",
  "artifact": "HeiTang-Knowledge-Workbench-v4.2.0-rc.1-windows-x64.zip",
  "artifact_sha256": "150B1EC02428F27DC4A65F86A544350BF10E306699A3FB15821E312ABB8D041E",
  "smoke_status": "passed",
  "github_release_created": false
}
```

## 11. Release Notes

```text
web/workbench/flutter_app/output/release_upload/v4.2.0-rc.1/release_notes_v4.2.0-rc.1.md
```

The notes identify this build as a Release Candidate, not stable.

## 12. GitHub Release Status

```text
GitHub Release not created by policy.
github_release_created: false
```

No official release was published.

No stable tag was created.

## 13. Output / Build / Logs / Screenshots Git Check

Generated artifacts remained local evidence and were not committed:

```text
web/workbench/flutter_app/output/
web/workbench/flutter_app/build/
logs/
screenshots/
```

## 14. External Adoption Document

Known unrelated dirty file:

```text
docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md
```

This file was not touched, staged, committed, packaged, or included in the release upload materials.

## 15. Conclusion

Current status:

```text
release_upload_prepared
rc_tag_pushed
github_release_created: false
allowed_next_gate: final_owner_acceptance_gate
```

