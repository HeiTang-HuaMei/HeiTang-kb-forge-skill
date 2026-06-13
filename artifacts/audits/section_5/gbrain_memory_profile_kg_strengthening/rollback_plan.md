# Rollback Plan

Rollback is file-scoped:

1. Remove `heitang_kb_forge/gbrain_strengthening/`.
2. Remove `tests/test_gbrain_strengthening.py` and `tests/test_gbrain_integration_decision.py`.
3. Remove the GBrain CLI commands from `heitang_kb_forge/cli_runtime.py`.
4. Remove this evidence directory from `artifacts/audits/section_5/`.
5. Revert the GBrain entries in governance docs, audit index/manifest, and validation gate manifest.

No external dependency, runtime, database, MCP server, registry, or global system state was installed or modified.
