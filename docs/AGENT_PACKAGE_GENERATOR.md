# Agent Package Generator

v1.8 generates an Agent creation package from a knowledge package and Skill Package.

```powershell
python -m heitang_kb_forge.cli generate-agent --package .\tmp_v18_package --skill .\tmp_v18_skill --output .\tmp_v18_agent --agent-name "Demo Knowledge Agent" --agent-type generic
```

Outputs:

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

This does not create or deploy a real Agent. It only prepares auditable creation files.
