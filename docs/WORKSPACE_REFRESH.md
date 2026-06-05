# Workspace Refresh

v2.2 checkpoint fill adds static workspace refresh analysis.

Use:

```powershell
python -m heitang_kb_forge.cli workspace-refresh --workspace .\workspace --output .\refresh_output
```

Outputs include source change, refresh plan, impacted packages, impacted Skills, impacted Agents, and dependency impact reports.

The command does not run a background watcher and does not regenerate packages, Skills, or Agents.
