# 工作区与数据模型设计源

## 目的

本文件定义工作区、资料、文档库、知识库、成果和操作记录的产品数据模型。它不替代具体数据库 schema，但定义业务语义和验收真值。

## 工作区

工作区是用户数据隔离单位。

必须保存：

- workspace_id
- name
- root_path
- created_at
- updated_at
- current_marker
- status

必须支持：

- 创建
- 切换
- 删除或清空
- 删除后重新创建
- 重启恢复当前工作区

删除工作区不得误删其他工作区。清空工作区不得删除应用配置和外部服务配置。

## SourceDoc

SourceDoc 表示导入资料的原始来源。

必须保存：

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
- created_at

去重规则：

- 同一工作区内，相同 content_hash 应识别为重复。
- 文件和文件夹导入必须与链接导入使用一致的去重语义。
- 重复导入不能制造多个无法解释的普通成果。

## Document Library

文档库是已导入资料的用户可见集合。

文档库必须展示：

- 真实来源名称。
- 解析状态。
- 摘要或明确“暂无摘要”。
- 正文预览或明确“暂无正文预览”。
- 失败原因和下一步动作。

不得显示假摘要、假正文、假测试问题或假成果。

## Chunk

Chunk 是知识库生成和引用追溯的最小片段。

必须保存：

- chunk_id
- source_doc_id
- page_or_section
- chunk_hash
- text
- lineage
- created_at

片段必须可追溯到原始 SourceDoc。不能只显示“KB chunk 12”这类无法让用户理解来源的引用。

## KnowledgeBase

KnowledgeBase 是基于 SourceDoc 和 Chunk 生成的知识资产。

必须保存：

- kb_id
- workspace_id
- name
- source_docs
- chunks
- parent_kbs
- lineage
- status
- is_deleted
- created_at
- updated_at

知识库必须支持：

- 生成
- 查看来源
- 查看片段
- 验证
- 导出
- 删除
- 重启恢复

删除知识库时：

- 普通列表移除或标记删除。
- 不误删 source_docs。
- 不误删 parent_kbs。
- 不误删其他知识库 chunks。
- 成果页和验证页不再默认使用已删除知识库。

## 合并知识库

合并生成新知识库：

```text
K1 + K2 -> K_MERGED
```

新知识库必须保存：

- parent_kbs
- source_docs union
- deduped chunks
- duplicate_count
- near_duplicate_count
- conflict_count
- final_chunks
- lineage

去重规则：

- 同一 source_doc_id + page/section + chunk_hash 相同：duplicate。
- 不同来源但文本相同：possible_duplicate，保留来源关系。
- 文本相似但不完全一致：near_duplicate，进入待核查。

冲突规则：

- 不自动选择一个覆盖另一个。
- 不静默丢弃。
- 标记为“发现冲突 / 待核查”。
- 验证结果中提示用户核查来源。

## Artifact

Artifact 是用户成果。

普通成果只允许：

- knowledge_base
- document
- skill_package
- agent_package

必须保存：

- artifact_id
- workspace_id
- type
- name
- source_refs
- file_path
- status
- created_at

工程证据类文件不得进入普通成果列表。

## OperationRecord

OperationRecord 是操作历史，不是成果。

必须保存：

- record_id
- workspace_id
- action
- target_type
- target_id
- status
- message
- retryable
- diagnostic_ref
- created_at

必须支持：

- 清理普通历史。
- 查看失败原因。
- 重试失败记录。
- 忽略失败记录。
- 导出操作历史或支持诊断包。

## Skill

Skill 必须说明依赖模型：

- 快照型：源资料删除后仍可用。
- 指针型：源资料缺失时必须明确提示不可用或需要恢复来源。

UI 必须讲清楚实际模型，不能静默失败。

## Agent

Agent 必须保存：

- agent_id
- name
- bound_kbs
- bound_skills
- allow_general_knowledge
- created_at
- updated_at

回答必须保存：

- question
- answer
- cited_sources
- out_of_scope_status
- created_at

## 后台真值 Oracle

每条 E2E 必须至少检查：

- 文件数
- source_doc 数
- chunk 数
- parent_kbs
- source_docs
- artifact 类型
- operation_record 数量
- 删除前后对象状态
- 重启后对象状态

UI 看起来通过但后台真值不一致，判定为未通过。
