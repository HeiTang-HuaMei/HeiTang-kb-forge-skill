# Release Checklist

Current project version: `4.0.0`

Current stable release: `v4.0.0`

Current stage: v4.0.0 stable release after rc acceptance and hardening.

## Required Checks

- [x] Version aligned in `pyproject.toml`, `skill.json`, README, Capability Status, Version Matrix, and Release Checklist
- [x] P1 Final Gate, External Project Registry, S/A Contract Inclusion, rc.1 acceptance, and release hardening evidence remain attached
- [ ] `python -m pytest` passed
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

## Boundaries

- Do not claim default real LLM API calls; v2.6 live smoke is opt-in.
- Do not claim all providers were live-tested; v2.6 registry coverage is config governance plus Preview live smoke.
- Do not claim full runtime compatibility; v2.7 is a local offline demo / portfolio release.
- Do not claim official Xiaohongshu upload API support.
- Do not claim real OpenClaw / Codex / Claude Code / MCP runtime execution.
- Do not claim Feishu / mobile / installer / iOS support before v2.9.
- Do not claim SaaS / permissions before v3.x.

## Release Readiness Gate

`release-readiness` must return `release_ready=false` when version mismatch, critical blockers, missing Capability Status, missing Version Matrix, missing Release Checklist, README planned-as-completed claims, suspected secrets, missing mock boundaries, missing quickstart outputs, or doctor failures are detected.

