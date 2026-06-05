# Evidence Gate

v1.7 adds an opt-in evidence gate for checking whether a query is supported by a package.

```powershell
python -m heitang_kb_forge.cli evidence-gate --package .\output --query "What is this package about?" --output .\gate_output
```

Decisions:

* allow
* refuse
* needs_review

Outputs:

* evidence_gate_result.json
* evidence_gate_report.md

The gate is local and evidence-first. Optional mock LLM validation can be enabled for tests without network calls.
