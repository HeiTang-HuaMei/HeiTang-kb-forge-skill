# HeiTang Knowledge Workbench 版本计划

## 当前基线

当前版本：

- v2.6.0-alpha.1：真实 LLM Provider Governance。
- v2.7.0-alpha.1：Minimal End-to-End Demo。
- docs commit：Portfolio Presentation Pack。

当前总体进度：

| 层级 | 当前进度 |
|---|---:|
| GitHub 作品集 | 85% |
| KB Forge Core Skill | 60% |
| 本地工具台产品 | 30% - 35% |
| 完整工业级工具台 | 30% |
| 团队 / SaaS 平台 | 20% - 25% |

## 版本规则

每个版本必须解决一个大问题。

每版必须包含：

1. 实现。
2. 文档。
3. 测试。
4. smoke。
5. release gate。
6. demo。
7. known limits。
8. 不进入下一版前完成本版 DoD。

禁止：

- 先做壳，后补核心。
- 把 P0 留到 x.x.1。
- CI 红进入下一版。
- mock 冒充 live。
- README 声明未完成能力。
- 一个版本同时塞多个主线问题。

---

## v2.8：Parser Backend & Knowledge Reliability

### 核心问题

复杂资料解析可靠性不足。OCR / PDF / 表格 / 图片质量不可控。

### 目标

让 KB Forge 支持外部成熟解析器后端，并把不同解析结果统一纳入知识资产生产链路。

### 必须完成

1. parser_backend_registry。
2. optional Docling backend。
3. optional Marker backend。
4. parse-with-backend。
5. parse-compare。
6. parse-quality-gate。
7. high_risk_parse_pages.jsonl。
8. manual_review_queue.jsonl。
9. corrected_text re-import。
10. before / after quality diff。
11. knowledge_reliability_report.json。
12. docs / tests / smoke / release gate。

### 外部项目

- Docling：https://github.com/docling-project/docling
- Marker：https://github.com/datalab-to/marker

### 不做

- 不做 RAG 问答。
- 不做 Word / PPT / PDF 生成。
- 不做 Skill 融合。
- 不做 Workbench UI。

### 完成标准

同一份资料可用 builtin / docling / marker 至少两种路径解析；系统能发现高风险页 / 高风险 chunk；人工修正文本可以回灌重新 build；能输出修正前后质量对比。

### 完成后进度

完整工具台：30% - 35% → 45%。

---

## v2.9：Knowledge Runtime Loop

### 核心问题

知识库生成后还不能稳定使用。

### 目标

让知识库可检索、可问答、可引用、可低置信拒答。

### 必须完成

1. kb-index。
2. kb-query。
3. kb-answer。
4. citation required mode。
5. evidence-grounded answer。
6. low-confidence refusal。
7. query trace。
8. feedback log。
9. retrieval quality report。
10. RAG eval baseline。
11. docs / tests / smoke / release gate。

### 外部项目

- LlamaIndex：https://github.com/run-llama/llama_index
- RAGAS：https://github.com/explodinggradients/ragas
- DeepEval：https://github.com/confident-ai/deepeval

### 不做

- 不做文档生成。
- 不做 Agent 工厂。
- 不做 Skill 融合。
- 不做 Workbench UI。

### 完成标准

用户可以基于已生成知识包提问；回答必须带来源引用；低置信问题必须拒答；检索结果、引用、回答过程可追踪。

### 完成后进度

完整工具台：45% → 55%。

---

## v3.0：Document Generation Loop

### 核心问题

知识库不能自动生成用户想要的文件。

### 目标

用户选择知识库内容后，可生成 MD / Word / PDF / PPT，并保留来源证据。

### 必须完成

1. generate-md。
2. generate-docx。
3. generate-pdf。
4. generate-pptx。
5. template registry。
6. content planner。
7. citation insertion。
8. source evidence appendix。
9. export validation。
10. generated_file_report.json。
11. docs / tests / smoke / release gate。

### 外部项目

- python-docx：https://github.com/python-openxml/python-docx
- python-pptx：https://github.com/scanny/python-pptx
- WeasyPrint：https://github.com/Kozea/WeasyPrint

### 不做

- 不做 Agent 工厂。
- 不做 Skill 融合。
- 不做完整 UI。

### 完成标准

用户选择知识库内容后，可以生成 Markdown、Word、PDF、PPT；生成文件必须带来源依据；输出要验证文件存在、结构完整、引用可追踪。

### 完成后进度

完整工具台：55% → 65%。

---

## v3.1：Knowledge-Bound Agent / Skill Factory

### 核心问题

当前只是静态导出 Skill / Agent 包，还不能生成真正绑定知识库的专属行业 Agent。

### 目标

选择知识库 + 行业场景，生成绑定检索、Provider、证据策略和拒答策略的专属 Agent / Skill。

