# 黑糖 Knowledge Workbench 产品架构 v3

日期：2026-06-19
定位：产品架构重构版
输入依据：

- `heitang_knowledge_workbench_full_prd_v2_2026-06-18.md`
- `heitang_industrial_requirements_document_2026-06-18.md`
- `heitang_industrial_feature_acceptance_matrix_2026-06-18.md`
- `Campaign_6_外部运行时参考队列.md`

---

## 1. 架构重构目标

原架构已经有主链路：

```text
资料导入
  → 文档库
  → 知识库
  → 检索验证
  → 文档 / Skill / Agent / A2A
```

但当前最大问题不是能力少，而是能力之间缺少清晰链路。为了避免继续变成“功能按钮堆叠”，v3 架构必须显式补上三层：

```text
索引层
RAG 层
编排层
```

这三层的作用：

| 新增层 | 作用 | 解决的问题 |
|---|---|---|
| 索引层 | 把知识库变成可检索、可召回、可追溯的结构 | 知识库不是文件堆，而是可调用资产 |
| RAG 层 | 把检索结果转成有证据、有引用、有验证的生成上下文 | 避免文档和 Agent 空泛生成 |
| 编排层 | 按用户目标调度 KB、索引、模板、模型、Skill、Agent、A2A | 让功能形成真实使用链路 |

---

## 2. 产品一句话定义

黑糖 Knowledge Workbench 是一个本地优先的知识资产工作台，帮助用户把资料转成文档库，再构建知识库、索引和 RAG 能力，并通过编排层生成文档、Skill、Agent 和多 Agent 协作结果。

---

## 3. 产品总架构

```text
L0 工作区层 Workspace
  管理项目边界、资源隔离、配置、审计、产物、恢复。

L1 资料接入层 Import Source
  文件、文件夹、网页链接、外部 Skill、外部参考项目登记。

L2 文档库层 Document Library
  保存解析、清洗、结构化后的文档内容。

L3 标准化知识包层 Standard Knowledge Package
  将文档库内容封装成可版本化、可流通、可追溯的标准包。
  OKF 属于这一层的候选标准。

L4 知识库层 Knowledge Base
  用户从文档库 / 标准包中选择内容，构建一个或多个领域知识库。

L5 索引层 Index Layer
  为知识库建立关键词索引、向量索引、元数据索引、引用索引、记忆索引。

L6 RAG 与验证层 Retrieval / RAG / Validation
  查询改写、召回、重排、引用、外部事实验证、人工纠偏、验证报告。

L7 编排层 Orchestration
  根据目标调度知识库、索引、模板、模型、Provider、Skill、Agent、A2A。

L8 产物层 Artifacts
  文档、Skill、Agent 配置、A2A 报告、审计报告、导出包。

L9 治理配置层 Governance / Settings
  Provider、Redis、向量库、导出器、网络授权、安全、日志、版本、回滚。
```

---

## 4. 主链路架构

### 4.1 全局主链路

```text
配置初始化
  ↓
创建或选择工作区
  ↓
导入文件 / 文件夹 / 网页链接 / 外部 Skill
  ↓
解析所有导入内容
  ↓
进入文档库
  ↓
文档库内容标准化，可选封装为 OKF / 标准知识包
  ↓
从文档库选择内容组建一个或多个知识库
  ↓
为知识库构建索引
  ├─ 关键词索引
  ├─ 向量索引
  ├─ 元数据索引
  ├─ 引用索引
  └─ 记忆索引
  ↓
进入 RAG 与验证层
  ├─ 查询改写
  ├─ 单 KB / 多 KB 检索
  ├─ chunk 召回
  ├─ 重排
  ├─ 引用证据
  ├─ 外部事实验证
  └─ 人工纠偏
  ↓
编排层按目标生成产物
  ├─ 文档生成
  ├─ Skill 工厂
  ├─ 单 Agent
  └─ A2A 多 Agent
  ↓
产物中心 / 审计中心 / 导出
```

### 4.2 数据流总图

```text
ImportSource
  ↓
ParsedDocument
  ↓
DocumentLibrary
  ↓
StandardKnowledgePackage / OKF Candidate
  ↓
KnowledgeBase
  ↓
IndexProfile
  ↓
RetrievalRun / RAGContext
  ↓
OrchestrationPlan
  ↓
GeneratedDocument / SkillPackage / AgentProfile / A2AReport
```

### 4.3 产物流总图

