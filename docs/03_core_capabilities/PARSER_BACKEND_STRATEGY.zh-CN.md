# Parser Backend Strategy

当前 Core 版本：`3.12.0-alpha.1`

本文只记录 parser backend strategy。不新增 parser 代码、不新增依赖、不下载模型、不运行外部 parser。

## 已完成的 Core Parser 能力

HeiTang KB Forge 当前已完成的 parser 能力仍然是：

- 已验证的 internal parser，覆盖本地 Markdown、TXT、DOCX、文本 PDF、表格、HTML、EPUB、ZIP、图片 route 和混合源 ingestion 路径
- bounded best-effort OCR，用于本地 OCR route
- 本地 PDF token reduction 和 parser truth evidence

这些才是当前 Core tests 与 final proof 覆盖的已完成 parser 能力。外部 parser backend 在 adapter 与 acceptance proof 改变产品真值前，仍然只是独立候选。

## 外部 Backend 候选

| 候选 | 定位 | 当前状态 |
| --- | --- | --- |
| OpenDataLoader | 端到端 PDF -> Markdown/JSON/RAG-ready parser 候选，用于未来完整 PDF 内容包装路径。 | external backend candidate；planned adapter |
| PaddleOCR | OCR 基础能力候选，用于文字检测与识别。 | external backend candidate；planned adapter |
| MinerU | 文档结构理解与复杂版面解析候选，用于阅读顺序、章节、图片、公式和表格密集页面。 | external backend candidate；planned adapter |
| PaddleOCR + MinerU | OCR + document understanding pipeline 候选：PaddleOCR 提供 OCR foundation，MinerU 处理结构与复杂版面推理。 | external backend candidate；planned adapter |

## 治理边界

- 不把 OpenDataLoader、PaddleOCR、MinerU 或 PaddleOCR + MinerU pipeline 描述为当前已完成的 HeiTang KB Forge 能力。
- 未来 adapter 必须通过 local privacy、secret redaction、parser quality、token reduction、reliability 和 acceptance gate 后，才能改变产品真值。
- 本策略不新增依赖、不下载模型、不触发 runtime invocation、不改变 Core parser 实现。
- 当前 release 表述必须继续说明：HeiTang KB Forge 已完成能力是已验证的 internal parser、bounded best-effort OCR 和 PDF token reduction。
