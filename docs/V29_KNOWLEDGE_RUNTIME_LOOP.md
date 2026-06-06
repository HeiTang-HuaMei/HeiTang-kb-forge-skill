# v2.9 Knowledge Runtime Loop

v2.9.0-alpha.1 adds an opt-in local Knowledge Runtime Loop for using an existing knowledge package without calling external services.

## Scope

- Build a local KB index.
- Run deterministic local query ranking.
- Write query and citation traces.
- Generate a cited local answer.
- Refuse low-confidence answers.
- Generate retrieval quality evidence.
- Generate a RAG eval baseline.

## Commands

```powershell
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_runtime
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "pricing evidence" --output .\tmp_kb_runtime
python -m heitang_kb_forge.cli kb-answer --package .\tmp_quickstart_output --query "pricing evidence" --output .\tmp_kb_runtime
```

Build can also emit the runtime outputs when explicitly enabled:

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_build --knowledge-runtime --kb-query "summarize evidence"
```

Config-driven runs support:

```yaml
knowledge_runtime:
  enabled: true
  query: pricing evidence
  top_k: 5
  min_score: 2
  citation_required: true
```

## Output Files

- `kb_index.jsonl`
- `kb_index_manifest.json`
- `kb_query_result.json`
- `kb_query_trace.json`
- `kb_citation_trace.json`
- `kb_answer.md`
- `kb_answer_report.json`
- `retrieval_quality_report.json`
- `rag_eval_baseline.jsonl`
- `rag_eval_baseline_report.md`

## Boundaries

v2.9 is local and deterministic by default. It does not call LLM APIs, embedding APIs, vector databases, external Agent runtimes, Feishu, mobile clients, installers, or iOS surfaces.

