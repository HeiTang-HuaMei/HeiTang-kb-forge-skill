# Human Interrupt Only Policy

Routine confirmation is not a valid pause reason for the active goal. Human interruption is allowed only when execution cannot safely or truthfully continue.

## Allowed Pause Conditions

Pause and report only when:

1. A real account, API key, password, token, verification code, signing credential, or other user-held credential is missing.
2. Payment is required and no approved payment method or budget authorization is available.
3. An external service explicitly refuses, rate-limits, or remains unavailable after the bounded retry policy is exhausted.
4. The required operation is outside the current project, workspace, or local-machine authorization boundary.
5. Continuing creates a clear legal, security, privacy, or license risk with irreversible external consequences.
6. No rollback plan can be produced and the action could damage a non-project directory, unrelated user data, or real production data.
7. A platform-enforced control requires a user approval interaction that project policy cannot bypass.

## Not Valid Pause Conditions

Do not pause for:

- reasonable goal-serving scope expansion
- project dependency installation
- system dependency installation after checkpoint and rollback planning
- dependency remediation
- real adapter smoke
- local packaging
- Full Gate or Full Review when allowed by the active task
- project cleanup with a rollback plan
- UI refactoring
- Core Bridge extension with the high-risk action protocol
- bounded retry, checkpoint, recovery, or sub-agent cleanup
- an ordinary push, tag, or release permission question after its task-specific acceptance condition is satisfied

## Required Pause Report

When a valid pause condition occurs, record:

- `pause_reason`
- `failed_or_blocked_action`
- `checkpoint_path`
- `rollback_plan`
- `retry_count`
- `external_response` when applicable
- `credential_or_authorization_needed` when applicable
- `safe_resume_step`

Do not label a dependency as finally blocked before an allowed remediation attempt has been made and recorded.
