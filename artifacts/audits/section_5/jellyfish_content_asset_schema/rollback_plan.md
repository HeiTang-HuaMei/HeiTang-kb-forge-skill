# Rollback Plan

If this 5.9 integration evidence must be reverted:

1. Remove the local `heitang_kb_forge/content_asset_schema/` module and `tests/test_content_asset_schema.py`.
2. Remove the two CLI commands: `build-content-asset-schema-library` and `validate-content-asset-schema-library`.
3. Restore the Jellyfish entry in `docs/roadmap/external_projects/external_project_registry.json` to its previous `mentioned_only` / `template_library` state.
4. Re-run `python -m heitang_kb_forge.cli external-capability-registry --output docs\audits\s_a_contract_inclusion` and re-copy the two UI external asset JSON files.
5. Remove `artifacts/audits/section_5/jellyfish_content_asset_schema/` from `docs/audits/AUDIT_MANIFEST.json` and `docs/audits/AUDIT_INDEX.md`.
6. Restore `PLAN_SEQUENCE_LOCK`, `TARGET_ACCEPTANCE_MATRIX`, `GOAL_ACCEPTANCE_LEDGER`, `current_status.md`, `HANDOFF.md`, and `task_log.md` to the 5.8-next-5.9 state.
7. Re-run the focused tests listed in `run_manifest.json`.

This rollback touches only current-project files and does not delete caches, dependencies, or unrelated user changes.
