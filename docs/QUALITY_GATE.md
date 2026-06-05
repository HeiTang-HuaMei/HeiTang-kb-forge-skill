# Quality Gate

v2.5 adds a local release quality gate for knowledge packages, Skill packages, Agent packages, workspaces, prompt profiles, LLM audit files, and platform exports.

It writes `quality_gate_result.json`, `quality_gate_report.md`, `quality_gate_scorecard.json`, and `quality_gate_findings.jsonl`.

This gate is rule-based and local. It does not call real LLM APIs, vector databases, OpenClaw, Codex, Claude Code, MCP, XHS, Feishu, or SaaS services.