```text
一个文档库
  → 可组建多个知识库
  → 可封装为标准知识包

一个知识库
  → 可构建多个索引
  → 可生成多个文档
  → 可生成多个 Skill
  → 可绑定多个 Agent

一个索引配置
  → 支持关键词检索
  → 支持向量检索
  → 支持引用追溯
  → 支持 Agent 长期记忆

一个 RAG 运行
  → 产生命中 chunks
  → 产生引用列表
  → 产生验证报告
  → 支撑文档 / Agent 回复

一个 Skill
  → 可导出到外部平台
  → 可绑定到多个 Agent
  → 可与知识库再融合生成个性化 Skill

一个 Agent
  → 可绑定多个知识库
  → 可绑定多个 Skill
  → 可配置不同模型、记忆、工具
  → 可参与多 Agent 协作
```

---

## 5. 核心对象关系

```text
Workspace
  ├─ DocumentLibrary
  │   ├─ RawSource[]
  │   ├─ ParsedDocument[]
  │   ├─ CleanedDocument[]
  │   └─ StandardKnowledgePackage[]
  │
  ├─ KnowledgeBase[]
  │   ├─ SourceDocument[]
  │   ├─ BuildConfig
  │   ├─ Manifest
  │   ├─ Chunks
  │   ├─ QualityReport
  │   └─ Version[]
  │
  ├─ IndexProfile[]
  │   ├─ KeywordIndex
  │   ├─ VectorIndex
  │   ├─ MetadataIndex
  │   ├─ CitationIndex
  │   └─ MemoryIndex
  │
  ├─ RetrievalRun[]
  │   ├─ QueryRewrite
  │   ├─ RetrievedChunk[]
  │   ├─ RerankResult
  │   ├─ Citation[]
  │   ├─ ExternalValidation
  │   └─ HumanCorrection
  │
  ├─ OrchestrationPlan[]
  │   ├─ TargetOutputType
  │   ├─ Template
  │   ├─ SelectedKB[]
  │   ├─ SelectedIndex[]
  │   ├─ SelectedModel
  │   ├─ SelectedSkill[]
  │   └─ SelectedAgent[]
  │
  ├─ SkillPackage[]
  │   ├─ SourceKnowledgeBase[]
  │   ├─ OptionalExternalSkill
  │   ├─ TargetPlatform
  │   └─ GovernanceReport
  │
  ├─ Agent[]
  │   ├─ AgentWorkspace
  │   ├─ KnowledgeBase[]
  │   ├─ SkillPackage[]
  │   ├─ ModelConfig
  │   ├─ MemoryConfig
  │   └─ ToolConfig[]
  │
  ├─ A2ASession[]
  │   ├─ ParentWorkspace
  │   ├─ ChildAgentWorkspace[]
  │   ├─ Topic
  │   ├─ Rounds
  │   ├─ Summary
  │   └─ Report
  │
  ├─ Artifacts
  ├─ Configs
  └─ AuditLogs
```

---

## 6. 文档库、知识库、索引、RAG、编排边界

| 模块 | 定义 | 输入 | 输出 | 用户感知 |
|---|---|---|---|---|
| 文档库 | 处理后的文件内容资产库 | 原始文件、网页、解析结果 | 文档记录、正文、chunks、解析报告 | 强 |
| 标准知识包 | 文档库内容的标准封装 | 文档库内容 | OKF / manifest / metadata / package | 中 |
| 知识库 | 从文档库组合出的知识资产 | 文档库 / 标准知识包 | KB manifest、chunks、quality report、版本 | 强 |
| 索引层 | 知识库的检索结构 | KB chunks、metadata、embedding | keyword/vector/citation/memory index | 中 |
| RAG 层 | 检索增强生成与验证流程 | 查询、索引、KB、外部验证 Provider | 检索结果、引用、验证报告、上下文 | 强 |
| 编排层 | 调度资源生成产物 | 用户目标、模板、KB、模型、Skill、Agent | 文档、Skill、Agent 回复、A2A 报告 | 强 |

关键判断：

- 文档不是从 OKF 直接生成，而是由编排层选择模板、知识库、索引、RAG 上下文和模型生成。
- 知识库不是索引，索引是知识库的技术检索结构。
- RAG 不是知识库，RAG 是调用知识库和索引的方法。
- Agent 不是空聊天框，Agent 是工作区、KB、Skill、模型、记忆、工具、权限的组合体。
- A2A 不是替代单 Agent，而是多 Agent 总工作区内的协作机制。

---

## 7. 工作区架构

### 7.1 工作区类型

| 类型 | 用途 | 要求 |
|---|---|---|
| normal | 普通知识工作区 | 可创建、切换、删除、持久化 |
| single_agent | 单 Agent 工作区 | 绑定一个 Agent 的资源边界 |
| parent_multi_agent | 多 Agent 总工作区 | 管理 A2A 会话和子 Agent |
| child_agent | 子 Agent 工作区 | 独立 KB / Skill / 模型 / 记忆 |
| temp | 临时任务工作区 | 可清理、可审计 |

