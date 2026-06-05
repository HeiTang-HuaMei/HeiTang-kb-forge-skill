# Skill Validation and Benchmark

v1.8 adds local Skill validation and benchmark cases.

```powershell
python -m heitang_kb_forge.cli validate-skill --skill .\tmp_v18_skill --package .\tmp_v18_package --output .\tmp_v18_skill_validation
```

Outputs:

* skill_validation_result.json
* skill_validation_report.md
* skill_benchmark_cases.jsonl

Validation checks evidence grounding, boundary control, refusal rules, citation policy, style consistency, eval coverage, and release readiness.
