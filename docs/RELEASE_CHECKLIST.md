# Release Checklist

Current Core package version: `4.0.0`
Current stable release: `v4.0.0`

Current stage: v4.0.0 stable release after rc.1 acceptance and hardening.

## Required Checks

- [x] Version aligned in `pyproject.toml`, `skill.json`, README, Capability Status, Version Matrix, and Release Checklist
- [x] P1 Final Gate, External Project Registry, and S/A Contract Inclusion evidence remain attached
- [x] rc.1 acceptance and hardening evidence passed
- [ ] `python -m pytest` passed for stable v4.0.0
- [ ] Doctor command `python -m heitang_kb_forge.cli doctor --output ./tmp_doctor` passed
- [ ] Quickstart build passed
- [ ] Quickstart output contains `manifest.json`, `chunks.jsonl`, and `quality_report.json`
- [ ] Quality gate generated
- [ ] Release blockers generated
- [ ] Regression check generated
- [ ] Golden samples checked
- [ ] Export certification generated
- [ ] Compatibility matrix generated
- [ ] Release readiness generated
- [ ] Release readiness explicitly checked for `release_ready=true` in release-check workflow
- [ ] No tmp output directories committed
- [ ] No secret leak
- [ ] No default external network or platform call
- [ ] README claims reviewed
- [ ] CHANGELOG updated with real completed work only
- [ ] Provider security audit generated when preparing v2.6 release evidence
- [ ] Provider registry exported and validated
- [ ] Provider fallback, audit redaction, and cost guard generated
- [ ] LLM live smoke generated with explicit opt-in and no API key leakage
- [ ] Demo E2E generated `demo_e2e_result.json`, `portfolio_demo_report.md`, `demo_evidence_pack/`, and `runtime_limitations.md`
- [ ] Parser backend reliability generated `parser_backend_result.json`, `parse_quality_report.json`, `ocr_risk_report.json`, `manual_review_queue.jsonl`, `trusted_kb_gate.json`, and `knowledge_reliability_report.json` when parser backend mode is enabled
- [ ] Knowledge Runtime Loop generated `kb_index.jsonl`, `kb_query_result.json`, `kb_citation_trace.json`, `kb_answer.md`, `retrieval_quality_report.json`, and `rag_eval_baseline.jsonl` when knowledge runtime mode is enabled
- [ ] v3.12 product hardening generated diagnostics, command/package/workspace audits, privacy boundary, installer readiness, and v4 gate reports
- [ ] Final pre-v4 audit generated non-empty product proof, truth matrix, security/privacy, scale, docs truth, repository surface, and final v4 RC gate reports

## Boundaries

- Do not claim default real LLM API calls; v2.6 live smoke is opt-in.
- Do not claim all providers were live-tested; v2.6 registry coverage is config governance plus Preview live smoke.
- Do not claim full runtime compatibility; v2.7 is a local offline demo / portfolio release.
- Do not claim parser backend mode is enabled by default; v2.8 parser backend reliability is opt-in.
- Do not claim Docling or Marker are mandatory dependencies; v2.8 adapters are optional local integrations.
- Do not export draft parser-backed KBs to Skill, Agent, or platform packages unless `--allow-untrusted` is explicit.
- Do not claim Knowledge Runtime Loop is enabled by default; v2.9 runtime outputs are opt-in and local.
- Do not claim v2.9 calls LLM APIs, embedding APIs, vector databases, or external Agent runtimes.
- Do not claim v4.0.0 is published without a tag and release-check evidence.
- Do not claim BYO cloud/database is implemented while it remains future/optional.
- Do not claim platform-hosted user data, SaaS, or multi-user permissions are implemented.
- Do not claim official Xiaohongshu upload API support.
- Do not claim real OpenClaw / Codex / Claude Code / MCP runtime execution.
- Do not claim Feishu / mobile / installer / iOS support before future client platform integrations are implemented.
- Do not claim SaaS / permissions before v3.x.

## Release Readiness Gate

`release-readiness` must return `release_ready=false` when version mismatch, critical blockers, missing Capability Status, missing Version Matrix, missing Release Checklist, README planned-as-completed claims, suspected secrets, missing mock boundaries, missing quickstart outputs, or doctor failures are detected.

