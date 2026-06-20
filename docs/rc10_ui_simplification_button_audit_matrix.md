# rc10 UI Simplification Button Audit Matrix

Status: current gate working record.

Product baseline: `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`, `docs/product/PRD_V3_2026-06-19.md`, `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`.

| Page | Button / action | Runtime method | Real result | Decision |
| --- | --- | --- | --- | --- |
| Home | Open document library / generated docs / Agent workbench | page navigation | Opens real page | Keep as navigation only |
| Import & Parsing | Choose source | `pickAndImportFile`, `pickAndImportFolder`, `importWebLink` | Source records and files | Keep as primary |
| Import & Parsing | Parse / OCR / Chunking | `parseAndChunkSources` | Parse results and chunks | Keep as secondary, enabled after source import |
| Import & Parsing | Source-to-parse one click | `parseAndChunkSources` | Duplicate parse action | Remove |
| Document Library | Build KB from documents | page navigation to KB | Continues main chain | Keep as primary |
| Document Library | Re-parse / delete / standard package | runtime document operations | Real state changes | Move to more menu |
| Knowledge Base | Build / update KB | `buildKnowledgeBase` | KB and index records | Keep as primary |
| Knowledge Base | Select all / build from package / delete | KB operations | Real state changes | Move to more menu |
| Knowledge Base | Copy / merge / split / rebuild / compare / rollback | KB operations | Real KB records | Move to more menu |
| Retrieval & Verification | Query / validate / corrections | retrieval operations | Retrieval and validation records | Keep existing task controls |
| Document Generation | Generate Markdown | `generateMarkdown` | Markdown document | Keep as primary |
| Document Generation | Regenerate / export / delete history | generation operations | Real files or state changes | Move to more menu |
| Skill Factory | Validate Skill | `runSkillOperation('validate')` | Validation report | Keep |
| Skill Factory | Export Skill | `runSkillOperation('export')` | Export package | Keep |
| Skill Factory | Copy / fuse / bind / preview / delete | Skill operations | Real state changes | Move to more menu |
| Agent Workbench | Create Agent | `completeAgentProductOperations` | Agent workspace | Keep as primary in creation tab |
| Agent Workbench | Run chat | `runAgentDialogue` | Dialogue record | Keep as primary in chat area |
| Agent Workbench | Export dialogue | `exportAgentDialogue` | Dialogue export | Keep as secondary |
| Agent Workbench | Chat history / export preview / clear | Agent dialogue operations | Real files or state changes | Move to more menu |
| Agent Workbench | Start multi-Agent discussion | `runMultiAgentDiscussion` | A2A notes and reports | Keep as primary in A2A tab |
| Agent Workbench | Copy paths / view config / view session audit | preview or clipboard helpers | Developer-level artifact access | Remove from ordinary UI |
| Artifact Center | Open / export / delete selected artifact | artifact operations | Real files or state changes | Keep |
| Artifact Center | Copy artifact path | clipboard helper | Path-only utility | Remove from ordinary UI |
| Settings | Save / test provider and storage | settings operations | Real config and status | Keep |
| Settings | Provider evidence / runtime status enum | display only | Developer-level verification | Remove from ordinary UI |

