# Workspace Boundary Bridge Handoff Contract

Status: `handoff_contract_ready`

This is a Campaign 5 handoff contract only. It does not add current Bridge
allowlist actions and does not accept Bridge execution.

Future candidates:

- `validate-workspace-boundary`: registered_in_current_allowlist = `False`
- `register-workspace-asset`: registered_in_current_allowlist = `False`
- `resolve-kb-access-scope`: registered_in_current_allowlist = `False`

Forbidden behavior: arbitrary shell execution, open-any-path, absolute escape,
parent-directory escape, implicit cross-workspace read, and enabling future
actions before Campaign 5.
