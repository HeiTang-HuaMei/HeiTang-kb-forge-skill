# UI Information Architecture Restructure Plan

Generated: 2026-06-21

Gate: `ui_information_architecture_restructure_plan_gate`

Scope: plan only. This report does not change UI code, runtime behavior, artifact paths, tests, tags, or releases.

## 1. Inputs

- Product baseline:
  - `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
  - `docs/product/PRD_V3_2026-06-19.md`
  - `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`
- Current baseline pointer: `docs/current/CURRENT_PRODUCT_BASELINE.md`
- Real capability inventory: `docs/audits/current/ui_real_capability_and_structure_inventory_report.md`
- Current page registry: `web/workbench/flutter_app/lib/app/workbench_pages.dart`
- Current code map: `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md`
- Owner UI constraint: ordinary users must see a knowledge workflow product, not a developer control console.

## 2. Planning Principles

1. Show user tasks, not technical capability lists.
2. Each page has one primary action slot at most.
3. Primary action labels must use ordinary language.
4. Every retained button must map to a real runtime action, real artifact, real configuration change, or real view action.
5. Unconfigured capability states must not be displayed as usable actions.
6. Technical terms stay in advanced settings, usage records, or developer mode.
7. Audit, reports, and runtime evidence must not compete with the main task path.
8. Do not add tutorial strips, path explanation walls, or "next click here" cards. IA must carry the workflow.

## 3. Current State

Current user-facing page registry:

| Current page | Current ordinary exposure | Current issue |
| --- | --- | --- |
| Dashboard / 首页 | First-level | Acceptable first page, but must not become an all-capability launcher. |
| Workbook / 工作本管理 | First-level | Too technical for ordinary primary navigation; should become current workspace context. |
| Document Library / 文档库 | First-level | Correct layer, but import and parsing should read as one "我的资料" workflow. |
| Knowledge Base / 知识库 | First-level | Correct layer, but index/provider details must become status/config. |
| Retrieval & Verification / 检索与验证 | First-level | Real function, but ordinary label should be "测试知识库". |
| Document Generation / 文档生成 | First-level | Correct layer; nonconfigured export formats must remain unavailable. |
| Skill Factory / Skill 工厂 | First-level | Real function, but ordinary label should be "技能生成". |
| Agent Workbench / Agent 工作台 | First-level | Correct container; ordinary label should be "我的助手"; A2A stays inside. |
| Artifact Center / 产物中心 | First-level | Correct function; ordinary label should be "成果中心". |
| Governance & Audit / 治理与审计 | First-level | Should be weak entry as "使用记录"; developer wording only in developer mode. |
| Settings / 设置 | First-level | Should be weak entry; Provider/Gateway/ModelRoute details go under advanced settings. |

Current inventory confirms the real local chain exists:

```text
import -> parse/chunk -> KB build -> index -> retrieval -> Markdown -> Skill -> Agent -> multi-agent discussion -> artifacts -> audit
```

The IA problem is not missing pages. The problem is mixed action hierarchy, technical language, and too many primary-looking controls.

## 4. Target Navigation

### 4.1 Ordinary First-Level Navigation

| Target nav | Current source | Primary user task | Primary action slot |
| --- | --- | --- | --- |
| 首页 | Dashboard + current workbook summary | See current work and continue the next real task | State-driven: `添加资料`, `生成知识库`, `生成文档`, or `查看成果` |
| 我的资料 | Document Library + Import/Parsing | Add, organize, review source materials | State-driven: `添加资料` or `整理资料` |
| 我的知识库 | Knowledge Base + retrieval entry | Build and test knowledge bases | State-driven: `生成知识库` or `测试知识库` |
| 文档生成 | Document Generation | Generate and export documents from a KB | `生成文档` |
| 技能生成 | Skill Factory | Generate a Skill from a KB or localized template asset | `生成技能` |
| 我的助手 | Agent Workbench | Create, chat with, and coordinate assistants | State-driven: `创建助手`, `开始对话`, or `让多个助手一起讨论` |
| 成果中心 | Artifact Center | View and export generated outputs | State-driven: `查看成果` or `导出成果` |

### 4.2 Weak Entries

| Weak entry | Current source | Treatment |
| --- | --- | --- |
| 设置 | Settings | Top-right or bottom sidebar utility entry. Keep model service, local/pro mode, exporter, network, storage, Redis/vector details here. |
| 使用记录 | Governance & Audit + run histories | Weak utility entry. Ordinary label is usage records; developer mode may reveal audit details. |
| 帮助 | New/help surface only if already supported by static content | Do not create a tutorial flow in this gate; future execution may add minimal help entry only if backed by existing docs. |

### 4.3 Not First-Level

These must not appear as ordinary first-level navigation:

| Concept | Target placement |
| --- | --- |
| Standard package / OKF | More actions under `我的资料` and `我的知识库`; shown as standard package import/export, not a product module. |
| A2A | `我的助手` mode/action: `让多个助手一起讨论`. |
| Provider / Gateway / ModelRoute | `设置` -> advanced model service/provider settings. |
| Capability / operation / task gate concepts | Hidden from ordinary UI; developer mode or usage record only when needed. |
| Stage / campaign / release evidence | Usage records or docs, not product workflow pages. |

## 5. Page Action Model

Every page uses one visible primary action slot. Other actions are secondary, row-level, more-menu, settings, usage-record, or developer-only.

| Tier | Allowed use | UI pattern |
| --- | --- | --- |
| Primary | Current page's main user task and real action | One filled button or equivalent per page state |
| Secondary | Common next action after a real artifact exists | Outlined button or compact action near relevant artifact |
| Row action | Action on a specific material, KB, document, Skill, Agent, or artifact | Icon/menu in row |
| More menu | Low-frequency real actions such as copy, merge, rollback, delete, export variant | Menu with clear labels |
| Settings action | Saves/tests configuration, model service, provider, exporter, network, local/pro mode | Settings page only |
| Usage record | View evidence, history, audit, run records, reports | Usage records page or artifact details |
| Developer mode | Internal identifiers, gates, raw readiness, evidence matrices | Hidden by default |

## 6. Target Page Plans

### 6.1 首页

Purpose: current work status and next real task, not a capability launcher.

Keep:

- Current workspace/workbook name and health summary.
- Recent real tasks.
- Recent real outputs.
- Failure summary in ordinary language.
- One primary action slot based on missing prerequisite.

Remove/demote:

- All-capability grids.
- Gate/campaign/status matrix cards.
- Developer runtime evidence.
- Repeated direct links to every module.

Primary action state model:

| State | Primary label | Target |
| --- | --- | --- |
| No imported source | 添加资料 | 我的资料 |
| Imported but not organized | 整理资料 | 我的资料 |
| Organized but no KB | 生成知识库 | 我的知识库 |
| KB exists but no document | 生成文档 | 文档生成 |
| Outputs exist | 查看成果 | 成果中心 |

Validation target: home page shows no raw internal gate/campaign/core terms and has no more than one primary-looking action.

### 6.2 我的资料

Purpose: add and organize source materials.

Current sources:

- `document-library`
- `import-parsing`
- Document Library member route.

Primary action:

- `添加资料` if no source or user is in source-list context.
- `整理资料` if imported sources exist but parsing/chunking output is missing.

Secondary/row actions:

- Delete selected source.
- Clear imported source list.
- View parsed details.
- Re-run organization for a selected source.

More menu:

- Export/import standard package.
- Advanced parser/OCR options link to settings.

Copy rules:

- Use `整理资料`; do not expose parse/OCR/chunking as primary ordinary buttons.
- Show parser/OCR as status: `本地模式`, `需要设置`, `已连接`, `连接失败`.

Runtime mapping:

| User action | Runtime/action source | Artifact/effect |
| --- | --- | --- |
| 添加资料 | `pickAndImportFile`, `pickAndImportFolder`, `importFilePath`, `importFolderPath` | Imported files and `source_manifest.json` |
| 整理资料 | `parseAndChunkSources` | Parse report, chunks, document understanding manifest |
| 标准包导入/导出 | `importStandardKnowledgePackagePath`, `exportStandardKnowledgePackage` | Standard package files and audit |

### 6.3 我的知识库

Purpose: create, maintain, and test knowledge bases.

Current sources:

- `knowledge-package-management`
- `retrieval-verification` as a "test knowledge base" task.
- Index backend status from vector/provider settings.

Primary action:

- `生成知识库` when selected materials or standard package are available and KB is absent/stale.
- `测试知识库` when KB exists and the current mode is test/retrieval.

Secondary actions:

- Open KB detail.
- Go to document generation.
- Generate Skill from selected KB.
- Create assistant from selected KB.

More menu:

- Copy KB.
- Merge KB.
- Split KB.
- Compare versions.
- Roll back version.
- Delete KB.

Status:

- Index backend must read as `本地模式`, `专业模式`, `已连接`, `未配置`, or `连接失败`.
- Dimension mismatch and collection errors may appear only as user-readable failure states, not raw provider diagnostics.

Runtime mapping:

| User action | Runtime/action source | Artifact/effect |
| --- | --- | --- |
| 生成知识库 | `buildKnowledgeBase`, `buildKnowledgeBaseFromStandardPackage` | KB manifest, chunks/cards/QA/glossary, catalog, index artifacts |
| 测试知识库 | `searchKnowledgeBases`, `saveRetrievalValidationReport` | Query result, retrieval plan, validation report |
| KB version operations | KB CRUD/version runtime methods | Catalog, version, compare, rollback records |

### 6.4 文档生成

Purpose: generate and export documents from a knowledge base.

Primary action:

- `生成文档`.

Secondary actions:

- Reopen draft.
- Save edit.
- Export current Markdown document.

More menu:

- Regenerate.
- Delete latest record.
- Clear history.
- JSON/CSV export if available.

Configuration handling:

- Markdown remains default available when prerequisites exist.
- DOCX/PDF/PPTX must show `需要设置` or `暂不可用` until exporter config passes.
- Model service issues show `需要先配置模型服务`.

Copy rules:

- Ordinary user sees `生成文档` and `导出文档`.
- Do not make exporter/provider readiness a main page action.

Runtime mapping:

| User action | Runtime/action source | Artifact/effect |
| --- | --- | --- |
| 生成文档 | `generateMarkdown` | Markdown, reading notes, generation manifest |
| 导出文档 | `exportMarkdownDocument`, `exportDocumentFormat` | Exported document and export manifest |
| 保存编辑 | `saveEditedDocument` | Edited document and edit manifest |

### 6.5 技能生成

Purpose: generate usable Skills from knowledge assets.

Primary action:

- `生成技能`.

Secondary actions:

- Load draft.
- Save edit.
- Validate current Skill.
- Export Skill package.

More menu:

- Import/localize external template Skill.
- Copy Skill.
- Fuse Skills.
- Bind to assistant.
- View Skill content.
- Delete Skill artifact.

Copy rules:

- Ordinary label is `技能`, not raw `Skill` where feasible in Chinese UI.
- External template assets should not appear as Provider runtime.
- Validation/audit details go to usage records or details view.

Runtime mapping:

| User action | Runtime/action source | Artifact/effect |
| --- | --- | --- |
| 生成技能 | `generateSkill`, `completeSkillProductOperations` | Skill draft, config, validation, package manifest |
| 本地化模板技能 | `pickAndImportExternalSkill`, `importExternalSkillPath` | Localized Skill manifest, diff, localized draft |
| 技能操作 | `runSkillOperation`, `saveEditedSkill`, `clearSkillArtifacts` | Operation manifest/history, versions, diff, audit, export package |

### 6.6 我的助手

Purpose: create assistants, talk with assistants, and run multi-assistant collaboration.

Current source:

- `agent-factory-runtime`.

Primary action:

- `创建助手` if no assistant exists.
- `开始对话` if assistant exists and chat mode is active.
- `让多个助手一起讨论` inside collaboration mode when prerequisites exist.

Page structure:

- Mode/tabs: assistant overview, single assistant, multiple assistants, usage record.
- Do not expose A2A as first-level navigation.
- Do not show raw Agent package/audit as primary task.

Secondary actions:

- Export conversation.
- View conversation history.
- View discussion notes.

More menu:

- Clear conversation history.
- Delete assistant artifact.
- Advanced assistant settings.

Status:

- Model: `需要先配置模型服务`, `已连接`, `连接失败`, or `使用本地模式`.
- Memory: `本地模式`, `专业模式`, `已连接`, `未配置`.
- Tool access: ordinary labels only; unauthorized resources are not selectable.

Runtime mapping:

| User action | Runtime/action source | Artifact/effect |
| --- | --- | --- |
| 创建助手 | `generateAgent`, `completeAgentProductOperations` | Agent manifest/profile/config, permission audit |
| 开始对话 | `runAgentDialogue` | Dialogue markdown, chat history, traces, run history |
| 导出对话 | `exportAgentDialogue` | Exported dialogue and export manifest |
| 让多个助手一起讨论 | `runMultiAgentDiscussion` | Discussion report, session manifest, rounds, conflict/consensus records |

### 6.7 成果中心

Purpose: view and export outputs from the whole workflow.

Primary action:

- `查看成果` when browsing.
- `导出成果` when a single artifact or selected artifact set is active.

Secondary/row actions:

- Preview artifact.
- Export selected artifact.
- Delete selected recent artifact with confirmation.

Grouping:

- 文档
- 知识库
- 技能
- 助手
- 讨论报告
- 使用记录

Runtime mapping:

| User action | Runtime/action source | Artifact/effect |
| --- | --- | --- |
| 查看成果 | `readWorkspaceTextArtifact` | Artifact preview |
| 导出成果 | `exportWorkspaceArtifact` | Bounded exported copy |
| 清理成果 | `clearRecentTaskArtifacts` | Scoped artifact removal |

### 6.8 设置

Purpose: configure model service, local/pro mode, storage, exporters, network, and advanced providers.

Primary action:

- `设置模型服务` for the main settings surface.

Secondary actions:

- Save current configuration.
- Test current configuration.

Advanced sections:

- Provider/Gateway/ModelRoute.
- Redis/vector DB.
- Exporter config.
- Network authorization.
- Profile lifecycle.
- Tool and memory policy.

Demotion rules:

- Multiple profile/provider actions must not appear as a flat grid of primary buttons.
- Create/copy/switch/rollback/delete profile become row actions or more-menu actions.
- Test all provider capabilities becomes developer mode or advanced settings only.

Copy rules:

- Ordinary status: `本地模式`, `专业模式`, `已连接`, `未配置`, `连接失败`.
- Do not show raw provider readiness, runtime load, route binding, or schema labels in ordinary mode.

### 6.9 使用记录

Purpose: let users inspect what happened without turning records into the main workflow.

Current source:

- `reports-audit`
- Agent run history.
- Config/profile logs.
- Artifact and validation reports.

Primary action:

- None required unless exporting current record is the page's focused task.

Treatment:

- Ordinary label: `使用记录`.
- Developer label `审计` only when developer mode is active.
- Reports are grouped by action type: materials, knowledge base, document, Skill, assistant, settings, failures.

Demote/hide:

- Stage reports.
- Campaign labels.
- Raw matrix pages.
- Core operation details.
- External runtime debug details.

## 7. Button Audit Matrix

This matrix defines the first execution target. Execution must verify each retained action against real runtime/action evidence before deleting or hiding controls.

| Current area | Current button/label pattern | Target label | Tier | Runtime/effect | Handling |
| --- | --- | --- | --- | --- | --- |
| Dashboard | Multiple work entry buttons | State-driven ordinary task label | Primary slot only | Page navigation to next task | Keep one; demote other shortcuts |
| Workbook | 创建/切换工作本 | Current workspace selector | Weak/context | `createOrSwitchWorkbook` | Move out of first-level nav; preserve function in workspace context |
| Workbook | Delete/switch actions | More workspace actions | More menu | Workbook runtime state mutation | Keep guarded, not main user path |
| Document Import | Choose file/folder/source | 添加资料 | Primary/secondary depending state | Import methods | Keep, consolidate under 我的资料 |
| Document Import | Import web link | 添加链接 | Secondary/config-gated | `importWebLink` boundary | Show unavailable unless network authorization supports it |
| Document Library | Parse/OCR/chunking labels | 整理资料 | Primary state/row action | `parseAndChunkSources` | Rename and hide technical labels |
| Document Library | Standard package import/export | 标准包导入/导出 | More menu | OKF/standard package runtime | Keep as advanced package action |
| Knowledge Base | 构建/更新知识库 | 生成知识库 | Primary state | `buildKnowledgeBase` | Keep, ordinary label |
| Knowledge Base | Copy/merge/split/compare/rollback/delete | More KB actions | More menu | KB version/catalog methods | Keep as more/row actions |
| Retrieval | 运行真实检索 | 测试知识库 | Primary state | `searchKnowledgeBases` | Rename and decide whether page remains first-level or KB subtask |
| Retrieval | Save validation report | 保存测试记录 | Secondary | `saveRetrievalValidationReport` | Keep, not primary |
| Document Generation | 生成 Markdown | 生成文档 | Primary | `generateMarkdown` | Keep; Markdown detail can remain in status |
| Document Generation | Export Markdown | 导出文档 | Secondary/more | `exportMarkdownDocument` | Keep |
| Document Generation | DOCX/PDF/PPTX export | 导出文档 | Disabled/config-gated | `exportDocumentFormat` only after config | Show `需要设置`; not clickable until configured |
| Skill Factory | 生成 Skill | 生成技能 | Primary | `generateSkill` | Rename ordinary label |
| Skill Factory | Validate/export/copy/fuse/bind/view/delete | More Skill actions | More menu/secondary | `runSkillOperation` etc. | Keep but demote |
| External Skill | 导入并本地化 Skill | 导入模板技能 | More/secondary | External Skill localization | Keep as template asset action, not Provider |
| Agent Workbench | 创建 Agent | 创建助手 | Primary state | `generateAgent` | Rename ordinary label |
| Agent Chat | 运行对话 | 开始对话 | Primary state | `runAgentDialogue` | Keep |
| Agent Discussion | 启动联合讨论 / A2A | 让多个助手一起讨论 | Primary in collaboration mode | `runMultiAgentDiscussion` | Keep inside 我的助手, not first-level |
| Agent Export | 导出记录 | 导出对话 | Secondary/more | `exportAgentDialogue` | Keep, demote |
| Artifact Center | Preview/export/delete artifact | 查看成果 / 导出成果 | Primary plus row actions | Artifact read/export/delete | Keep |
| Audit | Export audit/report views | 查看使用记录 / 导出记录 | Weak/secondary | Audit/report artifacts | Demote to 使用记录 |
| Settings | Save/validate Provider config | 设置模型服务 / 测试连接 | Settings primary/secondary | Config persistence/test | Keep under settings |
| Settings | Test all/rollback provider capability | Advanced provider actions | Advanced/developer | Provider readiness/rollback | Hide from ordinary UI |
| Settings | Redis/Qdrant tests | 测试专业模式连接 | Advanced settings | Redis/vector tests | Keep config-gated; ordinary pages show status only |
| Settings | Profile CRUD | 配置方案 actions | Row/more | Profile lifecycle runtime | Keep in settings; no flat primary grid |

## 8. Terminology Replacement Map

| Technical/current term | Ordinary UI term |
| --- | --- |
| Document Library / 文档库 | 我的资料 |
| Knowledge Base / 知识库 | 我的知识库 |
| Retrieval / RAG validation | 测试知识库 |
| Skill Factory | 技能生成 |
| Agent Workbench | 我的助手 |
| Artifact Center / 产物中心 | 成果中心 |
| Governance & Audit | 使用记录 |
| Provider / Gateway / ModelRoute | 模型服务 / 高级设置 |
| Redis / Qdrant / Vector DB | 本地模式 / 专业模式 / 已连接 / 未配置 |
| Standard package / OKF | 标准知识包 / 标准包 |
| A2A | 多个助手一起讨论 |
| Parse / OCR / Chunking | 整理资料 |
| Build KB | 生成知识库 |
| Export boundary/readiness | 需要设置 / 暂不可用 / 可导出 |

## 9. Status Wording Rules

Use ordinary status:

| Runtime/config condition | User wording |
| --- | --- |
| Ready and usable | 可用 |
| Missing prerequisite source | 需要先添加资料 |
| Missing KB | 需要先生成知识库 |
| Missing model/provider config | 需要先配置模型服务 |
| Local fallback active | 使用本地模式 |
| External/pro service configured and tested | 已连接 |
| External/pro service missing | 未配置 |
| Connection/test failed | 连接失败 |
| Generated artifact present | 已生成 |
| Export possible | 可导出 |
| Config required before use | 需要设置 |
| Temporarily blocked | 暂不可用 |

Developer/internal status must not appear in ordinary UI. It may remain in tests, logs, or developer-mode evidence only.

## 10. UI Structure Execution Phases

Future gate: `ui_information_architecture_restructure_execution_gate`.

### Phase 1: Navigation and Naming

Goal: align first-level navigation and labels with ordinary user tasks.

Changes:

- Update `pages` titles/descriptions in `app/workbench_pages.dart`.
- Update sidebar grouping in `app/workbench_sidebar.dart`.
- Demote `工作本管理`, `治理与审计`, and `设置` from dominant workflow grouping.
- Rename user-facing pages:
  - 文档库 -> 我的资料
  - 知识库 -> 我的知识库
  - 检索与验证 -> either `测试知识库` first-level or KB subtask, depending implementation risk
  - Skill 工厂 -> 技能生成
  - Agent 工作台 -> 我的助手
  - 产物中心 -> 成果中心
  - 治理与审计 -> 使用记录

Validation:

- Widget tests confirm target nav labels.
- Forbidden first-level labels do not appear.
- Existing page keys stay stable where tests depend on them, or tests are updated intentionally.

### Phase 2: Primary Action Slot Per Page

Goal: one primary action slot per ordinary page.

Changes:

- Inventory all `_PrimaryProductAction` instances by page.
- Convert extra primary-looking actions to secondary buttons, row actions, or more menus.
- Preserve runtime calls and disabled states.
- Do not delete runtime methods.

Validation:

- Widget contract counts primary action widgets per visible page.
- Each retained action maps to runtime/effect in the Button Audit Matrix.

### Phase 3: Technical Term Hiding

Goal: remove developer-control-console language from ordinary UI.

Changes:

- Replace ordinary labels according to the terminology map.
- Move Provider/Gateway/ModelRoute detail into advanced settings.
- Move audit/report/evidence detail into usage records or developer mode.
- Keep raw terms only in code identifiers, logs, tests, advanced settings, or developer mode.

Validation:

- UI text scan for prohibited ordinary terms.
- Tests for no raw boundary/status strings in ordinary pages.

### Phase 4: Page-Level Simplification

Goal: make each page's main task visually dominant without restyling for its own sake.

Changes:

- 首页: single next-task action, recent task/artifact/failure summaries.
- 我的资料: merge import/parsing presentation; standard packages in more menu.
- 我的知识库: KB creation/testing, index as status.
- 文档生成: generate/export documents; exporter configuration as status and settings link.
- 技能生成: create Skill first; validation/export/fusion in secondary/more.
- 我的助手: create/chat/discuss modes; multiple-assistant discussion inside page.
- 成果中心: grouped outputs and export.
- 设置/使用记录: utility pages, not main workflow.

Validation:

- No tutorial/path instruction card added.
- Ordinary user path can be executed by following primary/secondary actions.
- Existing runtime tests still pass.

### Phase 5: Contract Tests and EXE Smoke

Goal: verify the restructured UI still drives real product capabilities.

Validation:

- `flutter analyze`
- Relevant widget tests for navigation, forbidden terms, and button hierarchy.
- `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1`
- Targeted runtime tests for import, KB, retrieval, generation, Skill, Agent, A2A, artifact, settings.
- Python UI contract/basic scan if available in repo scripts.
- `git diff --check`
- no-secret scan.
- overclaim scan.
- OKF boundary scan: no first-level OKF page or independent runtime claim.
- A2A boundary scan: no first-level A2A page; action remains inside assistant page.
- Windows EXE launch smoke after implementation if build scope includes EXE.

## 11. Risks and Guardrails

| Risk | Guardrail |
| --- | --- |
| Hiding real capability by over-demotion | Button Audit Matrix must map every retained/demoted action to runtime/effect before code changes. |
| Breaking existing tests by renaming labels | Preserve keys when possible; update widget tests only where product language intentionally changes. |
| Making Settings unusable by hiding too much | Keep model service and local/pro status visible; move only advanced internals under advanced sections. |
| Turning reports into product tasks | Usage records remain weak entry and details-only. |
| Claiming unconfigured capability is available | Config-gated capabilities show `需要设置`, `未配置`, or `暂不可用`; buttons disabled until test passes. |
| Changing runtime semantics during UI work | Execution gate must be behavior-preserving; runtime methods and artifact paths stay unchanged. |
| Reintroducing tutorial-based path fixes | Empty states may state missing prerequisite, but no step-by-step instruction walls. |

## 12. Required Execution Report

The future execution gate must output:

```text
docs/audits/current/ui_information_architecture_restructure_execution_report.md
```

Report must include:

1. Final navigation list.
2. Before/after page label map.
3. Button Audit Matrix with final handling.
4. Primary action count per page.
5. Hidden/demoted technical terms.
6. Settings/usage-record/developer-mode split.
7. Runtime methods preserved.
8. Tests updated.
9. analyze/test/build/scan results.
10. Remaining risks for Owner EXE review.

## 13. Entry Decision

The project is ready to enter `ui_information_architecture_restructure_execution_gate` after Owner accepts this plan.

Execution should start with navigation/naming and button hierarchy, not visual restyling. The first execution commit should be small enough to verify with widget tests before deeper page simplification.
