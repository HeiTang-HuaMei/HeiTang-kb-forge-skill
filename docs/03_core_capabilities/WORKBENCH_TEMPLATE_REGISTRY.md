# P1 Workbench Template Registry

The P1 template registry is emitted in `workbench_template_registry.json` by:

```powershell
python -m heitang_kb_forge.cli workbench-contracts --profile p1 --output .\tmp_workbench_p1
```

The registry contains six deterministic templates:

- 产品经理知识库模板
- 图书/出版社知识库模板
- 企业制度知识库模板
- 教育伴学模板
- 导购/运营 Agent 模板
- 软件说明书 / 操作 Skill 模板

Each template includes `use_case`, `recommended_inputs`, `chunk_strategy`, `metadata_rules`, `retrieval_strategy`, `skill_output_structure`, `agent_config`, `evaluation_questions`, `example_reports`, `p1_ready`, and `blocked_reason`.

Template entries are Core contracts only. They do not include raw user content, local provider profiles, secrets, or UI layout rules.
