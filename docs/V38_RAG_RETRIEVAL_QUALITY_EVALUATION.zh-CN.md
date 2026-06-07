# v3.8 RAG Retrieval Quality & Evaluation

v3.8 在 v3.7 retrieval plan 之上执行本地、确定性的检索质量与知识验证逻辑。它会在可用时消费 `retrieval_plan.json` 中的 query variants 与 subqueries，然后执行 bounded multi-query recall、candidate merge/dedup、deterministic rerank、evidence selection、diagnostics、golden query evaluation 和本地 claim verification。

## 输出

- `multi_query_recall_trace.json`
- `rerank_report.json`
- `evidence_selection_trace.json`
- `retrieval_failure_report.json`
- `retrieval_quality_report.json`
- `retrieval_quality_report.md`
- `golden_query_eval_report.json`
- `claim_verification_report.json`
- `source_cross_check_report.json`
- `contradiction_map.json`
- `freshness_check_report.json`
- `knowledge_accuracy_report.json`
- `verification_retrieval_trace.json`
- `v38_external_absorption_map.json`

External Benchmark Absorption Map 是 v3.8 的必需产物。它记录每个 v3.8 capability 对应的外部基准 pattern、吸收内容、不复制内容、本地确定性实现路径、离线 fallback、测试和报告/trace 输出。

## CLI

- `eval-retrieval --package ... --output ...`
- `rerank-results --package ... --query ... --output ...`
- `select-evidence --package ... --query ... --output ...`
- `diagnose-retrieval-failure --package ... --query ... --output ...`
- `verify-claims --package ... --output ...`
- `check-knowledge-accuracy --package ... --output ...`

所有命令都不需要真实 LLM/API/network。v3.8 会拒绝 `allow_external_network` 和 `allow_llm_judge`。

## 配置

```yaml
retrieval_quality:
  enabled: true
  use_query_planning: true
  top_k: 5
  max_candidates: 50
  enable_rerank: true
  enable_evidence_selection: true
  enable_failure_diagnostics: true
  enable_claim_verification: true
  verification_sources: []
  allow_external_network: false
  allow_llm_judge: false
```

除非启用 `retrieval_quality.enabled` 或显式使用 v3.8 CLI，默认 `build`、`kb-query` 和 `kb-answer` 行为保持不变。

## 边界

v3.8 不实现 web search、SaaS、cloud-hosted user data、Agent Runtime、workspace storage lifecycle、local PDF-to-Markdown preprocessing 或 parser backend benchmark。
