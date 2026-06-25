# Knowledge Memory Compiler Design

Status: `p2_backlog_candidate_not_blocking_p1`

This document records a P2 candidate capability for large static document knowledge bases. It is inspired by memory-compilation research patterns, but the user-facing product language must use plain names such as "深度知识消化" or "跨文档推理". The UI must not expose the external project name as a feature name.

## 1. Product Goal

Knowledge Memory Compiler adds a deep digestion layer for large document libraries.

It does not replace RAG. RAG remains the retrieval path for source-grounded answers. Knowledge Memory Compiler prepares higher-level memory objects before and around retrieval so cross-document questions can start from stable anchors, entities, relations, and evidence.

Target users should understand it as:

- 深度知识消化.
- 跨文档推理.
- 从大量静态资料中整理出可追溯的知识脉络.

## 2. Scope

This is a P2 backlog capability.

It must not block P1 work, P1 validation, or any P1 Release Gate path. It should be planned as an enhancement after the current P1 queue is closed and after the relevant P2 gate is opened.

The capability is aimed at:

- Large static document libraries.
- Curated knowledge packages.
- Cross-document source trace.
- Repeated knowledge questions that need stable context instead of one-shot retrieval only.

## 3. Positioning Against RAG

RAG answers a user query by retrieving relevant chunks and generating a source-grounded response.

Knowledge Memory Compiler prepares durable memory artifacts that can improve retrieval, reasoning, validation, and user inspection.

Expected relationship:

```text
Document Library
-> Parse / Chunk / Source Trace
-> RAG Index
-> Knowledge Memory Compiler
-> Facts / Entities / Relations / Memory Cards / Validation Reports
-> Anchor -> Entity -> Evidence -> Answer
```

RAG remains the evidence retrieval foundation. The compiler adds structured, reviewable memory layers that point back to original sources.

## 4. Inputs

The compiler accepts:

- Document library.
- Knowledge package.
- Source trace.

Input requirements:

- Every compiled object must keep a path back to source trace.
- Unsupported or low-confidence sources must be marked for review.
- The compiler must not claim knowledge that cannot be traced to input sources.

## 5. Outputs

The compiler produces:

- `facts`
- `entities`
- `relations`
- `compound_questions`
- `cross_doc_summaries`
- `memory_cards`
- `validation_report`

Output expectations:

| Output | Purpose |
| --- | --- |
| `facts` | Atomic claims with source references and confidence notes. |
| `entities` | People, organizations, places, concepts, products, files, or domain objects. |
| `relations` | Source-grounded links between entities and facts. |
| `compound_questions` | Multi-hop questions that the document library can answer. |
| `cross_doc_summaries` | Summaries that explicitly merge evidence from multiple documents. |
| `memory_cards` | User-readable durable cards for repeated reuse. |
| `validation_report` | Checks for source trace coverage, contradiction, uncertainty, and missing evidence. |

## 6. Query Chain

The intended query chain is:

```text
Anchor -> Entity -> Evidence -> Answer
```

Meaning:

1. Anchor: identify the user's topic, object, project, document group, or known memory card.
2. Entity: resolve relevant entities and relations.
3. Evidence: retrieve source-backed facts, chunks, and cross-document summaries.
4. Answer: generate a response with explicit evidence and uncertainty where needed.

This chain should reduce blind semantic search and make cross-document reasoning easier to inspect.

## 7. User-Facing Language

Ordinary UI copy should use:

- 深度知识消化.
- 跨文档推理.
- 已整理.
- 待消化.
- 需要核对.
- 证据不足.
- 来源可追溯.
- 可用于回答.

The UI should not use:

- MeMo.
- 本地模型训练.
- GPU 训练.
- 大模型打包.
- 蒸馏模型训练.

If an external LLM API is used, the UI should describe the action as "摘要 / 校验 / 生成候选记忆", not as model training.

## 8. Execution Model

Allowed executor roles:

- Existing parser and chunking pipeline.
- Existing source trace and artifact lifecycle.
- External LLM API for summarization, distillation-style extraction, contradiction checks, and validation.
- Redis as an external memory service, when configured.
- Vector DB as an external index service, when configured.

Important boundary:

- Redis and Vector DB remain external services or optional connectors.
- They must not be packaged as service binaries inside the desktop executable.
- External LLM APIs can execute extraction and validation tasks, but the product must not train a local small model as part of this capability.

## 9. Explicit Non-Goals

This capability must not:

- Train a local small model.
- Require GPU training.
- Bundle a local large model.
- Package Redis or Vector DB service binaries into the app executable.
- Replace RAG.
- Treat summaries as evidence without source trace.
- Create a separate product module for an external project.
- Block P1 execution or P1 gates.

## 10. P2 Backlog Fit

Recommended backlog placement:

```text
Phase: P2
Capability family: Knowledge Reliability Engine / Memory & Evidence Layer
Acceptance type: composite
User-facing feature name: 深度知识消化 / 跨文档推理
Release impact: P2 enhancement candidate
P1 blocking status: not_blocking_p1
```

Likely linked blackbox scenarios:

- User selects a large document set and starts "深度知识消化".
- System creates source-traced facts, entities, relations, and memory cards.
- User asks a cross-document question.
- System follows Anchor -> Entity -> Evidence -> Answer.
- User opens the evidence path behind the answer.
- User exports or deletes generated memory artifacts created by this test.

## 11. Acceptance Direction

A future implementation should verify:

- Source-traced input ingestion.
- Fact extraction with source references.
- Entity and relation extraction with source references.
- Compound question generation.
- Cross-document summary generation.
- Memory card creation, opening, export, delete, and restart recovery.
- Validation report generation.
- Query path using Anchor -> Entity -> Evidence -> Answer.
- RAG still works as the source retrieval foundation.
- No local model training path is introduced.
- No GPU training dependency is introduced.
- No local large model is bundled.
- Redis and Vector DB remain optional external services or connectors.

## 12. Open Design Questions

- Whether memory cards should live under the Artifact Lifecycle, the Memory & Evidence Layer, or both.
- How users approve, reject, or revise generated memory cards.
- How contradiction and uncertainty should be displayed without overwhelming non-technical users.
- How much of the compiler should run synchronously versus as a background task.
- Which P2 Release Gate should own full regression for cross-document reasoning.
