# v2.9 Knowledge Runtime Loop

v2.9.0-alpha.1 新增 opt-in 本地 Knowledge Runtime Loop，用于在不调用外部服务的情况下使用已有知识包。

## 范围

- 构建本地 KB index。
- 执行确定性本地 query ranking。
- 写出 query trace 和 citation trace。
- 生成带引用的本地答案。
- 低置信时拒答。
- 生成 retrieval quality 证据。
- 生成 RAG eval baseline。

## 命令

```powershell
python -m heitang_kb_forge.cli kb-index --package .\tmp_quickstart_output --output .\tmp_kb_runtime
python -m heitang_kb_forge.cli kb-query --package .\tmp_quickstart_output --query "pricing evidence" --output .\tmp_kb_runtime
python -m heitang_kb_forge.cli kb-answer --package .\tmp_quickstart_output --query "pricing evidence" --output .\tmp_kb_runtime
```

Build 也可以在显式启用时生成 runtime 输出：

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_build --knowledge-runtime --kb-query "summarize evidence"
```

配置文件支持：

```yaml
knowledge_runtime:
  enabled: true
  query: pricing evidence
  top_k: 5
  min_score: 2
  citation_required: true
```

## 输出文件

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

## 边界

v2.9 默认本地、确定性运行。它不调用 LLM API、embedding API、向量数据库、外部 Agent runtime、飞书、移动端、安装端或 iOS surface。

