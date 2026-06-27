# 术语表

## 目的

本文件统一项目术语，避免同一对象在 UI、代码、测试和文档中含义混乱。

## 核心术语

| 术语 | 定义 | 普通 UI 表达 |
| --- | --- | --- |
| Workspace | 用户数据隔离单位 | 工作区 |
| SourceDoc | 导入的原始来源记录 | 来源资料 |
| Document Library | 已导入并可查看的资料集合 | 文档库 |
| Chunk | 知识库引用的最小文本片段 | 片段 |
| KnowledgeBase | 由来源资料和片段构成的知识资产 | 知识库 |
| Merged KnowledgeBase | 由多个知识库派生的新知识库 | 合并知识库 |
| Artifact | 用户成果索引 | 成果 |
| OperationRecord | 用户操作历史 | 操作记录 |
| Skill | 可复用的方法或能力包 | Skill / Skill 包 |
| Agent | 绑定知识库和 Skill 的助手 | 助手 |
| Workgroup | 多个助手或角色协作任务 | 工作小组 |

## 数据术语

| 术语 | 定义 |
| --- | --- |
| source_docs | 知识库使用的来源资料集合 |
| parent_kbs | 合并知识库的来源知识库 |
| lineage | 从成果追溯到来源的链路 |
| source_map | KB 到来源资料和片段的映射 |
| source_trace | 操作或回答的来源追踪 |
| chunk_hash | 片段内容指纹 |
| content_hash | 原始来源内容指纹 |
| tombstone | 删除或回滚标记 |

## 状态术语

普通 UI 只使用：

- 已可用
- 已连接
- 已配置，待测试
- 未配置
- 测试失败
- 可选，未安装
- 需要处理

内部状态可以更细，但必须映射后再进入普通 UI。

## 禁止混淆

- 文档库不是知识库。
- 来源资料不是成果。
- 操作记录不是成果。
- 审计报告不是普通成果。
- 合并知识库不是覆盖原知识库。
- Skill 不是 Agent。
- 工作小组不是单个助手。

## 内部术语使用边界

以下词可出现在代码、测试、日志、诊断、审计报告中，但不应直接出现在普通 UI：

- runtime
- provider
- adapter
- parser
- router
- capability matrix
- dependency_gated
- needs_secret_config

普通 UI 应使用用户语言表达。
