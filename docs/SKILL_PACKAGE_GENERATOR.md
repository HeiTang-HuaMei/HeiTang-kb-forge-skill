# Skill Package Generator

v1.8 generates a package-scoped Skill Package from a HeiTang KB Forge knowledge package.

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_v18_package --output .\tmp_v18_skill --skill-name "Demo Knowledge Skill" --skill-type generic
```

Outputs:

* SKILL.md
* skill_manifest.yaml
* knowledge_scope.md
* answer_rules.md
* citation_rules.md
* boundary_rules.md
* refusal_rules.md
* style_rules.md
* evidence_policy.md
* examples.md
* eval_cases.jsonl
* skill_generation_report.md

The Skill is constrained by package evidence, governance results, retrieval context, and Evidence Gate outputs.
