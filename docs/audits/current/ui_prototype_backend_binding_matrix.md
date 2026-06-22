# UI Prototype Backend Binding Matrix

Generated: 2026-06-22

Gate: `ui_prototype_backend_binding_execution_gate`

Scope: final binding matrix after UI implementation. This matrix maps Figma V0.2 frames to Flutter pages and real runtime capabilities, and records the implemented binding status verified by Flutter tests.

## 1. Inputs

- Figma file: `https://www.figma.com/design/FoFihaTUFUDQdNnOJUEGRA`
- Figma page: `V0.2 Visual Refined`
- Product baseline:
  - `docs/product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md`
  - `docs/product/PRD_V3_2026-06-19.md`
  - `docs/product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md`
- Runtime capability inventory:
  - `docs/audits/current/ui_real_capability_and_structure_inventory_report.md`
- Code map:
  - `docs/code_map/WORKBENCH_CODE_MAP_AFTER_CODE_CLEANUP.md`

## 2. Preflight Findings

| Check | Result |
| --- | --- |
| Branch | `feature/workbench-ui-prototype` |
| Current head | `b26a024 Add GitHub repository governance controls` |
| Figma page found | Yes: `V0.2 Visual Refined` |
| Figma frames found | 10 page frames plus `00 Component Library V0.2` |
| Required Flutter source files | Present |
| `ui_information_architecture_restructure_execution_report.md` | Missing; this gate treats previous IA execution as not completed and does not rely on that report |
| Existing unrelated dirty files | Preserved; do not rollback or commit unless explicitly included in this gate |

## 2.1 Implementation Closure

| Area | Result |
| --- | --- |
| Navigation labels | Bound to user-facing labels: 首页, 工作区, 文档库, 知识库, 测试知识库, 文档生成, 技能生成, 我的助手, 成果中心, 使用记录, 设置 |
| Primary task wording | Bound to ordinary actions: 添加资料, 整理资料, 生成知识库, 测试知识库, 生成文档, 生成技能, 创建助手, 开始对话, 多个助手讨论, 查看成果 |
| Runtime binding | Existing runtime method names and semantics preserved; UI labels route to existing runtime actions, artifacts, config saves, previews, or disabled/config-gated states |
| Config gating | DOCX/PDF/PPTX export, external link checking, model service, memory/search service, and advanced provider functions remain gated by existing runtime/config status |
| Ordinary UI terminology | Development terms demoted from ordinary navigation/buttons; remaining scan hits are code identifiers, tests, fixtures, logs, or internal status mapping branches |
| Verification | `flutter analyze`, `flutter test --concurrency=1`, `flutter test test\rc6_runtime_truth_blocker_repair_test.dart --concurrency=1`, and `git diff --check` passed |

## 3. Figma Frame To Flutter Page Mapping

| Figma Frame | Flutter Page Key | Current Flutter Source | Target User Label | Notes |
| --- | --- | --- | --- | --- |
| `01 首页 Visual V0.2` | `dashboard` | `features/dashboard/dashboard_product_workflow.dart` | 首页 | Show current workspace status, recent work, recent outputs, one next action. |
| `02 工作区 Visual V0.2` | `workbook` | `features/workbook/workbook_product_workflow.dart` | 工作区 | Workspace remains isolation container. It can be first-level in this prototype but must not become account/login. |
| `03 文档库 Visual V0.2` | `document-library` | `features/document_library/document_library_product_workflow.dart`, `features/import_parsing/import_product_workflow.dart` | 文档库 | User-facing task: add and organize materials. |
| `04 知识库 Visual V0.2` | `knowledge-package-management` | `features/knowledge_base/knowledge_base_product_workflow.dart` | 知识库 | User-facing task: build, test, and trace KB. |
| `05 检索与验证 Visual V0.2` | `retrieval-verification` | `features/retrieval/retrieval_verification_product_workflow.dart` | 测试知识库 | Frame label retained for traceability; ordinary page/action label uses `测试知识库`. |
| `06 文档生成 Visual V0.2` | `document-generation` | `features/document_generation/document_generation_product_workflow.dart` | 文档生成 | Primary action is `生成文档`; Markdown is implementation detail/status. |
| `07 Skill 工厂 Visual V0.2` | `skill-factory` | `features/skill/skill_builder_product_workflow.dart` | 技能生成 | Frame label retained for traceability; ordinary actions use `生成技能` and `导入模板技能`. |
| `08 Agent 工作台 Visual V0.2` | `agent-factory-runtime` | `features/agent/agent_product_workflow.dart` | 我的助手 | Multi-agent/A2A capability remains inside this page as `多个助手讨论`. |
| `09 产物中心 Visual V0.2` | `artifact-center` | `features/artifacts/artifact_center_product_workflow.dart` | 成果中心 | User-facing task: preview/export generated outputs. |
| `10 设置 Visual V0.2` | `workspace` | `features/settings/settings_product_workflow.dart` | 设置 | Ordinary sections first; Provider/Gateway/ModelRoute only in advanced settings. |
| `00 Component Library V0.2` | shared components | `shared/product_components.dart`, `app/workbench_shell.dart`, `app/workbench_sidebar.dart`, `app/product_top_bar.dart` | Component system | Reuse existing product components; no large widget duplication. |

