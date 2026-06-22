# UI Current Screenshot Review And Wireframe Plan

Generated: 2026-06-21

Scope: screenshot-based UI review and wireframe plan only. No UI code, runtime code, product behavior, tag, release, or commit was changed.

## 1. Screenshot Evidence

Current UI was captured from the existing Flutter web build served locally from:

```text
web/workbench/flutter_app/build/web
```

Screenshot output directory:

```text
web/workbench/flutter_app/output/ui_current_screenshots/
```

Captured pages:

| Page | Screenshot |
| --- | --- |
| 首页 | `web/workbench/flutter_app/output/ui_current_screenshots/01_home.png` |
| 工作本管理 | `web/workbench/flutter_app/output/ui_current_screenshots/02_workbook.png` |
| 文档库 / 我的资料 | `web/workbench/flutter_app/output/ui_current_screenshots/03_document_library.png` |
| 知识库 / 我的知识库 | `web/workbench/flutter_app/output/ui_current_screenshots/04_knowledge_base.png` |
| 检索验证 / 测试知识库 | `web/workbench/flutter_app/output/ui_current_screenshots/05_retrieval.png` |
| 文档生成 | `web/workbench/flutter_app/output/ui_current_screenshots/06_document_generation.png` |
| 技能生成 | `web/workbench/flutter_app/output/ui_current_screenshots/07_skill.png` |
| 我的助手 / Agent | `web/workbench/flutter_app/output/ui_current_screenshots/08_agent.png` |
| 成果中心 | `web/workbench/flutter_app/output/ui_current_screenshots/09_artifacts.png` |
| 使用记录 / 审计 | `web/workbench/flutter_app/output/ui_current_screenshots/10_usage_records.png` |
| 设置 | `web/workbench/flutter_app/output/ui_current_screenshots/11_settings.png` |

Capture notes:

- `flutter run -d web-server` could not start because `web/index.html` uses `<base href="./">`.
- `flutter build web --base-href /` could not rebuild because `web/index.html` does not use `$FLUTTER_BASE_HREF`.
- Existing `build/web` output was served through a local static server and captured with Microsoft Edge via Playwright.
- Flutter Web text is rendered through Canvas and was not exposed as DOM text, so page switching used fixed sidebar coordinates from the visible UI.

## 2. Current UI Findings

### 2.1 Overall

The UI already has a clean black/white/gray direction and avoids a strong brand-purple palette. The main issue is information architecture, not basic visual polish.

Observed problems:

1. First-level navigation still reflects engineering/product layers: `工作本管理`, `文档库`, `知识库`, `检索与验证`, `Skill 工厂`, `Agent 工作台`, `产物中心`, `治理与审计`, `设置`.
2. Ordinary user vocabulary is mixed with technical vocabulary: `OCR`, `Chunking`, `向量索引`, `LLM 增强`, `Embedding`, `Provider`, `Redis`, `向量库`, `Agent`, `A2A`, `审计`.
3. Several pages have tab-like module switches that behave like capability lists rather than user task paths.
4. Some pages already obey one main action visually, but page-level action hierarchy is inconsistent.
5. Usage records and settings still expose developer/industrial wording that should be weak or advanced-only.
6. A2A is currently inside Agent Workbench, which is architecturally correct, but the visible label should become `多个助手一起讨论`.
7. OKF is not first-level, which is correct. It should remain under standard package actions in materials/knowledge-base flows.

## 3. Page-Level Review

### 3.1 首页

Current strengths:

- Clear dashboard and status overview.
- No obvious raw gate/campaign matrix on the first viewport.
- Black/white/gray visual style is close to target.

Problems:

- `工作入口` lists multiple module entry cards, making the home page feel like a console launcher.
- `知识供应链进度` uses product-internal chain language and table density.
- The next action is not singular enough for an ordinary user.

Target:

