# Release Checklist

Current project version: 2.5.0-alpha.1

Use this checklist before tagging any checkpoint.

## Required Checks

- [ ] Version aligned in pyproject.toml and skill.json
- [ ] pytest passed
- [ ] Quickstart build passed
- [ ] Doctor passed, if available
- [ ] Quality gate passed
- [ ] Release blockers checked
- [ ] Regression checked
- [ ] Golden samples checked
- [ ] Export certification checked
- [ ] Compatibility matrix generated
- [ ] Release readiness generated
- [ ] No tmp directories
- [ ] No secret leak
- [ ] No real external call by default
- [ ] README claims checked
- [ ] CHANGELOG updated
- [ ] Capability Status updated
- [ ] Version Matrix updated
- [ ] Tag planned

## Required Boundaries

- Do not claim real LLM API support unless live smoke has passed.
- Do not claim official Xiaohongshu upload API support.
- Do not claim real OpenClaw / Codex / Claude Code / MCP runtime execution.
- Do not claim Feishu / mobile / installer / iOS support before v2.9 implementation.
- Do not claim SaaS / permission system support before v3.x implementation.

## Release Readiness Gate

Release readiness must return `release_ready=false` when:

- project versions are inconsistent
- critical release blockers exist
- Capability Status is missing
- Version Matrix is missing
- Release Checklist is missing
- README claims planned capabilities as completed
- suspected secrets are detected
- platform export lacks mock boundary
