# Model Gateway and Provider Policy

Model Gateway and Provider configuration are shared infrastructure, not Agent-only features.

## Applies To

- document generation,
- Skill Factory,
- Agent Workspace,
- A2A collaboration,
- retrieval verification when external search or evaluation is configured,
- embedding and vector index flows.

## Provider Readiness Levels

- `reference_only`: registered for governance only; not user-selectable.
- `readiness_only`: adapter contract or local evidence exists; runtime is not loaded.
- `needs_verification`: may be useful but lacks enough evidence.
- `configurable_provider`: configuration, health check, fallback, audit, and rollback evidence exist.
- `runtime_loaded`: allowed only when the runtime has real evidence and the boundary is explicit.

## Required Evidence For User Selection

- config schema,
- health or readiness test,
- masked secret handling,
- failure degradation,
- audit record,
- rollback path,
- downstream binding evidence.

## Prohibited Claims

- Do not call a health check workflow execution.
- Do not call a template asset a runtime Provider.
- Do not call a test-only model route a release Provider.
- Do not expose external project names as normal user modules.
