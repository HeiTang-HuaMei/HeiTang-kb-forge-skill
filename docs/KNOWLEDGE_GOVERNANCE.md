# Knowledge Governance

v1.7 adds opt-in knowledge governance for existing HeiTang KB Forge packages.

It generates package diff, lifecycle status, conflict detection, staleness detection, review queue, and a governance report.

```powershell
python -m heitang_kb_forge.cli govern --package .\output --output .\governance_output
```

Outputs:

* package_diff.json
* package_diff_report.md
* lifecycle_manifest.json
* lifecycle_report.md
* conflict_report.json
* conflict_report.md
* staleness_report.json
* staleness_report.md
* review_queue.jsonl
* review_queue_report.md
* governance_report.md

This layer is local and rule-based. It does not call LLMs or vector databases.
