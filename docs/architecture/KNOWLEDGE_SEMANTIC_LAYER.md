# Knowledge Semantic Layer

Status: `vNext_planning_pending_owner_review`

This document plans a HeiTang-specific knowledge semantic layer. It is not a SQL DataAgent design and does not add implementation, dependencies, providers, gateways, or runtime-ready claims.

## 1. Purpose

The knowledge semantic layer maps user tasks into knowledge operations without binding the product to one storage or retrieval backend.

High-level mapping:

```text
用户自然语言任务
-> 知识语义层
-> 本地文件 / SQLite / 向量库 / Redis / 外部链接 / manual evidence
-> 结构化结果
-> 文档 / Skill / Agent / 检索答案 / 报告
```

## 2. Non-Goals

This plan does not:

- Implement SQL DataAgent.
- Add a SQL query assistant.
- Add Provider / Gateway / ModelRoute concepts.
- Add dependencies.
- Replace current retrieval runtime.
- Bind Workbench to a single vector database.
- Claim runtime readiness.

## 3. Source Types

Planned supported source types:

- PDF.
- DOCX.
- Markdown.
- TXT.
- CSV / TSV / XLSX.
- HTML / webpage.
- Chat record.
- Code.
- Image OCR.
- Audio transcript.
- Manual evidence.
- Obsidian Markdown.
- Notion / Feishu / WeChat exported content.

Source type is descriptive metadata. It must not force a specific external account system or sync provider.

## 4. Knowledge Units

The semantic layer should normalize knowledge into explicit units:

| Unit | Meaning |
| --- | --- |
| `source` | Original imported material or external reference. |
| `chunk` | Parse-time segment with source mapping. |
| `card` | Curated atomic knowledge note. |
| `qa_pair` | Question-answer pair generated or validated from evidence. |
| `source_trace` | Link from output back to source and location. |
| `evidence_map` | Structured relation between claim, source, confidence, and validation. |
| `validation_report` | Retrieval or external-check result with evidence. |
| `skill_template` | Skill structure generated from knowledge. |
| `agent_memory_entry` | Scoped Agent memory item. |
| `artifact` | Output file or product asset tracked by artifact center. |

## 5. Metadata

Every knowledge unit should carry metadata where available:

- Workspace ID.
- Source ID.
- Source type.
- Title.
- Author or origin.
- Created time.
- Imported time.
- Parsed time.
- Language.
- Tags.
- Hash.
- File path or external URL.
- Parser profile.
- Chunk index or location.
- Confidence score.
- Freshness / time validity.
- Permission scope.
- Lifecycle state.

## 6. Source Trace

Outputs must remain traceable:

```text
output claim -> evidence_map -> source_trace -> source/chunk/card -> original file or link
```

Source trace must support:

- Document generation citations.
- Retrieval evidence.
- Knowledge-base source inspection.
- Skill source inspection.
- Agent answer evidence.
- Audit and usage records.

## 7. Confidence

Confidence is a product-facing quality signal, not a fake certainty claim.

Inputs to confidence may include:

- Source type.
- Parse quality.
- Retrieval score.
- Evidence count.
- Source recency.
- User validation.
- External check availability.
- Conflict detection.

When confidence cannot be computed, the UI should show a plain state such as:

```text
需要核对
证据不足
本地证据
```

## 8. Freshness

Knowledge units should model time validity:

- Static.
- Recent.
- Expiring.
- Outdated.
- Unknown.

Freshness filtering must be available for tasks where time matters, especially reports, external checks, and Agent answers.

## 9. Permission Boundary

The semantic layer must preserve:

- Workspace filtering.
- Source permission.
- Network permission.
- External source gate.
- Agent memory scope.
- Multi-Agent collaboration task scope.
- Export permission.

No query path may silently cross workspace boundaries.

## 10. Lifecycle

Planned lifecycle states:

```text
imported
parsed
organized
indexed
validated
used_in_output
archived
deleted
```

Deletion and cleanup must preserve audit clarity without deleting user-owned original input files outside the workspace scope.

## 11. Query Paths

Supported query paths should include:

- Keyword retrieval.
- Vector retrieval.
- Rule filtering.
- Source backtrace.
- Time filtering.
- Confidence filtering.
- Permission filtering.
- Workspace filtering.
- Agent memory filtering.

The semantic layer should choose or combine query paths based on the user task and configured capabilities.

## 12. Output Targets

Planned output targets:

- Knowledge base.
- Markdown document.
- DOCX / PDF / PPTX export.
- Skill.
- Agent.
- Q&A.
- Validation report.
- Multi-Agent discussion report.
- Artifact center artifact.

Every output target must retain source trace and artifact metadata.

## 13. vNext Implementation Direction

Future implementation should start with the smallest viable semantic manifest:

```text
source
chunk
source_trace
evidence_map
artifact
```

Only after this works with real input, real retrieval, and real artifact trace should the project add card, qa_pair, richer confidence, or Agent memory enhancements.