## 4. Page Action Binding Matrix

| Figma Frame | UI Page Key | 用户动作 | 页面按钮/区域 | Runtime Method | Artifact/Effect | Config Gate | 状态文案 | 是否落地 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 01 首页 Visual V0.2 | `dashboard` | 添加资料 | 主按钮 / 继续任务 | Navigation to `document-library` | Opens material intake page | None | 需要先添加资料 | 已落地：首页下一步动作绑定文档库 |
| 01 首页 Visual V0.2 | `dashboard` | 整理资料 | 主按钮 when imported but not organized | Navigation to `document-library`; document page binds `parseAndChunkSources` | Parse/chunk artifacts after action | Local parser available; OCR optional | 待整理 / 使用本地模式 | 已落地：首页下一步动作和文档库整理动作绑定 |
| 01 首页 Visual V0.2 | `dashboard` | 生成知识库 | 主按钮 when organized docs exist and KB absent | Navigation to `knowledge-package-management` | KB build page | Requires organized source | 需要先整理资料 | 已落地：首页下一步动作绑定知识库页 |
| 01 首页 Visual V0.2 | `dashboard` | 生成文档 / 生成技能 | Main next action after KB exists | Navigation to `document-generation` or `skill-factory` | Opens generation task | Requires KB | 可用 | 已落地：生成入口绑定真实页面 |
| 01 首页 Visual V0.2 | `dashboard` | 创建助手 | Main next action after Skill/KB exists | Navigation to `agent-factory-runtime` | Opens assistant page | KB/Skill recommended | 可用 | 已落地：助手入口绑定真实页面 |
| 01 首页 Visual V0.2 | `dashboard` | 查看成果 | Main next action after artifacts exist | Navigation to `artifact-center` | Opens artifacts | Artifact present | 已生成 | 已落地：成果中心入口绑定真实页面 |
| 02 工作区 Visual V0.2 | `workbook` | 新建工作区 | 主按钮 / 工作区操作 | `createOrSwitchWorkbook` | Updates `workbooks/workbook_manifest.json` and active workspace state | Local workspace | 可用 | 已落地：现有 runtime 保持，UI 使用工作区文案 |
| 02 工作区 Visual V0.2 | `workbook` | 切换工作区 | 工作区列表 / action | `createOrSwitchWorkbook` | Switches active workspace | Local workspace | 已切换 | 已落地：现有 runtime 保持，UI 使用工作区文案 |
| 02 工作区 Visual V0.2 | `workbook` | 删除工作区 | More/danger action | `deleteWorkbook` | Removes workbook only if allowed | Cannot delete active/last protected workspace | 需要先切换 / 暂不可用 | Existing runtime; keep guarded |
| 02 工作区 Visual V0.2 | `workbook` | 验证隔离 | Status/report area | Runtime state plus tests | A/B workspace manifests and scoped artifacts | Local test workspace | 数据不互通 | 已验证：workbook persistence/deletion and asset index tests passed |
| 03 文档库 Visual V0.2 | `document-library` | 添加资料 | 主按钮 | `pickAndImportFile`, `pickAndImportFolder`, `importFilePath`, `importFolderPath` | Copied files, `source_manifest.json` | Desktop/local file access | 可用 | 已落地：添加与整理资料页绑定真实导入 runtime |
| 03 文档库 Visual V0.2 | `document-library` | 添加链接 | 次按钮/config-gated | `importWebLink` | Local link record/boundary artifact | Real crawl requires network authorization | 需要设置 / 暂不可用 | 已落地：网页导入保持配置/边界门控 |
| 03 文档库 Visual V0.2 | `document-library` | 整理资料 | 主/secondary state action | `parseAndChunkSources` | DU manifest, parse report, chunks seed artifacts | Local parser; OCR/provider optional | 待整理 / 已整理 / 使用本地模式 | Existing runtime; rename/hide technical terms |
| 03 文档库 Visual V0.2 | `document-library` | 删除资料 | Row/danger action | `deleteImportedSource` | Removes source record/file reference | Source selected | 已删除 | Existing runtime |
| 03 文档库 Visual V0.2 | `document-library` | 标准包导入 | More/advanced action | `importStandardKnowledgePackagePath` | Standard package records | Local package path | 可用 | Existing runtime; not OKF first-level |
| 03 文档库 Visual V0.2 | `document-library` | 标准包导出 | More/advanced action | `exportStandardKnowledgePackage` | Standard package manifest/content/audit | Organized material recommended | 可导出 | Existing runtime; not OKF first-level |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 生成知识库 | 主按钮 | `buildKnowledgeBase`, `buildKnowledgeBaseFromStandardPackage` | KB manifest, chunks/cards/QA/glossary, catalog, index artifacts | Requires source docs or package | 需要先添加资料 / 需要先整理资料 / 可用 | 已落地：知识库页绑定真实构建 runtime |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 测试知识库 | Secondary/detail action | `searchKnowledgeBases`, `saveRetrievalValidationReport` | Query result and validation report | Requires KB | 可用 | Existing runtime; may navigate to retrieval page |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 查看来源 | Detail/view action | `readWorkspaceTextArtifact` or source/KB manifest view | Opens source trace/manifest evidence | Requires KB/source artifact | 可查看 | 已落地：来源/质量/验证记录保持 artifact 预览绑定 |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 外部来源核对 | Config-gated action | Search provider path through retrieval/provider config | External validation report only when configured | Search provider/network authorization | 需要设置 / 未配置 / 已连接 | 已落地：未配置时显示设置/边界状态，不显示可用成功态 |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 更新知识库 | More action | `updateKnowledgeBaseIncremental` | Updated KB catalog/version | Existing KB | 可用 | Existing runtime |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 重建知识库 | More action | `rebuildKnowledgeBaseFull` | Rebuilt KB version/artifacts | Existing KB | 可用 | Existing runtime |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 复制知识库 | More action | `copyKnowledgeBase` | Copied KB catalog entry/artifacts | Existing KB | 可用 | Existing runtime |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 合并知识库 | More action | `mergeKnowledgeBases` | Merged KB catalog entry | Multiple KBs | 需要多个知识库 | Existing runtime |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 拆分知识库 | More action | `splitKnowledgeBase` | Split KB artifacts | Existing KB | 可用 | Existing runtime |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 版本对比 | More action | `compareKnowledgeBaseVersions` | Compare report | Multiple versions | 可用 / 暂不可用 | Existing runtime |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 回滚版本 | More action | `rollbackKnowledgeBaseVersion` | Rollback records | Previous version | 可用 / 暂不可用 | Existing runtime |
| 04 知识库 Visual V0.2 | `knowledge-package-management` | 删除知识库 | More/danger action | `deleteKnowledgeBaseRecord` | Removes KB catalog record | Existing KB | 已删除 | Existing runtime, keep guarded |
| 05 检索与验证 Visual V0.2 | `retrieval-verification` | 查询 / 测试知识库 | 主按钮 | `searchKnowledgeBases` | Query result, citation/source evidence | Requires KB | 需要先生成知识库 / 可用 | Existing runtime; rename ordinary action |
| 05 检索与验证 Visual V0.2 | `retrieval-verification` | 保存测试记录 | Secondary action | `saveRetrievalValidationReport` | Validation report md/json/history | Query result exists | 可保存 | Existing runtime |
| 05 检索与验证 Visual V0.2 | `retrieval-verification` | 查看证据 | View action | `readWorkspaceTextArtifact` or existing preview | Opens query/citation/source trace artifact | Query result exists | 可查看 | 已落地：测试知识库页展示证据选择和引用来源 |
| 05 检索与验证 Visual V0.2 | `retrieval-verification` | 外部交叉验证 | Config-gated action | External search/provider path | External validation artifact only after config | Search provider/network authorization | 需要设置 / 未配置 / 已连接 | 已落地：外部核对保持配置门控 |
| 06 文档生成 Visual V0.2 | `document-generation` | 生成文档 | 主按钮 | `generateMarkdown` | Markdown, reading notes, generation manifest | Requires KB | 需要先生成知识库 / 可用 | Existing runtime; rename from Markdown |
| 06 文档生成 Visual V0.2 | `document-generation` | 保存草稿 / 保存编辑 | Secondary action | `saveEditedDocument` | Edited markdown and edit manifest | Generated/open draft | 可保存 | Existing runtime |
| 06 文档生成 Visual V0.2 | `document-generation` | 导出 Markdown | Export action | `exportMarkdownDocument` | Markdown export and manifest | Generated markdown | 可导出 | Existing runtime |
| 06 文档生成 Visual V0.2 | `document-generation` | 导出 Word/PDF/PPT/表格 | Export action/config-gated | `exportDocumentFormat` | Exported format or structured export manifest | Exporter config for DOCX/PDF/PPTX; structured artifact for JSON/CSV | 需要设置 / 暂不可用 / 可导出 | Existing runtime; must gate UI |
| 06 文档生成 Visual V0.2 | `document-generation` | 读取历史 | View action | `readLatestDocumentGenerationHistoryMarkdown` | Loads generation history markdown | History exists | 可查看 | Existing runtime |
| 06 文档生成 Visual V0.2 | `document-generation` | 删除最新记录 | More/danger action | `deleteLatestDocumentGenerationHistory` | Mutates generation history | History exists | 已删除 | Existing runtime |
| 06 文档生成 Visual V0.2 | `document-generation` | 清空历史 | More/danger action | `clearDocumentGenerationHistory` | Clears history | History exists | 已清空 | Existing runtime |
| 07 Skill 工厂 Visual V0.2 | `skill-factory` | 生成技能 | 主按钮 | `generateSkill`, `completeSkillProductOperations` | `SKILL.md`, config, verification, package manifest | Requires KB; model optional/configurable | 需要先生成知识库 / 可用 | Existing runtime; ordinary label can be `生成技能` |
| 07 Skill 工厂 Visual V0.2 | `skill-factory` | 导入外部 Skill 并专属化 | Secondary action | `pickAndImportExternalSkill`, `importExternalSkillPath` | Localized Skill manifest/diff/draft | Local file source; template asset, not Provider runtime | 可用 | Existing runtime; label as template/import skill |
| 07 Skill 工厂 Visual V0.2 | `skill-factory` | 检查 Skill | Secondary action | `runSkillOperation('validate')` | Validation report/operation history | Existing Skill | 可检查 | Existing runtime |
| 07 Skill 工厂 Visual V0.2 | `skill-factory` | 保存技能编辑 | Secondary action | `saveEditedSkill` | Edited Skill markdown | Draft loaded | 可保存 | Existing runtime |
| 07 Skill 工厂 Visual V0.2 | `skill-factory` | 导出 Skill | Secondary/export action | `runSkillOperation('export')` | Skill export package | Existing Skill | 可导出 | Existing runtime |
| 07 Skill 工厂 Visual V0.2 | `skill-factory` | 绑定助手 | Secondary action | `runSkillOperation('bind_agent')` | Binding manifest | Existing Skill and Agent/workspace | 需要先创建助手 / 可用 | Existing runtime |
| 07 Skill 工厂 Visual V0.2 | `skill-factory` | 复制/融合/删除 Skill | More/danger actions | `runSkillOperation('copy')`, `runSkillOperation('fusion')`, `clearSkillArtifacts` | Operation history, versions, deletion | Existing Skill | 可用 | Existing runtime; demote |
| 08 Agent 工作台 Visual V0.2 | `agent-factory-runtime` | 创建助手 | 主按钮 | `generateAgent`, `completeAgentProductOperations` | Agent manifest/profile/config/permission audit | KB/Skill recommended; model optional | 需要先生成知识库 / 可用 | Existing runtime; ordinary label |
| 08 Agent 工作台 Visual V0.2 | `agent-factory-runtime` | 开始对话 | Main/secondary in single assistant mode | `runAgentDialogue` | Dialogue markdown/jsonl/traces/run history | Existing Agent | 可用 | Existing runtime |
| 08 Agent 工作台 Visual V0.2 | `agent-factory-runtime` | 清空对话 | More/danger action | `clearAgentDialogueHistory` | Clears local dialogue history | History exists | 已清空 | Existing runtime |
| 08 Agent 工作台 Visual V0.2 | `agent-factory-runtime` | 导出对话 | Secondary/export action | `exportAgentDialogue` | Dialogue export markdown/manifest | Dialogue history exists | 可导出 | Existing runtime |
| 08 Agent 工作台 Visual V0.2 | `agent-factory-runtime` | 多 Agent 协作 / 多个助手一起讨论 | Main action in collaboration mode | `runMultiAgentDiscussion` | Discussion report, session manifest, rounds, audit, conflict/consensus | Existing Agent/Skill/KB; provider optional | 可用 / 需要先创建助手 | Existing runtime; not first-level A2A |
| 08 Agent 工作台 Visual V0.2 | `agent-factory-runtime` | 查看讨论报告 | View action | `readWorkspaceTextArtifact` on discussion artifact | Opens multi-agent discussion report | Discussion exists | 可查看 | Existing artifact view |
| 09 产物中心 Visual V0.2 | `artifact-center` | 查看成果 / 预览 | Main/view action | `readWorkspaceTextArtifact` | Artifact preview | Artifact present | 可查看 | Existing runtime |
| 09 产物中心 Visual V0.2 | `artifact-center` | 导出成果 | Export action | `exportWorkspaceArtifact` | Bounded exported artifact copy/manifest | Artifact selected | 可导出 | Existing runtime |
| 09 产物中心 Visual V0.2 | `artifact-center` | 删除最近任务产物 | More/danger action | `clearRecentTaskArtifacts` | Scoped artifact cleanup | Artifact/task selected | 已删除 | Existing runtime |
| 09 产物中心 Visual V0.2 | `artifact-center` | 打开相关助手/文档/知识库 | Navigation/view action | Page navigation using artifact metadata | Opens related page | Artifact metadata exists | 可打开 | 已落地：artifact metadata 不足时保持查看/导出/删除成果，不伪造跳转成功 |
| 10 设置 Visual V0.2 | `workspace` | 语言与外观 | Preference controls | Existing local UI state or profile setting if available | UI preference change | None/profile persistence if available | 已设置 | 已落地：使用现有 UI state/profile 能力，不伪造额外持久化 |
| 10 设置 Visual V0.2 | `workspace` | 模型服务连接 | Settings action | `saveModelGatewayProviderConfig`, `testModelGatewayProvider` | Model gateway config/evidence, masked secrets | Endpoint/model/API key ref required | 需要设置 / 已连接 / 连接失败 | Existing runtime |
| 10 设置 Visual V0.2 | `workspace` | 本地存储 | Settings action | Workspace/storage profile methods; `saveStorageProviderSettings` where applicable | Storage config/status | Local path writable | 可用 / 路径不可写 | Existing runtime/config |
| 10 设置 Visual V0.2 | `workspace` | 导出工具 | Settings action | `saveExporterSettings`, `validateExporterSettings` | Exporter settings and validation report | Exporter config for Office formats | 需要设置 / 已连接 / 连接失败 | Existing runtime |
| 10 设置 Visual V0.2 | `workspace` | 内存与缓存 | Advanced settings action | `testRedisConnection`, `testQdrantConnection` | Redis/Qdrant test result logs | Redis/Qdrant endpoint/secrets/dimension | 使用本地模式 / 需要设置 / 已连接 / 连接失败 | Existing runtime; ordinary copy hides raw terms |
| 10 设置 Visual V0.2 | `workspace` | 安全与合规 | Settings/status view | Existing config/profile/security settings | Network/auth/security status | Depends on profile | 已配置 / 需要设置 | Existing settings surface |
| 10 设置 Visual V0.2 | `workspace` | Profile 生命周期 | Advanced settings | `createProjectConfigProfile`, `copyProjectConfigProfile`, `activateProjectConfigProfile`, `rollbackProjectConfigProfile`, `deleteProjectConfigProfile`, `testProjectConfigProfile` | Profile JSON, activation/test logs | At least one profile; active/last protected | 可用 / 暂不可用 | Existing runtime; advanced only |
| 10 设置 Visual V0.2 | `workspace` | Provider 能力 | Advanced/developer settings | `syncRegisteredProviderCapabilities`, `testAllRegisteredProviderCapabilities`, `activateRegisteredProviderCapability`, `rollbackRegisteredProviderCapability` | Readiness/user catalog/lifecycle audit | Provider config/evidence | 需要设置 / 已连接 / 连接失败 | Existing runtime; not ordinary primary |