- Show current work, recent real tasks, recent outputs, failures, and one state-driven primary button.
- Use primary button labels only from ordinary user actions: `添加资料`, `整理资料`, `生成知识库`, `生成文档`, `查看成果`.

### 3.2 工作本管理

Current strengths:

- Shows workspace isolation and continuation state.

Problems:

- Should not be first-level for ordinary users.
- `工作本`, `资产承接`, and stage table language is more operational than user-facing.

Target:

- Fold into home/workspace context.
- Keep advanced workspace switching in Settings or a small current-work selector.
- Do not keep `工作本管理` as primary navigation.

### 3.3 文档库

Current strengths:

- The page already groups import and organization.
- The primary action area is visible.

Problems:

- Page title should become `我的资料`.
- `导入与解析`, `解析/OCR/Chunking`, `Parser`, `OCR` are too technical for ordinary mode.
- `Web 预览模式` reads like an implementation state.

Target:

- Ordinary task: `添加资料` then `整理资料`.
- Technical parsing/OCR details become statuses or advanced settings.
- Standard package/OKF stays in more actions.

### 3.4 知识库

Current strengths:

- Represents source selection, KB type, local index, quality records, and build artifacts.
- One disabled main build action is visible.

Problems:

- Page title should become `我的知识库`.
- `向量索引`, `LLM 增强`, `Embedding`, `向量库` should not be visible as ordinary page controls.
- Tabs `向量索引 / 质量记录 / 存储边界` expose internal layers.

Target:

- Primary task: `生成知识库`.
- Secondary task: `测试知识库`.
- Index/vector/model details shown as `本地模式`, `专业模式`, `已连接`, `未配置`, `连接失败`.
- Advanced index details move to Settings or details panel.

### 3.5 检索与验证

Current strengths:

- Real test workflow exists: query, evidence selection, score, correction, validation.
- It can support external source checking after configuration.

Problems:

- `检索与验证` is not the best ordinary label.
- The page shows too many technical stages: query rewrite, retrieval plan, rerank, evidence verification.
- The visible failure reason `desktop_runtime_required` is not ordinary-language UI.

Target:

- Ordinary task label: `测试知识库`.
- Page can stay as a main page only if product keeps testing as a distinct workflow; otherwise it becomes a section inside `我的知识库`.
- Button labels: `测试知识库`, `保存测试记录`.
- External checks appear as `外部链接核对：需要设置 / 已连接 / 连接失败`.

### 3.6 文档生成

Current strengths:

- Clear generation task area.
- Export formats show unavailable status instead of fake availability.

Problems:

- Primary button currently says `生成 Markdown`; ordinary label should be `生成文档`.
- `输出格式`, `验证与导出`, `脱敏检查`, `导出边界` are denser than necessary for first-use.
- DOCX/PDF/PPTX status is correct conceptually but should read as ordinary availability.

Target:

- Primary action: `生成文档`.
- Secondary action: `导出文档`.
- Format cards show `可导出`, `需要设置`, or `暂不可用`.
- Advanced validation details move to document details or usage records.

### 3.7 Skill 工厂

Current strengths:

- Real Skill generation, external localization, version operation, validation/export flows exist.

Problems:

- Title should become `技能生成`.
- `Skill 工厂`, `外部本地化`, `版本操作`, `验证导出`, `治理报告` are too technical as top visible tabs.
- Too many chips and configuration fields appear before the user's main action.

Target:

- Primary action: `生成技能`.
- Secondary actions: `导入模板技能`, `验证技能`, `导出技能`.
- Copy/fuse/bind/delete/view become more-menu actions.
- Template assets must not look like runtime Providers.

### 3.8 Agent 工作台

Current strengths:

- A2A is inside Agent Workbench, not first-level.
- Create, single-agent chat, multi-agent discussion, and run audit are in one place.

Problems:

- Title should become `我的助手`.
- Visible labels `Agent`, `单 Agent`, `多 Agent / A2A`, `运行审计`, `Redis`, `向量长期记忆` are technical.
- Main action `创建 Agent 工作区并进入对话` should be simplified.

