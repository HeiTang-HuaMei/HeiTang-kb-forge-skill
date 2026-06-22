# Windows EXE Smoke Acceptance Report

Generated: 2026-06-22

Gate: `windows_exe_smoke_acceptance_gate`

Automation path:

```text
windows_native_product_verifier
```

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

## 1. Branch / Commit / Dirty State

| Item | Result |
| --- | --- |
| Branch | `feature/workbench-ui-prototype` |
| Commit | `30db6ba docs: record windows exe packaging gate` |
| Known unrelated dirty file | `docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md` |
| This gate touched unrelated dirty file | No |
| Commit created | No |
| Tag created | No |
| Release created | No |
| GitHub Release created | No |

## 2. EXE Path

```text
D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill-ui\web\workbench\flutter_app\build\windows\x64\runner\Release\heitang_workbench.exe
```

## 3. Evidence Directory

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/
```

Key files:

```text
smoke_manifest.json
exe_launch_result.json
window_probe_result.json
page_smoke_results.json
main_chain_smoke_results.json
artifact_smoke_results.json
usage_record_smoke_results.json
config_gate_smoke_results.json
dangerous_action_smoke_results.json
windows_native_product_verifier_result.json
screenshots/
```

The evidence directory is generated output and was not committed.

## 4. EXE Launch Result

| Check | Result |
| --- | --- |
| EXE file exists | Passed |
| EXE launched | Passed |
| Alive after 5 seconds | Passed |
| MainWindowHandle non-zero | Passed |
| Window title contains `HeiTang Workbench` | Passed |
| Initial screenshot non-white | Passed |
| Initial screenshot non-black | Passed |

## 5. Window Behavior Result

| Operation | Result |
| --- | --- |
| Maximize | Passed |
| Restore after maximize | Passed |
| Minimize | Passed |
| Restore after minimize | Passed |
| Screenshot capture | Passed |
| WM_CLOSE close and process exit | Passed |

## 6. 11-Page Navigation Result

Result:

```text
passed
```

Pages covered by automated relative-coordinate navigation:

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

Each page produced a screenshot and passed non-white / non-black screenshot checks.

## 7. Real Input Directory

Real input directory:

```text
D:\HeiTang-Codex-WorkSpace\input
```

Input handling:

```text
Input files were inventoried and imported through the packaged EXE workflow.
No input file was modified, deleted, or moved.
```

Inventory evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/real_input_used.json
```

The final smoke run recorded 6 input files with SHA-256 hashes.

## 8. Main Chain Smoke Result

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

Evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/main_chain_smoke_results.json
```

## 9. Real Artifact Paths

The packaged EXE produced real artifacts under:

```text
C:\Users\Administrator\AppData\Local\HeiTangKBForge\rc10_product_flow_workspace
```

Verified artifact classes before cleanup:

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

## 10. Artifact Center Verification Result

Result:

```text
passed
```

The verifier confirmed this-run generated artifacts existed before destructive cleanup.

Evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/artifact_smoke_results.json
```

## 11. Usage Record Verification Result

Result:

```text
passed
```

The verifier confirmed usage-record evidence from real operations and workspace traces.

Evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/usage_record_smoke_results.json
```

## 12. Config Gate Verification Result

Result:

```text
passed
```

Unconfigured capabilities stayed gated and did not produce false success artifacts:

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

## 13. Dangerous Operation Result

Result:

```text
passed
```

Verified actions:

```text
删除资料
清空对话
删除成果或清理最近任务
```

For each action, the verifier opened the real confirmation dialog, cancelled first and verified no side effect, then confirmed and verified expected workspace artifact cleanup.

Evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_182742/dangerous_action_smoke_results.json
```

## 14. Failure Items / Remaining Risk

No blocking smoke failure remains.

Residual limitations:

```text
Flutter desktop accessibility text is still limited for native automation, so verifier relies on stable shortcuts, relative coordinates, screenshots, and filesystem artifact checks.
```

## 15. Release Candidate Gate Decision

Allowed next gate:

```text
release_candidate_gate
```

## 16. Release Boundary

No tag was created.
No release was created.
No GitHub Release was created.
No manual verifier fallback was used.
