# 验收执行模板

## 基本信息

```text
run_id:
date:
tester:
startup_method:
git_head:
dirty_marker:
source_timestamp:
exe_timestamp:
app_so_timestamp:
old_process_closed:
owner_visible_ui_tested:
```

## 验收范围

```text
main_nav:
task_chain:
sample_workspace:
sample_data:
```

## 正常路径

```text
steps:
expected:
actual:
result: pass | fail
```

## 扰动动作

至少三个：

```text
disturbance_1:
expected:
actual:
result:

disturbance_2:
expected:
actual:
result:

disturbance_3:
expected:
actual:
result:
```

## UI 证据

```text
screenshots:
visible_text_checked:
forbidden_terms_found:
```

## 后台真值

```text
workspace_id:
source_doc_count:
chunk_count:
kb_count:
parent_kbs:
source_docs:
artifact_types:
operation_record_count:
```

## 重启恢复

```text
restart_performed:
state_after_restart:
result:
```

## 结论

```text
blocker_count:
major_count:
minor_count:
passed:
remaining_risk:
```
