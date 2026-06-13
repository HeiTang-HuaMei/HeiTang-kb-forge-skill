# Rollback Plan

Rollback is file-scoped: remove or revert heitang_kb_forge/business_scenario_templates, its CLI commands, tests/test_business_scenario_templates.py, and this run directory. Regenerate registry/governance state back to next item 5.8 if validation fails. No system state, external service, credentials, or runtime cache is modified by this action.
