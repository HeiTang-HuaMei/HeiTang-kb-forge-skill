# v2.7 Demo E2E

v2.7.0-alpha.1 新增最小本地端到端 demo / portfolio release 工作流。

## 命令

```powershell
python -m heitang_kb_forge.cli demo-e2e --output .\tmp_demo_e2e
```

## 工作流

该命令会运行以下离线流程：

1. 构建知识包。
2. 运行 quality gate。
3. 运行 provider security audit。
4. 运行 mock LLM quality gate assist。
5. 导出 generic、Codex、OpenClaw 平台包。
6. 运行 release readiness。
7. 生成 portfolio demo report。
8. 生成 demo evidence pack。

## 输出

* `demo_e2e_result.json`
* `portfolio_demo_report.md`
* `demo_evidence_pack/`
* `runtime_limitations.md`

## 边界

该 demo 默认离线、mock-first。它不调用 live provider，不启动 MCP server，不运行 OpenClaw 或 Codex runtime，不自动发布小红书，也不实现完整 runtime compatibility。
