# Update Impact

v2.3 adds local update impact reports for packages, skills, and agents.

Outputs:

- `impacted_packages.json`
- `impacted_skills.json`
- `impacted_agents.json`
- `update_required_report.md`
- `dependency_impact_report.md`

Use:

```powershell
python -m heitang_kb_forge.cli update-impact --workspace .\workspace --package .\new_package --output .\impact_output
```

The command recommends revalidation or regeneration; it does not automatically regenerate Skills or Agents.
