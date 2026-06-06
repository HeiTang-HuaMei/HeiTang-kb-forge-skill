# 外部 GitHub 项目接入清单

## 接入原则

HeiTang Knowledge Workbench 不从零自研所有能力。

接入策略：

1. KB Forge Core 负责知识资产标准化、质量门禁、证据边界、复核流程。
2. 外部成熟项目负责文档解析、OCR、RAG、评测、文档生成。
3. 所有外部项目必须 optional。
4. 未安装时不应阻断 builtin 流程。
5. 不复制外部项目源码，只做 adapter / wrapper。
6. 所有输出必须归一化为 KB Forge 标准知识资产包。
7. 必须保留 license / source / version 信息。
8. 不把外部项目输出直接视为可信知识，仍需 quality gate / evidence gate / review queue。

---

## A. Parser / OCR / Document Understanding

### 1. Docling

GitHub：

https://github.com/docling-project/docling

用途：

- 通用文档解析。
- PDF / Office / HTML 等文档转结构化内容。
- 适合作为 v2.8 第一优先级 parser backend。

接入方式：

- optional dependency。
- CLI wrapper。
- 输出 Markdown / JSON。
- 转换为 KB Forge chunks / source inventory / evidence map。

建议命令：

- parser-backend-list
- parse-with-backend --backend docling
- build --parser-backend docling

---

### 2. Marker

GitHub：

https://github.com/datalab-to/marker

用途：

- PDF / image / PPTX / DOCX / XLSX / HTML / EPUB 转 Markdown / JSON / chunks / HTML。
- 表格、公式、图片提取能力强。
- 适合作为复杂 PDF 与多格式解析后端。

接入方式：

- optional dependency。
- CLI wrapper。
- 输出 Markdown / JSON / chunks。
- 进入 parse compare。

建议命令：

- parse-with-backend --backend marker
- parse-compare --backend builtin,marker

---

### 3. MinerU

GitHub：

https://github.com/opendatalab/MinerU

用途：

- PDF / image / DOCX / PPTX / XLSX 转 Markdown / JSON。
- 适合复杂文档、科研文档、公式/版面密集文档。
- 第二阶段接入。

接入方式：

- optional backend。
- 不作为 v2.8 首批强依赖。
- 先保留 adapter 规划和 install doctor。

---

### 4. PaddleOCR

GitHub：

https://github.com/PaddlePaddle/PaddleOCR

用途：

- 中文 OCR。
- PDF / 图片转结构化 LLM-ready 数据。
- 适合中文扫描件、教材、合同、表格图片。

接入方式：

- optional OCR backend。
- 先做 doctor 和 backend registry。
- 后续实现 --ocr-backend paddleocr。

---

### 5. Surya

GitHub：

https://github.com/datalab-to/surya

用途：

- OCR。
- layout analysis。
- reading order。
- table recognition。
- 多语言文档识别。

接入方式：

- optional OCR/layout backend。
- 适合图文混排、表格页、阅读顺序检测。
- 后续实现 --ocr-backend surya。

---

### 6. Unstructured

GitHub：

https://github.com/Unstructured-IO/unstructured

用途：

- 企业文档 ingestion / preprocessing。
- partition 函数按文件类型路由解析。
- 可作为通用 fallback parser。

接入方式：

- optional parser backend。
- 输出元素类型映射到 KB Forge 标准 chunk 类型。
- 后续接入。

---

## B. Knowledge Runtime / RAG

### 7. LlamaIndex

GitHub：

https://github.com/run-llama/llama_index

用途：

- 数据连接。
- 索引。
- 检索。
- 查询接口。
- Agent / workflow 生态。

接入方式：

- v2.9 Knowledge Runtime Loop。
- kb-index --backend llamaindex。
- kb-query --backend llamaindex。
- kb-answer --backend llamaindex。

---

### 8. RAGAS

GitHub：

https://github.com/explodinggradients/ragas

用途：

- RAG 评测。
- context precision / recall。
- faithfulness。
- answer relevancy。

接入方式：

- rag-eval --backend ragas。
- 作为 release gate 的 optional eval。
- 不作为默认 CI 强依赖。

---

### 9. DeepEval

GitHub：

https://github.com/confident-ai/deepeval

用途：

- LLM / RAG / Agent eval。
- 单元测试式评测。
- hallucination / answer relevancy / task completion 等指标。

接入方式：

- eval backend。
- 可用于 Agent / Skill validation。
- v2.9 或 v3.1 接入。

---

## C. Document Generation

### 10. python-docx

GitHub：

https://github.com/python-openxml/python-docx

用途：

- 生成和修改 Word .docx。

接入方式：

- v3.0 Document Generation Loop。
- generate-docx。
- template registry。
- citation appendix。

---

### 11. python-pptx

GitHub：

https://github.com/scanny/python-pptx

用途：

- 生成和修改 PowerPoint .pptx。

接入方式：

- v3.0。
- generate-pptx。
- slide template。
- source citation slide。

---

### 12. WeasyPrint

GitHub：

https://github.com/Kozea/WeasyPrint

用途：

- HTML / CSS 转 PDF。
- 适合报告、讲义、知识库导出文档。

接入方式：

- v3.0。
- generate-pdf。
- HTML intermediate。
- PDF export validation。

---

## 接入优先级

### 第一优先级：v2.8

- Docling
- Marker

### 第二优先级：v2.9

- LlamaIndex
- RAGAS
- DeepEval

### 第三优先级：v3.0

- python-docx
- python-pptx
- WeasyPrint

### 第四优先级：后续增强

- MinerU
- PaddleOCR
- Surya
- Unstructured

## 风险

1. 依赖重。
2. Windows 安装复杂。
3. 模型文件大。
4. 许可证边界需要检查。
5. 解析质量不稳定。
6. 多后端输出格式不一致。
7. CI 不适合默认安装全部依赖。
8. 部分后端可能需要 GPU 或额外系统依赖。

## 解决策略

1. optional extras。
2. backend doctor。
3. backend smoke。
4. fallback to builtin。
5. external backend output normalization。
6. 不把任一后端输出视为绝对正确。
7. 多后端差异进入 review queue。
8. 大依赖不进默认 CI。
