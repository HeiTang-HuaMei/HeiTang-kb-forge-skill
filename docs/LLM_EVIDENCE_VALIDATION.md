# LLM Evidence Validation

v1.7 can optionally run LLM-assisted evidence validation on top of the local Evidence Gate.

```powershell
python -m heitang_kb_forge.cli evidence-gate --package .\output --query "What is this package about?" --output .\gate_llm --llm --llm-provider mock --llm-evidence-validation --llm-boundary-check --llm-hallucination-check
```

Outputs may include:

* llm_evidence_validation.json
* llm_evidence_validation_report.md
* llm_boundary_judgment.json
* llm_hallucination_check.json
* llm_call_log.jsonl

This is an adapter and validation layer. It does not replace local evidence gating.
