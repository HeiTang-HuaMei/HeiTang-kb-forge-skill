# Parser Backend Strategy

当前 Core package 版本：`4.1.0`
当前 stable release：`v4.0.0`
当前 release candidate line：`v4.1.0`

本文记录 parser backend strategy。不会把外部 runtime 变成默认路径，不下载模型；只有显式选择 backend 且本地安装对应依赖时，才会运行外部 parser。

## 已完成的 Core Parser 能力

HeiTang KB Forge 当前已完成的 parser 能力仍然是：

- 已验证的 internal parser，覆盖本地 Markdown、TXT、DOCX、文本 PDF、表格、HTML、EPUB、ZIP、图片 route 和混合源 ingestion 路径
- bounded best-effort OCR，用于本地 OCR route
- 本地 PDF token reduction 和 parser truth evidence

这些是默认 parser path 覆盖的能力。P2.1 额外完成了 Docling、PaddleOCR、Unstructured 的 optional real local adapters 的 release hardening；只有在本地安装对应依赖并显式选择后才会调用，默认 Core path 不变。

可选的本地真实 runtime adapter 已覆盖三个 S 级 parser/OCR 项目：

- Docling：结构化文档转换
- PaddleOCR：本地 OCR runtime
- Unstructured：通过 `parser-unstructured` extra 覆盖 Markdown/TXT 文档解析

## 外部 Backend 候选

| 候选 | 定位 | 当前状态 |
| --- | --- | --- |
| OpenDataLoader | 端到端 PDF -> Markdown/JSON/RAG-ready parser 候选，用于未来完整 PDF 内容包装路径。 | external backend candidate；planned adapter |
| PaddleOCR | OCR 基础能力，用于文字检测与识别。 | optional real local runtime adapter；更广 OCR pipeline 仍为 planned |
| MinerU | 文档结构理解与复杂版面解析候选，用于阅读顺序、章节、图片、公式和表格密集页面。 | external backend candidate；planned adapter |
| PaddleOCR + MinerU | OCR + document understanding pipeline 候选：PaddleOCR 提供 OCR foundation，MinerU 处理结构与复杂版面推理。 | planned combined pipeline；不是当前 stable surface |

## 治理边界

- 不把 OpenDataLoader、MinerU 或 PaddleOCR + MinerU pipeline 描述为当前已完成的 HeiTang KB Forge 能力。
- 不把 Docling、PaddleOCR 或 Unstructured 描述为默认 Core parser、已打包 runtime 或 UI 可执行外部项目；它们仍然是 opt-in 的本地 runtime adapters。
- 未来 adapter 必须通过 local privacy、secret redaction、parser quality、token reduction、reliability 和 acceptance gate 后，才能改变产品真值。
- 本策略保持默认 Core parser 实现不变，但当本地安装对应依赖并显式选择时，optional adapter 可以触发真实 runtime invocation。
- 当前 release 表述必须说明：HeiTang KB Forge 保留已验证的 internal parser capability 与 builtin fallback，同时具备 P2.1 Docling、PaddleOCR、Unstructured opt-in runtime integrations，并遵守已文档化 stable surfaces。
