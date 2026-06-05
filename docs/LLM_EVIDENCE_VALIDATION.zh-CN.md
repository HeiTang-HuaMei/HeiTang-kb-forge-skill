# LLM 证据校验

v1.7 可以在本地 Evidence Gate 之上可选运行 LLM 辅助证据校验。

```powershell
python -m heitang_kb_forge.cli evidence-gate --package .\output --query "这个知识包主要讲什么？" --output .\gate_llm --llm --llm-provider mock --llm-evidence-validation --llm-boundary-check --llm-hallucination-check
```

输出可能包括：

* llm_evidence_validation.json
* llm_evidence_validation_report.md
* llm_boundary_judgment.json
* llm_hallucination_check.json
* llm_call_log.jsonl

这是 adapter 和校验层，不替代本地 Evidence Gate。
