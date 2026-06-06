# HeiTang Knowledge Workbench 立项文档

## 1. 项目名称

HeiTang Knowledge Workbench

## 2. 项目定位

HeiTang Knowledge Workbench 是一个本地优先、可被 Agent 调度的知识资产生产与 Agent/Skill 生成工具台。

它不是单一 Skill，也不是单一 RAG Demo，而是一条由多个 Skill / Agent 组成的知识工业链路。

底层核心为 HeiTang KB Forge Core，负责将多格式资料加工成标准化、可审计、可复核、可检索的知识资产包；上层逐步扩展知识库问答、文档生成、专属 Agent / Skill 生成、外部 Skill 拆解融合、本地工作台 UI。

## 3. 终极目标

用户上传各种资料：

- PDF
- DOCX
- Markdown
- TXT
- CSV / TSV / XLSX
- 图片
- 扫描 PDF
- HTML / EPUB / ZIP 等扩展格式

系统自动完成：

1. 多后端解析 / OCR / 结构化。
2. 生成多类型知识库。
3. 质量门禁、证据追踪、人工复核。
4. 知识库可检索、可问答、可引用来源。
5. 用户选择知识库内容后，自动生成 MD / Word / PDF / PPT。
6. 自动生成绑定知识库的专属行业 Agent / Skill。
7. 拆解别人 Skill。
8. 融合自身知识库。
9. 生成自己的专用 Skill / Agent。
10. 在本地 Workbench 中完成上传、进度、审核、查询、生成、导出。

## 4. 当前状态

当前已完成到 v2.9.0-alpha.1，并补充了本地 Knowledge Runtime Loop checkpoint。

已具备：

- 多格式输入基础。
- 知识资产包生成。
- progress / observability。
- 大文件 OCR 参数控制。
- quality gate / evidence gate。
- Provider Governance。
- mock / live 边界。
- Skill / Agent 静态导出。
- demo-e2e 最小闭环。
- parser backend registry / parse compare / quality gate / trusted KB gate。
- kb-index / kb-query / kb-answer / citation trace / low-confidence refusal / RAG eval baseline。
- CI / Release Check / tag。
- 作品集与面试展示文档。

当前真实定位：

HeiTang KB Forge Core 是知识供应链核心 Skill，不是完整工具台产品。

## 5. 当前完成度判断

| 目标层级 | 当前完成度 |
|---|---:|
| GitHub / 面试作品集 | 85% |
| KB Forge Core Skill | 60% |
| 本地知识工作台 | 30% - 35% |
| 完整工具台产品 | 30% |
| 工业级团队产品 | 20% - 25% |

## 6. 核心问题

当前主要短板不是“没有功能”，而是：

1. 复杂资料解析可靠性不足。
2. OCR / 表格 / 图片 / 版面理解不能只靠内置能力。
3. 知识库生成后还不能稳定问答。
4. 不能从知识库稳定生成 Word / PDF / PPT。
5. Agent / Skill 仍偏静态导出包，没有形成知识库绑定后的可用行业 Agent。
6. 不能真正拆解并融合外部 Skill。
7. 没有产品化 Workbench UI。
8. 没有任务队列、审核队列、导出中心。
9. 人工复核与 corrected text 回灌闭环不足。
10. 完整产品必须由多 Skill + 调度 Agent 组成，不能继续塞进单一 Skill。

## 7. 产品架构

HeiTang Knowledge Workbench = 多 Skill + 多 Agent 调度的知识工具台。

核心分层：

1. Workbench UI 层。
2. Workbench Agent 调度层。
3. Skill / Tool 能力层。
4. Knowledge Asset Contract 层。
5. External Backend Adapter 层。
6. Provider Governance 层。
7. Release / Quality / Evidence Gate 层。

## 8. 子系统拆分

### 8.1 HeiTang KB Forge Core

职责：

- 多格式资料进入知识系统前的标准化加工。
- 生成标准知识资产包。
- 质量门禁。
- 证据追踪。
- 复核准备。
- RAG / Agent 上游输出。

### 8.2 Parser Backend Skill

职责：

- 接入 Docling / Marker / MinerU / PaddleOCR / Surya / Unstructured。
- 多解析器对比。
- 解析质量报告。
- 高风险页标注。
- 人工复核队列。

### 8.3 Knowledge Runtime Skill

职责：

- kb-index。
- kb-query。
- kb-answer。
- citation required answer。
- low-confidence refusal。
- query trace。
- RAG eval。

### 8.4 Document Generator Skill

职责：

- generate-md。
- generate-docx。
- generate-pdf。
- generate-pptx。
- 模板系统。
- 引用插入。
- 导出验证。

### 8.5 Agent Factory Skill

职责：

- 选择知识库。
- 选择行业场景。
- 生成绑定知识库的 Agent / Skill。
- 绑定检索工具。
- 绑定 Provider。
- 生成测试用例。
- smoke 验证。

### 8.6 Skill Reverse & Fusion Skill

职责：

- 导入外部 Skill。
- 分析 instruction / tools / schema / examples。
- 抽取能力边界。
- 抽取 prompt pattern。
- 结合自身知识库生成新 Skill。
- 输出 diff report / safety report。

### 8.7 Review / Correction Skill

职责：

- low-quality chunk 队列。
- OCR / table / image 风险标注。
- 人工修正。
- corrected_text 回灌。
- 修正前后质量对比。

## 9. 产品边界

当前阶段不做：

- SaaS。
- 多人权限。
- 云部署。
- 自动发布小红书。
- 真实平台自动发布。
- 完整企业协作。
- 用 mock 冒充 live。
- 声称任意扫描 PDF 自动高精度入库。

## 10. 项目成功标准

达到本地工具台产品形态时，必须满足：

1. 非技术用户可在本地上传资料。
2. 可查看进度。
3. 可查看知识包。
4. 可识别高风险内容。
5. 可人工复核和修正。
6. 可基于知识库问答。
7. 回答必须能引用来源。
8. 可生成 MD / Word / PDF / PPT。
9. 可生成绑定知识库的 Agent / Skill。
10. 可导入外部 Skill 并融合自身知识库。
11. 所有结果有 evidence / report / validation。
12. CI / smoke / release gate 通过。

## 11. 项目原则

- 一个版本只解决一个大问题。
- 不允许把 P0 问题留到补丁版本。
- 不允许 mock 冒充 live。
- 不允许 README 夸大能力。
- 不允许 CI 红进入下一版。
- 不允许把所有能力继续塞进一个巨型 Skill。
- KB Forge Core 保持为知识供应链核心。
- Workbench 负责产品化调度与体验。

## Agent 与知识库关系

知识库不是 Agent 的全部大脑，而是 Agent 的可信资料层。

Agent 负责理解问题、调度检索、筛选证据、组织回答、引用来源、拒答不确定内容和调用工具。

知识库负责提供可信事实、来源证据、业务边界和可追踪材料。

大模型负责理解、归纳、生成和格式化；在允许时可以补充通用知识，但必须与知识库依据区分。

系统必须支持多种回答策略：

- strict_grounded
- knowledge_first
- creative_grounded
- open

默认采用 knowledge_first；高风险场景采用 strict_grounded。