### 7.2 工作区隔离规则

- KB、Skill、Agent、记忆、运行记录按工作区隔离。
- 单 Agent 只能访问自己工作区授权内容。
- 多 Agent 子工作区只能访问自身 KB / Skill。
- 总工作区只汇总子 Agent 输出和共享授权内容。
- A2A 不得直接篡改子 Agent 配置。

---

## 8. 索引层架构

### 8.1 索引类型

| 索引 | 用途 | 默认策略 |
|---|---|---|
| Keyword Index | 关键词检索、本地兜底 | 默认启用 |
| Vector Index | 语义检索、长期记忆 | 可选启用 |
| Metadata Index | 文档、页码、chunk、来源追溯 | 默认启用 |
| Citation Index | 引用反查、证据链 | 默认启用 |
| Memory Index | Agent 长期记忆 | 可选启用 |

### 8.2 索引存储策略

```text
本地索引
  → 默认可用
  → 不依赖外部服务
  → 适合个人用户和离线优先

外部向量库
  → Qdrant / Chroma / Milvus / pgvector / Weaviate / custom
  → 通过设置页配置
  → 连接测试通过后绑定 KB / Agent
  → 不默认打包服务本体
```

### 8.3 索引层产物

- `index_metadata.json`
- `keyword_index`
- `vector_index_reference`
- `citation_index.json`
- `memory_index_reference`
- `index_build_report.json`

---

## 9. RAG 层架构

### 9.1 RAG 运行链路

```text
用户问题 / 生成目标
  → 查询改写
  → 选择 KB / 多 KB
  → 调用索引层
  → 召回 chunks
  → 重排
  → 生成引用上下文
  → 可选外部事实验证
  → LLM 生成回答 / 文档 / Agent 输出
  → 保存验证报告
```

### 9.2 RAG 必须保存的证据

- 原查询。
- 改写查询。
- 选择的 KB。
- 命中 chunk。
- 命中分数。
- 来源文档。
- 引用列表。
- 覆盖率指标。
- 外部验证结果。
- 人工纠偏。
- 生成输出。

---

## 10. 编排层架构

### 10.1 编排层定位

编排层是产品运行时的大脑，不直接存储知识，而是根据用户目标选择资源和执行路径。

### 10.2 编排对象

```text
OrchestrationPlan
  ├─ plan_id
  ├─ workspace_id
  ├─ target_type: document / skill / agent_reply / a2a_report
  ├─ selected_kb_ids
  ├─ selected_index_profile_ids
  ├─ selected_template_id
  ├─ selected_model_config_id
  ├─ selected_skill_ids
  ├─ selected_agent_ids
  ├─ retrieval_policy
  ├─ citation_policy
  ├─ external_validation_policy
  ├─ output_format
  └─ audit_path
```

### 10.3 编排策略

| 场景 | 编排层负责 |
|---|---|
| 文档生成 | 选 KB、索引、模板、RAG 策略、模型、导出格式 |
| Skill 生成 | 选来源 KB、外部 Skill、目标平台、验证样例 |
| 单 Agent 对话 | 选 Agent 工作区、KB、Skill、模型、记忆、引用策略 |
| A2A 协作 | 选总工作区、子 Agent、任务分发、汇总策略 |
| 外部验证 | 选 Search Provider、网络授权、证据合并方式 |
| 失败恢复 | 选重试、降级、本地兜底、错误报告 |

---

## 11. Skill 架构

### 11.1 Skill 来源

| 来源 | 说明 |
|---|---|
| KB 生成 Skill | 从知识库抽象方法论、规则、输入输出 |
| 多 KB 生成 Skill | 多知识库综合为复合 Skill |
| 外部 Skill 本地化 | 外部 Skill + 本地知识库融合 |
| Skill 二次融合 | Skill + KB / Skill + Skill |

### 11.2 Skill 与索引 / RAG / 编排关系

```text
知识库
  → 索引层提取方法、概念、引用
  → RAG 层验证方法论是否有来源
  → 编排层生成 Skill 草稿
  → 用户编辑 / 验证
  → 导出或绑定 Agent
```

---

## 12. Agent 架构

### 12.1 Agent 不是空聊天框

Agent 必须由以下资源组成：

- 工作区。
- Agent 类型。
- 创建模式：simple / advanced。
- 绑定知识库。
- 绑定 Skill。
- 绑定模型。
- 短期记忆。
- 长期记忆。
- 工具。
- 权限边界。
- 审计记录。

### 12.2 单 Agent

