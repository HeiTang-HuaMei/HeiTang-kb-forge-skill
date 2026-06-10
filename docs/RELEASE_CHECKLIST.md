# Release Checklist

Current project version: `4.1.1`

Current stable release: `v4.1.1`

Current stage: v4.1.1 Test Framework Governance stable release closure after v4.1.0 P2.1 Parser/OCR Workbench evidence sync; v4.0.0 and v4.1.0 remain untouched historical stable tags.

## Required Checks

- [x] Version aligned in `pyproject.toml`, `skill.json`, README, Capability Status, Version Matrix, and Release Checklist
- [x] v4.1.1 is documented as the P2.2 Entry Gate / Test Governance Stable Baseline, not as part of P2.2
- [x] P2.2 remains blocked until Core/UI release-truth closure, Core/UI CI green, Core/UI Release Check green, v4.1.1 tag / GitHub Release, and Workspace handoff/status sync are complete
- [x] v4.1.1 scope is limited to test governance, release governance, and validation cost control; no P2.2 business capability is included
- [x] P1 Final Gate, External Project Registry, S/A Contract Inclusion, rc.1 acceptance, and release hardening evidence remain attached
- [x] Parser backend matrix fixture and Flutter asset are copied from Core runtime baseline commit `576a62075dc1ecbe00388bb0569fd1fc767be7cb`
- [x] Workbench displays parser/OCR evidence, install mode, stable surface, known limitations, and no runtime execution claim
- [x] Test Framework Governance artifacts added: [Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json), [Test Pruning Register](testing/TEST_PRUNING_REGISTER.md), pytest markers, and `heitang_kb_forge.test_governance.gates`
- [x] v4.1.1 stable release closure is backed by Chunked Full Gate, Post-Codex Full Review, CI, Release Check, tag, and GitHub Release evidence
- [ ] Before any validation phase, load [Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json), generate a changed-file impact map, select Fast / Medium / Full Gate, run only impacted tests during development, run Medium Gate at phase closure, run Chunked Full Gate before tag/release, preserve logs for long-running gates, and never report skipped/deferred tests as passed
- [x] Post-Codex Full Review completed before tag/release with P0=0, P1=0, and P2 fixed or explicitly deferred; P3 backlog does not block release
- [x] `python -m pytest` passed through the v4.1.1 UI Chunked Full Gate
- [ ] Doctor command `python -m heitang_kb_forge.cli doctor --output ./tmp_doctor` passed
- [ ] Quickstart build passed
- [ ] Quickstart output contains `manifest.json`, `chunks.jsonl`, and `quality_report.json`
- [ ] Quality gate generated
- [ ] Release blockers generated
- [ ] Regression check generated
- [ ] Golden samples checked
- [ ] Export certification generated
- [ ] Compatibility matrix generated
- [x] Release readiness generated and checked in release-check workflow
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
- Do not claim parser/OCR runtimes execute from static Workbench.
- Do not claim Unstructured PDF/DOCX/image support as stable in v4.1.0; stable surface is `.md/.txt`.
- Do not bundle Docling, PaddleOCR, or Unstructured as default dependencies.
- Do not use Post-Codex Review Gate as an infinite scope expansion loop; only P0/P1/P2 can block release.

## Release Readiness Gate

`release-readiness` must return `release_ready=false` when version mismatch, critical blockers, missing Capability Status, missing Version Matrix, missing Release Checklist, README planned-as-completed claims, suspected secrets, missing mock boundaries, missing quickstart outputs, or doctor failures are detected.

