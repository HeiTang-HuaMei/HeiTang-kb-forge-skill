# 架构边界设计源

## 目的

本文件定义前端、控制层、运行时、数据层和外部服务之间的职责边界。编码前必须先确认改动落在哪一层，不能跨层补丁式扩散。

## 分层

```text
UI 层
-> Controller / ViewModel 层
-> Product Service 层
-> Runtime / Adapter 层
-> Storage / External Service 层
```

## UI 层职责

UI 层只负责：

- 展示用户任务。
- 展示用户可理解的状态。
- 收集用户输入。
- 触发用户动作。
- 展示下一步操作。
- 展示错误和恢复建议。

UI 层不得：

- 直接拼接底层文件结构作为业务真相。
- 直接暴露 runtime、adapter、provider、parser、router 等实现术语。
- 用测试报告或审计文件冒充用户成果。
- 把内部状态枚举原样显示给用户。

## Controller / ViewModel 层职责

Controller / ViewModel 层负责：

- 把产品对象转换成 UI 状态。
- 把内部状态映射成用户语言。
- 控制按钮启用、禁用和原因说明。
- 保持页面切换、语言切换、重启恢复后的状态一致。
- 聚合后台结果，但不修改底层业务规则。

## Product Service 层职责

Product Service 层负责真实产品动作：

- 工作区创建、删除、恢复。
- 资料导入、去重、整理。
- 文档库管理。
- 知识库生成、合并、验证、删除、导出。
- 文档生成。
- Skill 生成、导入、删除、导出。
- Agent 创建、绑定、问答、删除。
- 成果和操作记录管理。

跨页面共享的业务规则必须放在 Product Service 层或更低层，不得复制在多个页面组件里。

## Runtime / Adapter 层职责

Runtime / Adapter 层负责对接具体实现：

- 文档解析实现。
- Embedding 实现。
- 向量检索实现。
- Redis 或记忆库实现。
- 模型接口实现。
- 文件导出实现。
- 外部连接实现。

这些词可以出现在代码、日志、诊断、审计报告中，但不得作为普通产品 UI 的默认表达。

## Storage / External Service 层职责

Storage 层负责持久化真实状态：

- workspace
- document
- source_doc
- chunk
- knowledge_base
- parent_kbs
- lineage
- artifact
- operation_record
- task_state
- configuration

外部服务是增强项，不是本地基础链路的前置条件。

## 数据真值原则

UI 不能只看“是否有文件存在”。每个主对象必须有可对账的后台真值：

- 工作区：id、名称、路径、当前状态、创建时间。
- 文档：source_doc_id、文件名、解析状态、摘要、正文预览。
- 知识库：id、名称、source_docs、chunks、parent_kbs、lineage、状态。
- 文档成果：名称、类型、格式、保存位置、来源知识库。
- Skill：名称、来源类型、依赖模型、导出位置。
- Agent：名称、绑定知识库、绑定 Skill、回答来源。
- 操作记录：动作、对象、结果、时间、失败原因、重试入口。

## 知识边界

Agent 默认只基于绑定知识库回答。

当问题超出绑定知识库范围时，必须：

- 明确提示当前知识库无依据。
- 不编造答案。
- 不引用不属于当前知识库的来源。

如果允许通用知识，必须由用户显式开启，并在回答中标注“非当前知识库依据”。

## 合并知识库边界

合并知识库是创建新知识库，不是更新或覆盖原知识库。

必须保持：

- source_kbs_not_modified = true
- source_docs_union_correct = true
- chunk_dedup_rule_applied = true
- lineage_preserved = true
- merged_kb_delete_safe = true
- merged_kb_citation_trace_ok = true

中断后只允许：

- 新知识库完整生成，状态 completed。
- 新知识库不存在，或状态 failed / rolled_back。

不允许半成品显示为可用。

## 状态映射

内部状态可以细，用户状态必须少。

示例：

| 内部事实 | 用户表达 |
| --- | --- |
| local parser available | 基础解析：已可用 |
| external OCR missing | OCR：可选，未安装 |
| model key missing | AI 模型接口：未配置 |
| connection test failed | 测试失败 |
| dependency optional | 可选，未安装 |
| retryable task failed | 需要处理 |

## 变更原则

编码前必须回答：

- 改动属于哪一层？
- 上游输入是什么？
- 下游输出是什么？
- 是否改变持久化数据？
- 是否改变用户可见任务链？
- 如何验证 UI、后台真值和重启后一致？

如果回答不清楚，先补设计再编码。
