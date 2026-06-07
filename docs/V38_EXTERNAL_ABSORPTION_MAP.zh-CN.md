# v3.8 External Benchmark Absorption Map

`v38_external_absorption_map.json` 是 v3.8 完成的必需产物。它把 v3.6 的外部基准审计转成每个 v3.8 capability 的可审计实现映射。

该 map 覆盖 multi-query recall、candidate merge/dedup、deterministic rerank、evidence selection、retrieval diagnostics、explainable refusal、golden query evaluation、claim extraction、local verification retrieval、source cross-check、contradiction detection、freshness verification、knowledge accuracy scoring 和 verification retrieval trace。

规则：

- 外部项目只作为架构 pattern 来源。
- 不复制外部代码、提示词或数据集。
- v3.8 不新增高风险依赖。
- 测试不需要网络，也不需要真实 LLM/API。
- v3.9 storage/PDF/parser 工作和 v3.10 Agent Runtime 不属于本轮范围。
