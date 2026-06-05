# Agent Package Generator

v1.8 可以从知识包和 Skill Package 生成 Agent 创建包。

```powershell
python -m heitang_kb_forge.cli generate-agent --package .\tmp_v18_package --skill .\tmp_v18_skill --output .\tmp_v18_agent --agent-name "Demo Knowledge Agent" --agent-type generic
```

输出：

* soul.md
* role.md
* system_prompt.md
* agent_profile.yaml
* tool_config.yaml
* retrieval_config.yaml
* skill_manifest.yaml
* memory_policy.md
* safety_boundary.md
* launch_checklist.md
* agent_package_report.md

它不会创建或部署真实 Agent，只生成可审计的 Agent 创建文件。
