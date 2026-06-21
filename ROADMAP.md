# Roadmap

The roadmap is constrained by the v3 product baseline:

- `docs/current/CURRENT_PRODUCT_BASELINE.md`
- `docs/product/PRODUCT_ARCHITECTURE.md`
- `docs/product/PRD.md`
- `docs/product/FEATURE_ACCEPTANCE_MATRIX.md`

## Current Product Chain

```text
Document Library -> Knowledge Base -> Index Layer -> RAG -> Orchestration -> Document / Skill / Agent / A2A
```

## Current Engineering Focus

1. Keep Stage2 runtime evidence industrial and auditable.
2. Keep Stage3 Provider / Gateway / ModelRoute / Profile readiness, binding, rollback, and audit mechanisms stable.
3. Continue rc11 code cleanup in small behavior-preserving slices.
4. Keep GitHub governance aligned with product baseline, CI gates, external project registry, release policy, and Owner retest.

## Boundaries

- OKF belongs to the standard knowledge package candidate layer unless a future baseline explicitly changes it.
- A2A belongs under Agent Workspace.
- External projects are not automatically product modules.
- Provider enhancements must be configurable, testable, auditable, and rollback-safe before becoming user-selectable.
- Template assets enter Skill, Agent, or document template assets, not external runtime loading.
