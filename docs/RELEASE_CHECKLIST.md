# Release Checklist

Current Core package version: `4.1.1`
Current stable release: `v4.1.1`
Previous stable release: `v4.1.0`

Current stage: v4.1.1 Test Framework Governance stable release closure after v4.1.0 Parser/OCR industrial hardening.

## Required Checks

- [x] Version aligned in `pyproject.toml`, `skill.json`, README, Capability Status, Version Matrix, and Release Checklist
- [x] P1 Final Gate, External Project Registry, and S/A Contract Inclusion evidence remain attached
- [x] rc.1 acceptance and hardening evidence passed
- [x] P2.1 parser/OCR backend evidence indexed under `docs/audits/p2_1_parser_ocr_backends/`
- [x] Docling, PaddleOCR, and Unstructured represented as optional dependency-gated runtime adapters
- [x] Unstructured stable surface documented as `.md/.txt`
- [x] Builtin parser fallback preserved
- [x] Test Framework Governance artifacts added: [Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json), [Test Pruning Register](testing/TEST_PRUNING_REGISTER.md), pytest markers, and `heitang_kb_forge.test_governance.gates`
- [x] v4.1.1 stable release closure is backed by Chunked Full Gate, Post-Codex Full Review, CI, Release Check, tag, and GitHub Release evidence
- [ ] Before any validation phase, read [Validation Strategy](testing/VALIDATION_STRATEGY.md), load [Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json), generate a changed-file impact map, select Fast / Medium / Full Gate, run only impacted tests during development, run Medium Gate at phase closure, run Chunked Full Gate before tag/release, preserve logs for long-running gates, and never report skipped/deferred tests as passed
- [x] Post-Codex Full Review completed before tag/release with P0=0, P1=0, and P2 fixed or explicitly deferred; P3 backlog does not block release
- [x] `python -m pytest` passed through the v4.1.1 Chunked Full Gate before tag/release
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
- [x] Release readiness explicitly checked for `release_ready=true` in release-check workflow
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
- Do not claim Docling, PaddleOCR, or Unstructured are bundled by default; v4.1.1 preserves the v4.1.0 optional dependency-gated boundary.
- Do not claim Unstructured PDF/DOCX/image support is stable in v4.1.1; the stable surface is `.md/.txt`.
- Do not display static Workbench runtime execution controls for heavy parser/OCR adapters unless backed by a Core executable contract.
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
- Do not use Post-Codex Review Gate as an infinite scope expansion loop; only P0/P1/P2 can block release.

## Release Readiness Gate

`release-readiness` must return `release_ready=false` when version mismatch, critical blockers, missing Capability Status, missing Version Matrix, missing Release Checklist, README planned-as-completed claims, suspected secrets, missing mock boundaries, missing quickstart outputs, or doctor failures are detected.
