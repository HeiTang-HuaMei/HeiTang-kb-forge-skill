# 数据 Schema 与存储规格

## 目的

本文件把产品数据模型落到文件型 workspace 存储规格。它定义从 0 开发或重构时的最低持久化结构。

## 存储原则

- 本地优先。
- 每个 workspace 独立。
- 用户成果和工程证据分离。
- 删除优先软删除或 tombstone，避免误删来源。
- 每个可见对象都能追溯来源。
- 每个 E2E 都能做后台真值对账。

## Workspace Root

推荐结构：

```text
<workspace_root>/
  workspace_manifest.json
  source_manifest.json
  input/
  import/
  documents/
  knowledge_bases/
  artifacts/
  operations/
  export/
  config/
  audit/
```

当前项目中已有类似目录和文件名，重构时应优先兼容已有数据。

## workspace_manifest.json

用途：记录工作区列表和当前工作区。

必要字段：

```json
{
  "schema_version": "workspace_manifest.v1",
  "current_workspace_id": "UI008_GoldenWorkspace",
  "workspaces": []
}
```

workspace 记录字段：

- workspace_id
- name
- root_path
- status
- created_at
- updated_at
- is_deleted

## source_manifest.json

用途：记录导入来源。

SourceDoc 字段：

- source_doc_id
- workspace_id
- display_name
- source_type：file / folder / link
- original_path_or_url
- content_hash
- import_status
- parse_status
- summary
- text_preview
- error_message
- created_at
- updated_at

规则：

- content_hash 用于去重。
- summary 和 text_preview 不得用假内容填充。
- 没有内容就写空值，并由 UI 显示“暂无”。

## documents/

用途：保存解析后的文档正文、片段预览和元数据。

推荐：

```text
documents/
  <source_doc_id>/
    document.json
    text.txt
    pages.jsonl
    parse_report.json
```

parse_report 必须记录：

- parse_status
- parser_mode
- page_count
- text_length
- error_message
- next_action

百分比只表示解析进度，不表示全链路进度。

## knowledge_bases/

用途：保存知识库。

推荐：

```text
knowledge_bases/
  kb_catalog.json
  <kb_id>/
    manifest.json
    chunks.jsonl
    source_map.json
    source_trace.jsonl
    index_metadata.json
    validation_records.jsonl
```

manifest 字段：

- kb_id
- workspace_id
- name
- status
- source_docs
- parent_kbs
- chunk_count
- duplicate_count
- near_duplicate_count
- conflict_count
- is_deleted
- created_at
- updated_at

chunks.jsonl 字段：

- chunk_id
- source_doc_id
- page_or_section
- chunk_hash
- text
- lineage

source_map.json 必须能追到：

```text
KB -> parent KB -> source document -> page/section/chunk
```

## 合并知识库数据规则

合并生成新目录：

```text
knowledge_bases/<new_kb_id>/
```

不得覆盖 source KB 目录。

合并 manifest 必须记录：

- parent_kbs
- source_docs union
- total_input_chunks
- deduped_chunks
- duplicate_count
- near_duplicate_count
- conflict_count
- final_chunks
- merge_status

中断状态只允许：

- completed
- failed
- rolled_back

不允许半成品以 available / completed 展示。

## artifacts/

用途：保存普通用户成果索引。

推荐：

```text
artifacts/
  catalog.json
  documents/
  skill_packages/
  agent_packages/
```

catalog 只允许记录普通成果：

- knowledge_base
- document
- skill_package
- agent_package

不得把 audit report、acceptance report、validation report、usage、parallel、catalog、source、organize、package 工程证据写进普通成果。

## operations/

用途：记录操作历史。

推荐：

```text
operations/
  operation_records.jsonl
  failed_records.jsonl
  support_exports/
```

字段：

- record_id
- action
- target_type
- target_id
- status
- message
- retryable
- ignored
- diagnostic_ref
- created_at

失败记录必须可解释、可重试、可忽略或可导出诊断。

## config/

用途：保存非密钥配置。

规则：

- 不写入 API key 明文。
- 不写入 token、cookie、Authorization header。
- 外部服务配置状态和连接测试结果可以保存。
- 本地基础链路不得依赖外部服务配置存在。

## audit/

用途：保存内部审计、事件和诊断。

这些文件可包含工程细节，但不得进入普通成果页。

## 数据迁移原则

当 schema 变化时：

- 旧数据可读优先。
- 迁移前写 migration plan。
- 迁移失败不得损坏原数据。
- 迁移后写 migration record。
- UI 必须能解释旧数据不可读或部分可读。

## 后台真值检查

每条主链路至少检查：

- workspace_manifest 当前工作区。
- source_manifest 来源数量。
- documents 解析状态。
- kb_catalog 和 KB manifest。
- chunks 数量。
- source_map 可追溯。
- artifacts/catalog 类型合法。
- operation_records 记录完整。
- 重启后读取一致。
