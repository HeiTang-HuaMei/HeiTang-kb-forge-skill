# Campaign 7 Configuration System Degraded Mode Matrix

Date: 2026-06-17

Matrix status: pass

| Condition | Runtime status | User-facing handling | Rollback |
| --- | --- | --- | --- |
| missing_env_secret | blocked | Prompt env/secret-store setup; never echo plaintext. | no |
| invalid_schema | blocked | Show field-specific validation error and repair suggestion. | no |
| migration_incompatible | blocked | Keep previous profile active and write migration diagnostics. | yes |
| rollback_restore | degraded | Restore last valid snapshot and preserve audit log. | yes |
| provider_unavailable | degraded | Keep local capabilities available and mark provider unavailable. | no |
| tool_adapter_disabled | disabled_boundary | Do not execute disabled or unregistered adapters. | no |
| workspace_unavailable | blocked | Require workspace path repair before writing artifacts. | no |

## Security Boundary

| Check | Result |
| --- | --- |
| no plaintext secret | pass |
| secret env names only | pass |
| UI secret masked | pass |
| no arbitrary shell | pass |
| Computer Use disabled | pass |
| no Provider Runtime rewrite | pass |
| no Agent Runtime rewrite | pass |
| diagnostics contain no secret | pass |

## Repair Strategy

Campaign 7 repair guidance is emitted through diagnostics and degraded matrix outputs. Invalid or unsafe config is blocked before acceptance. Rollback uses versioned snapshot restore, preserving audit evidence and restoring the last valid resolved profile.
