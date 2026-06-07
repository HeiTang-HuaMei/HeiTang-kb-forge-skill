# v3.9 外部吸收图

`v39_external_absorption_map.json` 记录 v3.9 如何吸收外部 benchmark 的模式，同时不复制外部代码、prompt，也不引入强制重依赖。

强制参考包括：LiteDoc 的本地 PDF 转 Markdown 与不上传隐私边界、PaddleOCR 的 OCR 路由模式、MinerU 的复杂布局/表格/公式解析模式、Marker/Docling 的解析后端策略，以及 `rohitg00/agentmemory` 的记忆生命周期启发。

吸收图会为每个 v3.9 能力记录：

- benchmark references
- absorb / inspire / reject / future 决策
- 吸收什么
- 不复制什么
- 本地确定性实现路径
- 可选 LLM 辅助路径
- 离线 fallback
- 测试和报告
- 合同影响与风险等级

不复制外部代码或 prompt。测试不需要真实 LLM/API/网络。
