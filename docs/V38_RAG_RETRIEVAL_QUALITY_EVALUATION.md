# v3.8 RAG Retrieval Quality & Evaluation

v3.8 executes local, deterministic retrieval quality and knowledge verification logic on top of v3.7 retrieval plans. It consumes `retrieval_plan.json` query variants and subqueries when available, then performs bounded multi-query recall, candidate merge/dedup, deterministic rerank, evidence selection, diagnostics, golden query evaluation, and local claim verification.

## Outputs

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

The External Benchmark Absorption Map is mandatory. It records which audited external patterns informed each v3.8 capability, what is absorbed, what is not copied, the deterministic local implementation path, offline fallback, tests, and report/trace outputs.

## CLI

- `eval-retrieval --package ... --output ...`
- `rerank-results --package ... --query ... --output ...`
- `select-evidence --package ... --query ... --output ...`
- `diagnose-retrieval-failure --package ... --query ... --output ...`
- `verify-claims --package ... --output ...`
- `check-knowledge-accuracy --package ... --output ...`

All commands run without real LLM/API/network calls. `allow_external_network` and `allow_llm_judge` are rejected in v3.8.

## Config

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

Default `build`, `kb-query`, and `kb-answer` behavior remains unchanged unless `retrieval_quality.enabled` is true or a v3.8 CLI command is used.

## Boundaries

v3.8 does not implement web search, SaaS, cloud-hosted user data, Agent Runtime, workspace storage lifecycle, local PDF-to-Markdown preprocessing, or parser backend benchmarks.
