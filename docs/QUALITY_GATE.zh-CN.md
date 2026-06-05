# Quality Gate

v2.5 新增本地发布质量门禁，用于检查知识包、Skill 包、Agent 包、workspace、prompt profiles、LLM audit 文件和平台导出包。

输出 `quality_gate_result.json`、`quality_gate_report.md`、`quality_gate_scorecard.json` 和 `quality_gate_findings.jsonl`。

该门禁是本地规则检查，不调用真实 LLM API、向量数据库、OpenClaw、Codex、Claude Code、MCP、小红书、飞书或 SaaS 服务。

