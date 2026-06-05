# Studio Run

`studio-run` runs a local stable workflow from source input to a workspace-level Studio summary.

It uses the existing offline build, Skill package, Agent package, workspace registration, stable check, reliability score, and release checklist layers. It does not call real LLM APIs, vector databases, or Agent runtimes.

```powershell
python -m heitang_kb_forge.cli studio-run --input .\examples\quickstart\input --workspace .\tmp_v20_workspace --project-name demo_project --profile stable
```

Outputs include `studio_run_manifest.json`, `studio_run_report.md`, and `release_checklist.md`.
