# Workspace Refresh

v2.2 checkpoint 后补增加静态 workspace refresh 分析。

使用：

```powershell
python -m heitang_kb_forge.cli workspace-refresh --workspace .\workspace --output .\refresh_output
```

输出包括 source change、refresh plan、impacted packages、impacted Skills、impacted Agents 和 dependency impact 报告。

该命令不运行后台 watcher，也不会自动重生成知识包、Skill 或 Agent。
