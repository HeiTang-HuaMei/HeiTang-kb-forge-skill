# Release Checklist

当前 Core package 版本：`4.1.1`
当前 stable release：`v4.1.1`
上一个 stable release：`v4.1.0`

当前阶段：v4.1.1 Test Framework Governance stable release closure，位于 v4.1.0 Parser/OCR industrial hardening 之后。

## Required Checks

- [x] `pyproject.toml`、`skill.json`、README、Capability Status、Version Matrix、Release Checklist 版本一致
- [x] P1 Final Gate、External Project Registry 与 S/A Contract Inclusion evidence 仍然完整
- [x] rc.1 acceptance 与 hardening evidence 已通过
- [x] P2.1 parser/OCR backend evidence 已索引到 `docs/audits/p2_1_parser_ocr_backends/`
- [x] Docling、PaddleOCR、Unstructured 均表示为 optional dependency-gated runtime adapters
- [x] Unstructured stable surface 明确为 `.md/.txt`
- [x] Builtin parser fallback 保留
- [x] Test Framework Governance artifacts 已添加：[Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json)、[测试瘦身登记表](testing/TEST_PRUNING_REGISTER.zh-CN.md)、pytest markers 与 `heitang_kb_forge.test_governance.gates`
- [x] v4.1.1 stable release closure 已由 Chunked Full Gate、Post-Codex Full Review、CI、Release Check、tag 和 GitHub Release evidence 支撑
- [ ] 任何 validation phase 前，阅读 [验证策略](testing/VALIDATION_STRATEGY.zh-CN.md)，加载 [Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json)，生成 changed-file impact map，选择 Fast / Medium / Full Gate，开发中只运行 impacted tests，phase closure 运行 Medium Gate，tag/release 前运行 Chunked Full Gate，长时间 gate 保存 logs，并且绝不把 skipped/deferred tests 汇报为 passed
- [x] tag/release 前完成 Post-Codex Full Review，且 P0=0、P1=0、P2 已修复或明确 deferred；P3 backlog 不阻塞 release
- [x] v4.1.1 在 tag/release 前通过 Chunked Full Gate 的 `python -m pytest` 分段验证
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
- [x] release-check workflow 显式检查 `release_ready=true`
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
- [ ] 启用 parser backend 时已生成 `parser_backend_result.json`、`parse_quality_report.json`、`ocr_risk_report.json`、`manual_review_queue.jsonl`、`trusted_kb_gate.json` 和 `knowledge_reliability_report.json`
- [ ] 启用 knowledge runtime 时已生成 `kb_index.jsonl`、`kb_query_result.json`、`kb_citation_trace.json`、`kb_answer.md`、`retrieval_quality_report.json` 和 `rag_eval_baseline.jsonl`

## Boundaries

- 不声明默认真实 LLM API 调用；v2.6 live smoke 是 opt-in。
- 不声明所有 Provider 都已 live-tested；v2.6 registry coverage 是 config governance + Preview live smoke。
- 不声明完整 runtime compatibility；v2.7 是本地离线 demo / portfolio release。
- 不声明 parser backend 默认开启；v2.8 parser backend reliability 是 opt-in。
- 不声明 Docling 或 Marker 是必装依赖；v2.8 adapter 是可选本地集成。
- 不声明 Docling、PaddleOCR 或 Unstructured 默认打包；v4.1.1 保留 v4.1.0 optional dependency-gated 边界。
- 不声明 Unstructured PDF/DOCX/image support 在 v4.1.1 已稳定；stable surface 是 `.md/.txt`。
- 没有 Core executable contract 支撑时，不在 static Workbench 展示 heavy parser/OCR runtime execution controls。
- 未显式 `--allow-untrusted` 时，不把 draft parser-backed KB 导出为 Skill、Agent 或平台包。
- 不声明 Knowledge Runtime Loop 默认开启；v2.9 runtime 输出是 opt-in 且本地运行。
- 不声明 v2.9 会调用 LLM API、embedding API、向量库或外部 Agent runtime。
- 不声明小红书官方上传 API 支持。
- 不声明真实 OpenClaw / Codex / Claude Code / MCP runtime 执行。
- 不在后续客户端平台集成完成前声明飞书 / 移动端 / 安装端 / iOS 支持。
- v3.x 前不声明 SaaS / 权限系统。
- 不把 Post-Codex Review Gate 变成无限扩展范围的循环；只有 P0/P1/P2 可以阻塞 release。

## Release Readiness Gate

当检测到版本不一致、critical blockers、缺少 Capability Status、缺少 Version Matrix、缺少 Release Checklist、README 把 planned 写成 completed、疑似 secrets、缺少 mock boundary、quickstart 输出缺失或 doctor failed 时，`release-readiness` 必须返回 `release_ready=false`。