## 5. State Binding Matrix

| UI State | Runtime/Config Condition | User Wording | Ordinary UI Rule |
| --- | --- | --- | --- |
| No imported source | `!runtime.hasImportedFile` and source manifest absent/empty | 需要先添加资料 | Only show material intake as primary next action. |
| Imported source not organized | Source exists, parse/chunk artifacts absent/stale | 待整理 | Show `整理资料`, not Parse/OCR/Chunking. |
| Organized source exists | Parse report/chunks exist | 已整理 | Enable KB generation. |
| No KB | `!runtime.hasKnowledgeBase` | 需要先生成知识库 | Disable retrieval/document/Skill/Agent actions that require KB. |
| KB exists | KB manifest/catalog exists | 可用 | Enable testing/generation downstream actions. |
| External search unavailable | Search provider/network not configured | 外部链接核对：需要设置 | Do not show external validation as usable. |
| Markdown generated | Markdown artifact exists | 已生成 / 可导出 | Enable Markdown export. |
| Office exporter missing | Exporter config not validated | 需要设置 / 暂不可用 | DOCX/PDF/PPTX buttons disabled or settings-linked. |
| Model service missing | Model gateway/provider config missing or test failed | 需要先配置模型服务 / 连接失败 | Do not show model-dependent action as guaranteed. |
| Skill absent | Skill manifest absent | 需要先生成技能 | Disable validate/export/bind operations. |
| Agent absent | Agent manifest absent | 需要先创建助手 | Disable chat/discussion/export conversation. |
| Redis unavailable | Redis config/test failed | 使用本地模式 / 需要设置 | Agent memory falls back local; no raw Redis in ordinary page. |
| Vector DB unavailable | Vector config/test failed | 使用本地模式 / 需要设置 | KB local index remains available; no raw Qdrant/vector wording in ordinary page. |
| Artifact absent | Artifact list empty | 暂无成果 | Disable artifact preview/export/delete. |
| Runtime boundary/failure | Runtime reports raw failure such as desktop requirement | 暂不可用 / 需要设置 | Never expose raw failure token in ordinary UI. |

