# Studio Run

`studio-run` 用于运行本地稳定版工作流，从源资料生成 workspace 级 Studio 摘要。

它复用现有离线 build、Skill Package、Agent Package、workspace 注册、stable check、reliability score 和 release checklist，不调用真实 LLM API、向量数据库或 Agent Runtime。

```powershell
python -m heitang_kb_forge.cli studio-run --input .\examples\quickstart\input --workspace .\tmp_v20_workspace --project-name demo_project --profile stable
```

输出包括 `studio_run_manifest.json`、`studio_run_report.md` 和 `release_checklist.md`。