```text
SingleAgentWorkspace
  ├─ AgentProfile
  ├─ KB[]
  ├─ Skill[]
  ├─ ModelConfig
  ├─ MemoryConfig
  ├─ ChatHistory
  └─ AuditLog
```

### 12.3 多 Agent / A2A

```text
ParentMultiAgentWorkspace
  ├─ Topic
  ├─ ChildAgentWorkspace A
  ├─ ChildAgentWorkspace B
  ├─ ChildAgentWorkspace C
  ├─ A2ARounds
  ├─ ConflictPoints
  ├─ Consensus
  └─ A2AReport
```

---

## 13. 配置与 Provider 架构

| 配置 | 用途 | 默认策略 |
|---|---|---|
| Model Provider | LLM 调用、Embedding 调用 | 用户配置，不内置密钥 |
| Parser Provider | PDF / DOCX / HTML / OCR 解析增强 | optional |
| Search Provider | 外部事实验证 | 网络授权后启用 |
| Redis | 短期记忆、A2A 状态、任务缓存 | optional，不打包服务本体 |
| Vector DB | 知识库索引、长期记忆、Skill 来源检索 | optional，不打包服务本体 |
| Exporter | Markdown / DOCX / PDF / PPTX / JSON / CSV | Markdown 默认，其他配置后启用 |

---

## 14. 登记项目架构治理

### 14.1 登记项目不是已接入能力

登记项目只能处于：

```text
reference_only
needs_verification
verified_candidate
integration_planned
integrated
```

不得跳过验证直接进入 `integrated`。

### 14.2 登记项目分类

| 类型 | 候选 | 架构用途 | 当前边界 |
|---|---|---|---|
| Skill 方法论 | andrej-karpathy-skills | Skill 规则组织参考 | reference_only |
| Agent Runtime / Memory | GBrain、pi-mono | Post-9 Agent runtime 参考 | needs_verification / reference_only |
| 代码理解 | CodeGraph、Understand Anything、codebase-memory-mcp | 开发侧审查辅助 | 不进用户主链路 |
| 插件工作流 | claude-plugins-official、role-based-plugins | 插件化协作参考 | 不声明兼容或已接入 |
| 输出扩展 | Presenton | PPT 导出参考 | 后续 Exporter 候选 |
| PDF 解析 | OpenDataLoader PDF | Parser Provider 候选 | 需 verification gate |
| 治理 | HeiTang-governance-skill | LongRun / Evidence Gate 参考 | 不作为 runtime 依赖 |
| GPU / 视频 | NVlabs/LongLive | future reference | 不进当前产品 |

### 14.3 Verification Gate

接入前必须验证：

- license。
- 安装方式。
- 依赖体积。
- 安全风险。
- API / CLI 行为。
- 是否需要外部服务。
- Windows 可运行性。
- clean checkout 可复现性。
- CI 成本。
- EXE 打包体积影响。
- optional / dependency-gated 方案。

---

## 15. 页面架构

推荐导航：

```text
首页 / 工作本
文档库
知识库
检索与验证
文档生成
Skill 工厂
Agent 工作区
A2A 协作
产物中心
治理与审计
设置
```

页面职责：

| 页面 | 职责 |
|---|---|
| 首页 / 工作本 | 工作区、最近真实任务、健康状态、下一步行动 |
| 文档库 | 导入、解析、预览、搜索、删除、加入 KB |
| 知识库 | 多 KB、版本、构建、索引、合并、复制、删除 |
| 检索与验证 | RAG 检索、引用、外部验证、人工纠偏 |
| 文档生成 | 模板、大纲、正文、引用、历史、导出 |
| Skill 工厂 | KB 生成 Skill、外部 Skill 本地化、验证、导出 |
| Agent 工作区 | 单 Agent 创建、资源绑定、对话、审计 |
| A2A 协作 | 总工作区、子 Agent、任务分发、共识报告 |
| 产物中心 | 文档、Skill、Agent、A2A 报告统一管理 |
| 治理与审计 | 日志、验证报告、权限、错误、恢复 |
| 设置 | Provider、Redis、向量库、导出器、网络授权 |

---

## 16. 架构推版阻断项

出现以下任一问题，不应推版：

1. 文档库只是文件列表，没有解析内容。
2. 知识库无法从文档库选择来源。
3. 知识库没有索引元数据。
4. 检索结果无法追溯到 KB、文档、chunk。
5. RAG 结果没有引用。
6. 编排层没有记录输入资源和输出产物。
7. Agent 没有工作区资源边界。
8. A2A 没有总工作区和子 Agent 工作区。
9. 登记项目被写成已接入能力。
10. Redis / 向量库被默认打包进 EXE。
