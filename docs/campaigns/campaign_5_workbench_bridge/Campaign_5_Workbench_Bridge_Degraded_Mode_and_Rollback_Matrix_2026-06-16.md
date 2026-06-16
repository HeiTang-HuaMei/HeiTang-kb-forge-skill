# Campaign 5 Workbench Bridge Degraded Mode and Rollback Matrix

Status: `campaign5_workbench_bridge_production_grade_accepted_ui_bound`

## Degraded Mode Matrix

| Failure mode | Bridge status | User-facing behavior | Recovery / rollback |
| --- | --- | --- | --- |
| `bridge_disabled_by_policy` | `blocked` | Local Core execution is disabled; read-only evidence remains visible. | Unset the disable switch only after Owner review. |
| `flutter_web_runtime` | `blocked` | Flutter Web is a preview and does not start local CLI processes. | Use the Windows desktop runtime for local execution. |
| `missing_core_cli` | `failed` | Core operation could not start; no command output is trusted. | Check installation path and retry with the same action id. |
| `timeout` | `failed` | The local action exceeded its configured timeout. | Use bounded retry or inspect partial logs. |
| `non_zero_exit` | `failed` | Core returned a sanitized failure reason and repair suggestion. | Use error repair guidance and retry if policy allows. |
| `cancelled` | `cancelled` | The user cancelled the current task. | Previous successful artifacts remain unchanged. |
| `output_path_rejected` | `blocked` | Output path is outside the configured workspace. | Choose a workspace-contained output target. |
| `secret_env_rejected` | `blocked` | Secret-like environment keys are not accepted by the UI bridge. | Configure provider secrets outside the Workbench Bridge. |
| `provider_or_vector_boundary` | `degraded` | Provider/vector actions remain disabled boundary while local KB/document actions continue. | Opt-in provider gates remain separate from Campaign 5. |

## Rollback / Disable Switch

| Switch | Effect | Evidence |
| --- | --- | --- |
| `bridge_disabled_by_policy` | All local Core execution affordances become blocked/read-only. | CoreActionPanel enabled=false returns desktop_support_disabled. |
| `web_local_cli_unsupported` | Flutter Web cannot execute local Core commands. | LocalCoreBridge capability rejects Web runtime. |
| `action_not_allowlisted` | Unknown actions are blocked before process start. | LocalCoreBridge rejects missing action ids. |
| `output_path_rejected` | Outputs outside the workspace are blocked before process start. | CoreOutputPathContract containment check. |
