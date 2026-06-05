# Skill Package Generator

v1.8 可以从 HeiTang KB Forge 知识包生成受知识范围约束的 Skill Package。

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_v18_package --output .\tmp_v18_skill --skill-name "Demo Knowledge Skill" --skill-type generic
```

输出：

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

Skill 受知识包证据、治理结果、检索上下文和 Evidence Gate 输出约束。
