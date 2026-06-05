# Release Checklist

当前项目版本：`2.5.1-alpha.1`

## Required Checks

- [ ] `pyproject.toml`、`skill.json`、README、Capability Status、Version Matrix、Release Checklist 版本一致
- [ ] `python -m pytest` 通过
- [ ] Doctor 命令 `python -m heitang_kb_forge.cli doctor --output ./tmp_doctor` 通过
- [ ] Quickstart build 通过
- [ ] Quickstart 输出包含 `manifest.json`、`chunks.jsonl` 和 `quality_report.json`
- [ ] Quality gate 已生成
- [ ] Release blockers 已生成
- [ ] Regression check 已生成
- [ ] Golden samples 已检查
- [ ] Export certification 已生成
- [ ] Compatibility matrix 已生成
- [ ] Release readiness 已生成
- [ ] 未提交 tmp 输出目录
- [ ] 无 secret leak
- [ ] 默认不调用外部网络或平台
- [ ] README 能力声明已复核
- [ ] CHANGELOG 只记录真实已完成内容

## Boundaries

- v2.6 live smoke 通过前，不声明真实 LLM API 支持。
- 不声明小红书官方上传 API 支持。
- 不声明真实 OpenClaw / Codex / Claude Code / MCP runtime 执行。
- v2.9 前不声明飞书 / 移动端 / 安装端 / iOS 支持。
- v3.x 前不声明 SaaS / 权限系统。

## Release Readiness Gate

当检测到版本不一致、critical blockers、缺少 Capability Status、缺少 Version Matrix、缺少 Release Checklist、README 把 planned 写成 completed、疑似 secrets、缺少 mock boundary、quickstart 输出缺失或 doctor failed 时，`release-readiness` 必须返回 `release_ready=false`。