## 6. Workspace Isolation Binding

| Boundary | Expected Binding | Runtime Evidence Target | UI Treatment |
| --- | --- | --- | --- |
| Document library isolation | Active workspace controls source manifest and imported files | Workbook manifest/source records scoped to active workspace | Show current workspace; do not cross-list other workspace files. |
| Knowledge base isolation | Active workspace controls KB catalog and artifacts | KB catalog/scoped artifacts | Show only current workspace KBs by default. |
| Skill isolation | Active workspace controls Skill artifacts and binding | Skill manifest/binding records | Show only current workspace Skills by default. |
| Agent isolation | Active workspace controls Agent workspace and permissions | Agent manifest/permission audit | Show only current workspace assistants by default. |
| Single assistant memory | Agent dialogue history stored under current Agent/workspace | `agent/dialogue/chat_history.jsonl`, run history | Show as current assistant conversation only. |
| Multi-agent collaboration memory | Collaboration session belongs to current workspace/task | A2A/session manifest/round logs/report | Show only in current workspace discussion record. |

## 7. Hidden Or Demoted Technical Terms

These terms must not be ordinary main navigation or primary buttons. They may remain in code identifiers, tests, logs, advanced settings, usage-record details, or developer mode.

| Term | Ordinary Treatment |
| --- | --- |
| Provider / Gateway / ModelRoute | `模型服务` or advanced settings |
| Redis / Qdrant / Vector DB | `记忆服务`, `专业模式`, `本地模式`, advanced settings |
| Embedding / dimension mismatch / index_profile | KB advanced details or settings diagnostics |
| Parse / OCR / Chunking / Parser | `整理资料`; OCR as optional status/settings |
| OKF | `标准知识包`; more action only |
| A2A | `多个助手一起讨论`; inside Agent page only |
| runtime_ready / disabled_boundary / desktop_runtime_required | User-readable status only |
| Gate / Campaign / Stage / Capability Matrix / Operation Gate / Task Job Center | Hidden from ordinary UI |

## 8. Implementation Order

1. Align page registry/sidebar/topbar labels and route mapping.
2. Align shared component tokens/buttons/cards/status chips without duplicating widget systems.
3. Implement page-by-page action labels and config gates from this matrix.
4. Add/update widget tests for navigation labels, forbidden terms, primary action count, and config gates.
5. Add/update runtime tests for workspace and Agent/multi-agent isolation where existing evidence is insufficient.
6. Finalize `ui_prototype_backend_binding_execution_report.md`.