Target:

- Primary state actions:
  - `创建助手`
  - `开始对话`
  - `让多个助手一起讨论`
- Modes:
  - 我的助手
  - 对话
  - 多个助手讨论
  - 使用记录
- Redis/vector/tool policy shown as memory/model/tool statuses only in advanced areas.

### 3.9 产物中心

Current strengths:

- Correct role as output browser.
- Good candidate for final workflow destination.

Problems:

- Title should become `成果中心`.
- Category labels still include technical artifacts: `chunks`, `Skill`, `Agent`.
- Primary action is unclear when no artifact exists.

Target:

- Group outputs as:
  - 文档
  - 知识库
  - 技能
  - 助手
  - 讨论报告
  - 使用记录
- Primary action when artifact exists: `导出成果`.
- Empty state uses prerequisite wording, not technical artifact names.

### 3.10 治理与审计

Current strengths:

- Real usage/audit records are present.

Problems:

- Must not be first-level as `治理与审计` for ordinary users.
- Shows `blocked` and `desktop_runtime_required`, which violates ordinary status wording.
- Filter chips expose internal modules.

Target:

- Rename to `使用记录`.
- Use ordinary modules: 资料、知识库、文档、技能、助手、设置、失败.
- Developer audit details only in developer mode.
- Replace raw failure states with `暂不可用`, `需要设置`, `连接失败`, or a Chinese failure reason.

### 3.11 设置

Current strengths:

- Settings is already separated from main workflow.
- Local-first status is visible.

Problems:

- Top tabs expose `Provider / 模型`, `Redis / 向量库`.
- Settings first viewport still reads as engineering configuration.
- Some English technical assets appear in ordinary mode: `Provider`, `Redis`, `Agent Creation`, `Knowledge Base`.

Target:

- Main ordinary settings:
  - `模型服务`
  - `本地/专业模式`
  - `导出设置`
  - `网络权限`
  - `存储位置`
- Advanced settings:
  - Provider/Gateway/ModelRoute
  - Redis/vector DB
  - Profile lifecycle
  - Developer diagnostics

## 4. Corrected User Flow Wireframe

The next UI architecture should follow this workflow:

```text
原始资料
→ 我的资料
→ 从资料中选择内容
→ 生成知识库
→ 测试知识库
→ 检验 / 溯源 / 外部链接核对
→ 生成文档 / 生成技能
→ 创建助手
→ 多知识库 / 多技能 / 专属记忆 / 多助手协作
→ 成果中心
```

Important ordering:

- `生成技能` and `创建助手` should not visually compete with `添加资料 -> 生成知识库 -> 测试知识库`.
- `多个助手一起讨论` appears only after assistant capability exists.
- `外部链接核对` appears only when network/model/search configuration allows it.
- OKF/standard package appears only as standard package import/export under materials/KB actions.

## 5. Low-Fidelity Layout Target

### 5.1 Shell

```text
┌──────────────────────────────────────────────────────────────┐
│ 黑糖知识工作台         搜索资料 / 知识库 / 成果        设置 │
├───────────────┬──────────────────────────────────────────────┤
│ 首页          │ Page title                                   │
│ 我的资料      │ One-line page purpose                         │
│ 我的知识库    │                                              │
│ 文档生成      │ [Primary action]                              │
│ 技能生成      │                                              │
│ 我的助手      │ Main content: task-first, status-second        │
│ 成果中心      │                                              │
│               │                                              │
│ 使用记录      │ Secondary / more / row actions only            │
│ 设置          │                                              │
└───────────────┴──────────────────────────────────────────────┘
```

### 5.2 首页

```text
首页
当前工作：默认工作区               状态：使用本地模式

[添加资料]  ← only one primary action based on current state

最近任务
- 暂无任务 / 最近一次真实任务

最近成果
- 文档 / 知识库 / 技能 / 助手 / 讨论报告

需要处理
- 需要先添加资料
- 模型服务未配置
```

