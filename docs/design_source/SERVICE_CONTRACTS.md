# Service Contracts

## 目的

本文件定义 UI 与业务服务 / runtime 之间的产品级接口契约。从 0 开发时按本文件设计服务；修复现有项目时用本文件判断调用边界是否清楚。

## 通用返回结构

所有服务动作建议返回：

```text
success
status
user_message
next_actions
target_id
artifact_refs
operation_record_id
error_code
diagnostic_ref
```

UI 不应直接解释底层异常栈。底层错误必须映射成用户可理解的信息。

## WorkspaceService

### createWorkspace

输入：

- name
- root_path 可选

输出：

- workspace_id
- workspace_path
- current_workspace

规则：

- 名称为空时返回可解释错误。
- 同名时提示覆盖、创建副本或要求改名。
- 创建后必须可重启恢复。

### deleteWorkspace

输入：

- workspace_id
- confirm

输出：

- deleted / cancelled / failed
- next_current_workspace

规则：

- 不误删其他 workspace。
- 不删除源码。
- 不删除全局配置。
- 删除后必须能重新创建。

## ImportService

### importSources

输入：

- workspace_id
- source_type：file / folder / link
- paths_or_urls

输出：

- source_docs
- duplicate_count
- failed_count
- operation_record_id

规则：

- 文件、文件夹、链接使用一致去重语义。
- 链接不能真实读取时必须明确不可用或需配置。

### parseDocuments

输入：

- workspace_id
- source_doc_ids

输出：

- parse_status
- parse_progress_percent
- parsed_docs
- failed_docs

规则：

- 百分比只表示解析进度。
- 不生成假摘要或假正文。

## KnowledgeBaseService

### buildKnowledgeBase

输入：

- workspace_id
- name
- source_doc_ids

输出：

- kb_id
- source_docs
- chunk_count
- source_map_ref

规则：

- 无来源时禁用或返回明确原因。
- 生成后知识库列表、文档生成、Agent 绑定入口应刷新。

### mergeKnowledgeBases

输入：

- workspace_id
- source_kb_ids
- new_kb_name
- merge_options

输出：

- new_kb_id
- parent_kbs
- source_docs
- total_input_chunks
- deduped_chunks
- duplicate_count
- near_duplicate_count
- conflict_count
- status

规则：

- 创建新 KB。
- 不修改 source KB。
- 中断后不显示半成品可用。
- 重复合并要提示已存在或生成清楚的新版本。

### deleteKnowledgeBase

输入：

- kb_id
- confirm

输出：

- deleted / cancelled / failed

规则：

- 不误删 parent_kbs。
- 不误删 source_docs。
- 删除后其他页面刷新或提示刷新。

### exportKnowledgeBase

输入：

- kb_id
- target_path

输出：

- export_path
- open_folder_action

规则：

- 导出失败时说明原因和下一步。

## KnowledgeValidationService

### validateKnowledgeBase

输入：

- kb_ids
- question
- options

输出：

- answer
- cited_sources
- evidence_snippets
- found_issues
- suggested_additional_materials
- record_id

规则：

- KB 外问题不得编造。
- 引用必须能追到原始文档和片段。
- 结果可保存、重试、查看来源片段。

## DocumentGenerationService

### generateDocument

输入：

- kb_id
- document_name
- document_type
- template_id
- output_format
- source_display_policy

输出：

- document_id
- file_name
- format
- save_path
- artifact_id

规则：

- 先选知识库。
- 用户必须能命名文档。
- 生成后支持打开、导出、删除。

## SkillService

### generateSkillFromKnowledgeBase

输入：

- kb_id
- skill_name
- dependency_model：snapshot / pointer

输出：

- skill_id
- skill_package_ref
- artifact_id

规则：

- UI 必须说明 Skill 是快照型还是指针型。

### importSkill

输入：

- skill_path
- skill_name 可选

输出：

- skill_id
- validation_status

规则：

- 导入失败必须可解释。

## AgentService

### createAgent

输入：

- name
- bound_kbs
- bound_skills
- allow_general_knowledge

输出：

- agent_id
- status

规则：

- 默认 `allow_general_knowledge = false`。

### askAgent

输入：

- agent_id
- question

输出：

- answer
- cited_sources
- out_of_scope_status

规则：

- 超出绑定知识库时明确无依据。
- 通用知识开启时标注非当前知识库依据。

## ArtifactService

### listArtifacts

输入：

- workspace_id
- types 可选

输出：

- artifacts

规则：

- 只返回知识库、文档、Skill 包、Agent 包。

### deleteArtifact

输入：

- artifact_id
- confirm

输出：

- deleted / cancelled / failed

规则：

- 不误删来源资产。

## OperationRecordService

### listOperationRecords

输入：

- workspace_id

输出：

- records

### retryOperation

输入：

- record_id

输出：

- new_record_id
- status

### exportSupportPackage

输入：

- record_ids
- target_path

输出：

- export_path
- contains_summary

规则：

- 不泄露密钥。
- 说明包含什么和导出到哪里。
