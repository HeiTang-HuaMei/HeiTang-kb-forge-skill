# v2.7 Demo E2E

v2.7.0-alpha.1 adds a minimal local end-to-end demo / portfolio release workflow.

## Command

```powershell
python -m heitang_kb_forge.cli demo-e2e --output .\tmp_demo_e2e
```

## Workflow

The command runs the following offline workflow:

1. Build a knowledge package.
2. Run quality gate.
3. Run provider security audit.
4. Run mock LLM quality gate assist.
5. Export generic, Codex, and OpenClaw platform packages.
6. Run release readiness.
7. Generate a portfolio demo report.
8. Generate a demo evidence pack.

## Outputs

* `demo_e2e_result.json`
* `portfolio_demo_report.md`
* `demo_evidence_pack/`
* `runtime_limitations.md`

## Boundaries

The demo is offline and mock-first by default. It does not call live providers, start an MCP server, run OpenClaw or Codex runtimes, publish to Xiaohongshu, or implement full runtime compatibility.
