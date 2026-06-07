# v3.7 Query Rewrite & Retrieval Planning

v3.7 adds a deterministic, local-first query planning layer. It normalizes user queries, rewrites vague queries, expands terms, decomposes compound questions, resolves follow-up questions only from explicit context, generates bounded multi-query variants, and writes retrieval plans.

## Outputs

- `query_rewrite_report.json`
- `query_rewrite_trace.json`
- `retrieval_plan.json`
- `retrieval_plan_report.md`
- `query_rewrite_eval_report.json` from `eval-query-rewrite`

`retrieval_plan.json` separates `retrieval_purpose=answering` from `retrieval_purpose=validation`. Validation planning in v3.7 does not perform external retrieval, claim verification, contradiction detection, or source cross-checking.

## CLI

- `rewrite-query --query ... --output ...`
- `plan-retrieval --query ... --purpose answering|validation --output ...`
- `eval-query-rewrite --cases ... --output ...`

All commands are deterministic and offline by default. `--allow-llm-rewrite` only records a reserved optional assist path; it does not call a provider.

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

Default build, `kb-query`, and `kb-answer` behavior remains unchanged unless this block is enabled or the v3.7 CLI commands are used.

## Boundaries

v3.7 does not implement rerank, evidence selection, claim verification, external source retrieval, contradiction detection, knowledge accuracy scoring, Agent Runtime, SaaS, multi-user, or cloud-hosted storage.
