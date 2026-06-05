# 更新影响分析

v2.3 增加本地 update impact 报告，用于分析知识包、Skill、Agent 的依赖影响。

输出：

- `impacted_packages.json`
- `impacted_skills.json`
- `impacted_agents.json`
- `update_required_report.md`
- `dependency_impact_report.md`

使用：

```powershell
python -m heitang_kb_forge.cli update-impact --workspace .\workspace --package .\new_package --output .\impact_output
```

该命令只建议 revalidate 或 regenerate，不会自动重生成 Skill 或 Agent。
