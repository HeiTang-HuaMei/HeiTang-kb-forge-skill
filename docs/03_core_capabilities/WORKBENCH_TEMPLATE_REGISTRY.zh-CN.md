# P1 Workbench Template Registry

P1 template registry 由以下命令写入 `workbench_template_registry.json`：

```powershell
python -m heitang_kb_forge.cli workbench-contracts --profile p1 --output .\tmp_workbench_p1
```

registry 包含 6 个确定性模板：

- 产品经理知识库模板
- 图书/出版社知识库模板
- 企业制度知识库模板
- 教育伴学模板
- 导购/运营 Agent 模板
- 软件说明书 / 操作 Skill 模板

每个模板都包含 `use_case`、`recommended_inputs`、`chunk_strategy`、`metadata_rules`、`retrieval_strategy`、`skill_output_structure`、`agent_config`、`evaluation_questions`、`example_reports`、`p1_ready` 和 `blocked_reason`。

模板条目只属于 Core contract，不包含真实用户内容、本地 provider profile、secret 或 UI layout 规则。