### 必须完成

1. knowledge-bound-skill。
2. knowledge-bound-agent。
3. retrieval tool binding。
4. provider binding。
5. evidence policy binding。
6. refusal policy binding。
7. agent test cases。
8. agent smoke test。
9. skill validation report。
10. industry agent template registry。
11. docs / tests / smoke / release gate。

### 不做

- 不做 Skill 反向拆解。
- 不做 Workbench UI。
- 不做 SaaS。

### 完成标准

选择一个知识库 + 一个场景，可以生成专属 Agent / Skill。生成物必须包含知识库路径、检索配置、Provider 配置、引用规则、拒答规则、测试问题和 smoke 结果。

### 完成后进度

完整工具台：65% → 75%。

---

## v3.2：Skill Reverse & Fusion Loop

### 核心问题

不能拆解别人 Skill，也不能融合自身知识库生成自己的专用 Skill。

### 目标

导入外部 Skill，拆解能力、prompt pattern、tools/schema/examples，并结合自身知识库生成新 Skill。

### 必须完成

1. import-skill。
2. analyze-skill。
3. extract instructions。
4. extract tools / schema。
5. extract examples。
6. capability map。
7. prompt pattern map。
8. fusion plan。
9. generate-fused-skill。
10. validate-fused-skill。
11. diff report。
12. safety boundary report。
13. docs / tests / smoke / release gate。

### 不做

- 不做 Skill 市场。
- 不做自动发布。
- 不做 SaaS。

### 完成标准

能导入一个外部 Skill；能拆出能力边界、prompt pattern、输入输出；能结合自身知识库生成新 Skill；能输出差异报告和验证结果。

### 完成后进度

完整工具台：75% → 83%。

---

## v3.3：Local Knowledge Workbench UI

### 核心问题

当前仍是 CLI，不是产品化工具台。

### 目标

提供本地 Web UI，支持上传、进度、知识库浏览、人工复核、问答、文档生成、Agent/Skill 生成、导出中心。

### 必须完成

1. local web UI。
2. upload files。
3. job queue。
4. progress dashboard。
5. knowledge package browser。
6. review queue UI。
7. corrected text editor。
8. kb query UI。
9. document generation UI。
10. Agent / Skill generation UI。
11. export center。
12. local workspace history。
13. docs / tests / smoke / release gate。

### 不做

- 不做 SaaS。
- 不做多人权限。
- 不做云部署。

### 完成标准

非技术用户可以在本地页面完成上传资料、查看进度、查看知识包、复核低质量内容、查询知识库、生成文档、生成 Agent / Skill、导出结果。

### 完成后进度

完整工具台：83% → 90%。

---

## v3.4：Product Hardening & Installer

### 核心问题

工具台能跑，但还不够稳定、易安装、易演示。

### 目标

让新机器可以安装、启动、跑 demo、恢复失败任务、备份工作区。

### 必须完成

1. Windows installer / one-click start。
2. dependency doctor。
3. parser backend doctor。
4. OCR dependency doctor。
5. task retry。
6. job resume。
7. error recovery。
8. benchmark dataset。
9. performance dashboard。
10. backup / restore workspace。
11. demo mode。
12. release candidate checklist。
13. docs / tests / smoke / release gate。

### 不做

- 不做 SaaS。
- 不做多人权限。
- 不做企业协作。

### 完成标准

新机器可以按文档安装；一键启动本地 Workbench；失败任务可重试；工作区可备份恢复；demo 可以稳定跑。

### 完成后进度

完整工具台：90% → 94%。

---

## v4.0：Team / SaaS Optional

### 核心问题

如果升级为团队平台，需要权限、协作、部署。

### 必须完成

1. user roles。
2. workspace permissions。
3. team review flow。
4. audit log。
5. deployment mode。
6. API server。
7. multi-user storage。
8. admin dashboard。

### 完成后进度

本地产品：95%+。
团队平台：70%+。

## Agent 与知识库回答策略补充

后续版本必须把 Agent 与知识库的关系设计成可配置策略，而不是写死成一种行为。

策略包括：

- strict_grounded：严格基于知识库证据回答，无证据拒答。
- knowledge_first：优先知识库，允许模型补充，但必须标注非知识库来源。
- creative_grounded：以知识库为素材进行创作，事实点必须可追溯。
- open：知识库作为参考，适合开放式创作和头脑风暴。

默认策略：

```yaml
answer_policy: knowledge_first
```

高风险场景必须使用：

```yaml
answer_policy: strict_grounded
```

v2.9 负责在知识库问答中实现 answer_policy。
v3.1 负责在 Knowledge-Bound Agent / Skill 中写入 answer_policy。
v3.2 负责在 Skill Reverse & Fusion 中识别和重写 answer_policy。