### 5.3 我的资料

```text
我的资料
添加、整理并管理你的资料。

[添加资料]

资料列表
文件名 | 类型 | 状态 | 操作

整理状态
本地模式：可用
图片文字识别：需要设置
网页导入：需要设置

更多：标准包导入 / 标准包导出 / 高级整理设置
```

### 5.4 我的知识库

```text
我的知识库
把资料变成可以查询和使用的知识库。

[生成知识库]

知识库列表
名称 | 来源资料 | 状态 | 最近测试 | 操作

知识库详情
内容数量 / 来源 / 本地模式 / 质量状态

次操作：测试知识库 / 生成文档 / 生成技能 / 创建助手
更多：复制 / 合并 / 版本 / 删除 / 标准包
```

### 5.5 测试知识库

This can be either a first-level page or a subview inside `我的知识库`. If kept first-level, use ordinary wording.

```text
测试知识库
输入问题，检查答案是否能追溯到资料来源。

[测试知识库]

问题输入
证据结果
引用来源
外部链接核对：需要设置 / 已连接 / 连接失败

次操作：保存测试记录
```

### 5.6 文档生成

```text
文档生成
选择知识库和模板，生成可导出的文档。

[生成文档]

选择知识库
选择文档类型
正文编辑

导出
Markdown：可导出
DOCX：需要设置
PDF/PPTX：需要设置
JSON/CSV：可导出
```

### 5.7 技能生成

```text
技能生成
把知识库中的方法和规则变成可复用技能。

[生成技能]

来源知识库
技能类型
输出目标

技能草稿

次操作：验证技能 / 导出技能
更多：导入模板技能 / 融合技能 / 绑定助手 / 删除
```

### 5.8 我的助手

```text
我的助手
创建助手，并让助手使用你的知识库和技能完成工作。

[创建助手] or [开始对话] or [让多个助手一起讨论]

助手列表
名称 | 绑定知识库 | 绑定技能 | 状态

对话区

多个助手讨论
议题 / 参与助手 / 讨论结果

高级：记忆 / 工具 / 权限 / 使用记录
```

### 5.9 成果中心

```text
成果中心
查看和导出所有生成结果。

[查看成果] or [导出成果]

文档
知识库
技能
助手
讨论报告
使用记录
```

### 5.10 设置

```text
设置
配置模型服务、本地/专业模式和导出方式。

[设置模型服务]

模型服务：需要设置 / 已连接 / 连接失败
本地/专业模式：使用本地模式
导出设置：Markdown 可用，Office 需要设置
网络权限：未开启
存储位置：可用

高级设置：Provider / Gateway / ModelRoute / Redis / Vector DB / Profile
```

## 6. Execution Implications

The existing `ui_information_architecture_restructure_plan.md` remains directionally correct, but screenshot review makes these changes stricter:

1. `工作本管理` should be removed from ordinary first-level navigation, not just weakened.
2. `检索与验证` should become `测试知识库`; keep it first-level only if needed for workflow clarity.
3. `产物中心` must be renamed `成果中心`.
4. `治理与审计` must be renamed `使用记录` and weakly placed.
5. Settings must hide `Provider / 模型`, `Redis / 向量库` behind ordinary labels first.
6. `Skill 工厂` and `Agent 工作台` need ordinary Chinese labels before layout refinement.
7. Raw error/status text such as `desktop_runtime_required` and `blocked` must be translated before Owner EXE review.

## 7. Next Gate Recommendation

Proceed to:

```text
ui_information_architecture_restructure_execution_gate
```

Execution order:

1. Navigation rename and first-level pruning.
2. Ordinary label replacement for page titles, tabs, buttons, and statuses.
3. One-primary-action enforcement per page.
4. Settings/usage-record/developer-mode demotion.
5. Widget contract updates.
6. EXE/web screenshot re-capture and Owner review package.

Do not start visual beautification before these IA changes are implemented.
