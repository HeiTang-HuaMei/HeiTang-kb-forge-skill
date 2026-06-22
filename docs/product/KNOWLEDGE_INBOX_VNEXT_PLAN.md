# Knowledge Inbox vNext Plan

Status: `vNext_planning_pending_owner_review`

This document plans a future HeiTang Knowledge Inbox. It absorbs the "collect -> organize -> consolidate -> network" loop into the Workbench product path without binding to a specific external toolchain.

## 1. Goal

Knowledge Inbox should let users collect scattered material and move it into the existing HeiTang flow:

```text
导入到知识收件箱
-> 自动识别来源类型
-> 自动打标签
-> 自动整理
-> 进入文档库
-> 生成知识库
-> 生成文档 / Skill / Agent
-> 来源与可信度检查
```

The inbox is not a separate product center. It is an intake layer before the document library.

## 2. Supported Source Planning

Planned source categories:

- Chat records.
- Code change records.
- Web links.
- Video notes.
- Documents.
- Speech-to-text transcripts.
- Obsidian Markdown.
- Notion exports.
- Feishu exports.
- WeChat exports.
- Manual evidence.

These are source types, not required platform dependencies.

## 3. User Path

1. User imports or drops material into Knowledge Inbox.
2. System identifies source type.
3. System suggests tags and workspace placement.
4. User confirms or adjusts.
5. System organizes the item into document library.
6. User selects material to build knowledge base.
7. User generates document, Skill, or Agent.
8. User checks source trace and confidence.
9. Artifact and usage records are written.

## 4. Data Model Direction

Knowledge Inbox items should eventually map to the semantic layer:

| Inbox field | Semantic layer target |
| --- | --- |
| Original file/link/text | `source` |
| Extracted content | `chunk` |
| Suggested tags | metadata tags |
| Evidence note | `manual evidence` or `evidence_map` |
| Source type | source metadata |
| Confidence hint | confidence metadata |
| Destination | workspace and document library state |

## 5. Product States

Inbox items should support plain user-facing states:

- 待整理.
- 已整理.
- 需要核对.
- 需要设置.
- 暂不可用.
- 已进入文档库.
- 已用于知识库.

Do not expose parser, embedding, provider, gateway, or runtime terms in the ordinary inbox UI.

## 6. Not In Scope

Knowledge Inbox vNext must not:

- Require Plaud.
- Require Obsidian.
- Require Weflow.
- Require Notion.
- Add platform account login.
- Add a complex sync center.
- Replace the document library.
- Create a new core runtime dependency.
- Claim external tools are runtime-ready without a separate integration gate.

## 7. Minimal vNext Candidate

The first viable inbox should be:

```text
local/manual intake -> source type detection -> tag suggestion -> document library handoff
```

It should reuse existing import, parse, document library, knowledge base, artifact, and usage-record capabilities.

## 8. Acceptance Direction

A future Knowledge Inbox implementation should pass:

- Real input import.
- Source type detection evidence.
- Document library handoff evidence.
- Knowledge base build from inbox-origin material.
- Source trace from output back to inbox source.
- Usage record from each operation.
- Config gate for unsupported or unconfigured sources.

If a source type cannot be processed, the product must say "需要设置" or "暂不可用" instead of showing success.
