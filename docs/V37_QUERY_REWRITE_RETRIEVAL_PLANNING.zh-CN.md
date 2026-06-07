# v3.7 Query Rewrite 与 Retrieval Planning

v3.7 新增本地优先、确定性的查询规划层。它支持 query normalization、vague query rewrite、query expansion、query decomposition、只基于显式上下文的 follow-up resolution、bounded multi-query generation，以及 retrieval plan 输出。

## 输出文件

- `query_rewrite_report.json`
- `query_rewrite_trace.json`
- `retrieval_plan.json`
- `retrieval_plan_report.md`
- `eval-query-rewrite` 生成的 `query_rewrite_eval_report.json`

`retrieval_plan.json` 严格区分 `retrieval_purpose=answering` 与 `retrieval_purpose=validation`。v3.7 的 validation planning 不执行 external retrieval、claim verification、contradiction detection 或 source cross-checking。

## CLI

- `rewrite-query --query ... --output ...`
- `plan-retrieval --query ... --purpose answering|validation --output ...`
- `eval-query-rewrite --cases ... --output ...`

所有命令默认确定性、离线执行。`--allow-llm-rewrite` 只记录预留的可选辅助路径，不会调用 provider。

## Config

```yaml
query_rewrite:
  enabled: true
  strategy: hybrid
  use_conversation_context: true
  conversation_context: pricing policy context
  generate_multi_queries: true
  max_rewrites: 5
  allow_llm_rewrite: false
  retrieval_purpose: answering
```

除非启用该配置块或显式使用 v3.7 CLI，默认 build、`kb-query` 和 `kb-answer` 行为保持不变。

## 边界

v3.7 不实现 rerank、evidence selection、claim verification、external source retrieval、contradiction detection、knowledge accuracy scoring、Agent Runtime、SaaS、多用户或云端托管存储。
