# Release Checklist

当前项目版本：`4.2.0`

当前 stable release：`v4.2.0`

当前阶段：v4.2.0 P2.2 Skill Factory industrial workflow release closure，位于 v4.1.1 P2.2 Entry Gate 之后；v4.0.0、v4.1.0、v4.1.1 均保持为未改动的历史 stable tag。

## Required Checks

- [x] `pyproject.toml`、`skill.json`、README、Capability Status、Version Matrix、Release Checklist 版本一致
- [x] v4.1.1 保留为 P2.2 Entry Gate / Test Governance Stable Baseline，不是 P2.2 UI 能力交付本身
- [x] v4.2.0 覆盖 P2.2 Skill Factory industrial UI closure：Knowledge Package、Evidence、Methodology、Candidates、Hierarchy、Skill Suite、Reports 和 Export evidence surfaces
- [x] P2.3 未启动，Web static Workbench 不执行本地 Core CLI
- [x] P1 Final Gate、External Project Registry、S/A Contract Inclusion、rc.1 acceptance 与 release hardening evidence 仍然完整
- [x] Parser backend matrix fixture 与 Flutter asset 已从 Core runtime baseline commit `576a62075dc1ecbe00388bb0569fd1fc767be7cb` 复制
- [x] Workbench 展示 parser/OCR evidence、安装模式、稳定表面、已知限制，并不声明 runtime execution
- [x] Test Framework Governance artifacts 已添加：[Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json)、[测试瘦身登记表](testing/TEST_PRUNING_REGISTER.zh-CN.md)、pytest markers 与 `heitang_kb_forge.test_governance.gates`
- [ ] v4.2.0 stable release closure 由新的 Chunked Full Gate、Post-Codex Full Review、CI、Release Check、tag 和 GitHub Release evidence 支撑
- [x] 任何 validation phase 前，加载 [Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json)，生成 changed-file impact map，选择 Fast / Medium / Full Gate，开发中只运行 impacted tests，phase closure 运行 Medium Gate，tag/release 前运行 Chunked Full Gate，长时间 gate 保存 logs，并且绝不把 skipped/deferred tests 汇报为 passed
- [x] tag/release 前完成 Post-Codex Full Review，且 P0=0、P1=0、P2 已修复或明确 deferred；P3 backlog 不阻塞 release
- [x] v4.2.0 UI Chunked Full Gate 的 `python -m pytest` 分段验证通过
- [ ] Doctor 命令 `python -m heitang_kb_forge.cli doctor --output ./tmp_doctor` 通过
- [ ] Quickstart build 通过
- [ ] Quickstart 输出包含 `manifest.json`、`chunks.jsonl` 和 `quality_report.json`
- [ ] Quality gate 已生成
- [ ] Release blockers 已生成
- [ ] Regression check 已生成
- [ ] Golden samples 已检查
- [ ] Export certification 已生成
- [ ] Compatibility matrix 已生成
- [x] Release readiness 已生成，并已在 release-check workflow 中检查
- [ ] 未提交 tmp 输出目录
- [ ] 无 secret leak
- [ ] 默认不调用外部网络或平台
- [ ] README 能力声明已复核
- [ ] CHANGELOG 只记录真实已完成内容
- [ ] 准备 v2.6 release evidence 时生成 Provider security audit
- [ ] Provider registry 已导出并校验
- [ ] Provider fallback、audit redaction、cost guard 已生成
- [ ] LLM live smoke 必须显式 opt-in 且不泄漏 API key
- [ ] Demo E2E 已生成 `demo_e2e_result.json`、`portfolio_demo_report.md`、`demo_evidence_pack/` 和 `runtime_limitations.md`

## Boundaries

- 不声明默认真实 LLM API 调用；v2.6 live smoke 是 opt-in。
- 不声明所有 Provider 都已 live-tested；v2.6 registry coverage 是 config governance + Preview live smoke。
- 不声明完整 runtime compatibility；v2.7 是本地离线 demo / portfolio release。
- 不声明小红书官方上传 API 支持。
- 不声明真实 OpenClaw / Codex / Claude Code / MCP runtime 执行。
- v2.9 前不声明飞书 / 移动端 / 安装端 / iOS 支持。
- v3.x 前不声明 SaaS / 权限系统。
- 不声明 static Workbench 可以执行 parser/OCR runtime。
- 不声明 Unstructured PDF/DOCX/image support 在 v4.1.0 已稳定；稳定表面仅 `.md/.txt`。
- 不把 Docling、PaddleOCR 或 Unstructured 打包为默认依赖。
- 不把 Post-Codex Review Gate 变成无限扩展范围的循环；只有 P0/P1/P2 可以阻塞 release。

## Release Readiness Gate

当检测到版本不一致、critical blockers、缺少 Capability Status、缺少 Version Matrix、缺少 Release Checklist、README 把 planned 写成 completed、疑似 secrets、缺少 mock boundary、quickstart 输出缺失或 doctor failed 时，`release-readiness` 必须返回 `release_ready=false`。

