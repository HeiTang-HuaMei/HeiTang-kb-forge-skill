# Release Checklist

Current project version: `2.5.1-alpha.1`

## Required Checks

- [ ] Version aligned in `pyproject.toml`, `skill.json`, README, Capability Status, Version Matrix, and Release Checklist
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

## Boundaries

- Do not claim real LLM API support until v2.6 live smoke passes.
- Do not claim official Xiaohongshu upload API support.
- Do not claim real OpenClaw / Codex / Claude Code / MCP runtime execution.
- Do not claim Feishu / mobile / installer / iOS support before v2.9.
- Do not claim SaaS / permissions before v3.x.

## Release Readiness Gate

`release-readiness` must return `release_ready=false` when version mismatch, critical blockers, missing Capability Status, missing Version Matrix, missing Release Checklist, README planned-as-completed claims, suspected secrets, missing mock boundaries, missing quickstart outputs, or doctor failures are detected.
