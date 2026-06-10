# Validation Report

Version: v4.1.1

Gate: UI Chunked Full Gate

Repository: Ui

Decision: `chunked_full_gate_and_post_codex_full_review_passed_pending_commit_push_ci_tag_release`

Generated local date: 2026-06-11

## Chunks

| Chunk | Command | Exit code | Status | Summary | Log | Exit code sidecar |
| --- | --- | --- | --- | --- | --- | --- |
| ui_full_pytest_chunk | `python -m pytest -q` | 0 | passed | ........................................................................ [ 14%]<br>........................................................................ [ 28%]<br>...................s.................................................... [ 42%]<br>........................................................................ [ 56%]<br>........................................................................ [ 71%]<br>........................................................................ [ 85%]<br>........................................................................ [ 99%]<br>..                                                                       [100%]<br>505 passed, 1 skipped in 26.57s | `docs/audits/test_engineering/full_gate_logs/ui_full_pytest_chunk.log` | `docs/audits/test_engineering/full_gate_logs/ui_full_pytest_chunk.log.exitcode` |
| ui_flutter_analyze_chunk | `flutter analyze` | 0 | passed | Resolving dependencies...<br>Downloading packages...<br>  flutter_lints 4.0.0 (6.0.0 available)<br>  lints 4.0.0 (6.1.0 available)<br>  matcher 0.12.19 (0.12.20 available)<br>  meta 1.18.0 (1.18.3 available)<br>  test_api 0.7.11 (0.7.12 available)<br>  vector_math 2.2.0 (2.4.0 available)<br>Got dependencies!<br>6 packages have newer versions incompatible with dependency constraints.<br>Try `flutter pub outdated` for more information.<br>Analyzing flutter_app...                                        <br>No issues found! (ran in 5.9s) | `docs/audits/test_engineering/full_gate_logs/ui_flutter_analyze_chunk.log` | `docs/audits/test_engineering/full_gate_logs/ui_flutter_analyze_chunk.log.exitcode` |
| ui_flutter_test_chunk | `flutter test -r expanded` | 0 | passed | 00:01 +6: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: contract fixture parses p1 workbench contracts<br>00:01 +7: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: p1 real workflow v1 evidence parses and keeps gate blocked<br>00:01 +8: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: p1 real workflow v2 evidence parses final local path closure without v4 release<br>00:01 +9: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: p1 real workflow v2 copied report assets parse and match the fixture summary<br>00:01 +10: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: external capability assets parse as boundary-only S/A contract data<br>00:01 +11: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: p2.1 parser backend matrix asset parses with release boundaries<br>00:01 +12: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: full p1 fixture drives real local and deterministic smoke Core actions through the bridge request path<br>00:01 +13: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: renders desktop HeiTang workbench shell without Flutter exceptions<br>00:03 +14: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: renders mobile HeiTang workbench shell without Flutter exceptions<br>00:03 +15: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: keeps English and dark mode controls usable<br>00:06 +16: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: renders dedicated p1 pages without Flutter exceptions<br>00:08 +17: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: renders p1 real workflow v1 evidence while final V2 gate is ready<br>00:08 +18: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: renders p1 real workflow v2 evidence and keeps v4 release boundary<br>00:09 +19: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: renders S/A external capability boundaries without executable claims<br>00:09 +20: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: renders parser backend evidence without executable parser claims<br>00:10 +21: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: renders contract-driven action and agent mode data in English<br>00:11 +22: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: runs the desktop rag_query core action through an injected bridge<br>00:11 +23: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: disables local CLI actions on web runtime without calling the runner<br>00:12 +24: D:/HeiTang-Codex-WorkSpace/Project_01_HeiTang_KB_Forge/kb-forge-skill-ui/web/workbench/flutter_app/test/widget_test.dart: shows disabled blocked_reason for provider and secret actions<br>00:12 +25: All tests passed! | `docs/audits/test_engineering/full_gate_logs/ui_flutter_test_chunk.log` | `docs/audits/test_engineering/full_gate_logs/ui_flutter_test_chunk.log.exitcode` |
| ui_flutter_build_web_chunk | `flutter build web` | 0 | passed | Resolving dependencies...<br>Downloading packages...<br>  flutter_lints 4.0.0 (6.0.0 available)<br>  lints 4.0.0 (6.1.0 available)<br>  matcher 0.12.19 (0.12.20 available)<br>  meta 1.18.0 (1.18.3 available)<br>  test_api 0.7.11 (0.7.12 available)<br>  vector_math 2.2.0 (2.4.0 available)<br>Got dependencies!<br>6 packages have newer versions incompatible with dependency constraints.<br>Try `flutter pub outdated` for more information.<br>Compiling lib\main.dart for the Web...                          <br>Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm<br>Use --no-wasm-dry-run to disable these warnings.<br>Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons). This usually means you are referring to font families in an IconData class but not including them in the assets section of your pubspec.yaml, are missing the package that would include them, or are missing "uses-material-design: true".<br>Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 9600 bytes (99.4% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.<br>Compiling lib\main.dart for the Web...                             56.7s<br>√ Built build\web | `docs/audits/test_engineering/full_gate_logs/ui_flutter_build_web_chunk.log` | `docs/audits/test_engineering/full_gate_logs/ui_flutter_build_web_chunk.log.exitcode` |
| ui_flutter_build_windows_chunk | `flutter build windows` | 0 | passed | Resolving dependencies...<br>Downloading packages...<br>  flutter_lints 4.0.0 (6.0.0 available)<br>  lints 4.0.0 (6.1.0 available)<br>  matcher 0.12.19 (0.12.20 available)<br>  meta 1.18.0 (1.18.3 available)<br>  test_api 0.7.11 (0.7.12 available)<br>  vector_math 2.2.0 (2.4.0 available)<br>Got dependencies!<br>6 packages have newer versions incompatible with dependency constraints.<br>Try `flutter pub outdated` for more information.<br>Building Windows application...                                    51.6s<br>√ Built build\windows\x64\runner\Release\heitang_workbench.exe | `docs/audits/test_engineering/full_gate_logs/ui_flutter_build_windows_chunk.log` | `docs/audits/test_engineering/full_gate_logs/ui_flutter_build_windows_chunk.log.exitcode` |
| ui_git_diff_check | `git diff --check` | 0 | passed | warning: in the working copy of 'README.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'README.zh-CN.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/CAPABILITY_STATUS.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/CAPABILITY_STATUS.zh-CN.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/RELEASE_CHECKLIST.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/RELEASE_CHECKLIST.zh-CN.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/VERSION_MATRIX.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/VERSION_MATRIX.zh-CN.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/WORKBENCH_UI_SPEC.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/WORKBENCH_UI_SPEC.zh-CN.md', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'docs/audits/test_engineering/full_gate_logs/ui_git_diff_check.log', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'pyproject.toml', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'skill.json', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'tests/test_skill_metadata.py', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'tests/test_version_alignment.py', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'tests/test_version_matrix_docs.py', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'tests/test_workbench_external_capability_registry.py', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'tests/test_workbench_ui_contract.py', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'web/workbench/contracts.json', LF will be replaced by CRLF the next time Git touches it<br>warning: in the working copy of 'web/workbench/flutter_app/README.md', LF will be replaced by CRLF the next time Git touches it | `docs/audits/test_engineering/full_gate_logs/ui_git_diff_check.log` | `docs/audits/test_engineering/full_gate_logs/ui_git_diff_check.log.exitcode` |

## Deferred Or Skipped

No release-blocking chunk is deferred or skipped.

Skipped tests observed inside executed chunks are recorded below and are not reported as passed:

| Chunk | Test | Reason | Release impact |
| --- | --- | --- | --- |
| ui_full_pytest_chunk | `tests/test_live_provider_smoke.py::test_live_provider_smoke_entrypoint_is_explicitly_opt_in` | Live provider smoke tests require `HEITANG_RUN_LIVE_TESTS=1` | non-blocking explicit opt-in live provider smoke |

## Post-Codex Full Review

Status: `passed`

Report: `docs/audits/test_engineering/post_codex_full_review.md`

Open P0/P1/P2 issues: 0

Resolved P2 issues: 1 (`PCR-v4.1.1-001`)

Blocking rule: P0=0, P1=0, P2 fixed or explicitly deferred; P3 backlog does not block release.

## Remaining Release Gates

- Commit
- Push
- CI green
- v4.1.1 tag/release coordination

## Boundaries

- Static Workbench does not claim local parser/OCR runtime execution.
- Parser/OCR fixture remains historical Core evidence and is not rewritten as v4.1.1 runtime execution.
- Flutter build outputs are local artifacts and must remain uncommitted.
- No skipped/deferred/env-blocked check is reported as passed.
- v4.0.0 and v4.1.0 tags remain untouched.
- P2.2 is not started.

## Notes

- UI release sequence includes pytest, Flutter analyze, Flutter test, Flutter web build, Flutter Windows build, and git diff check.
- UI manifest now requires Post-Codex Review Gate metadata, matching the Core release-governance boundary.
