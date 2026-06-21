# Current Product Baseline

Current product truth is defined by the dated v3 baseline:

- [PRODUCT_ARCHITECTURE_V3_2026-06-19.md](../product/PRODUCT_ARCHITECTURE_V3_2026-06-19.md)
- [PRD_V3_2026-06-19.md](../product/PRD_V3_2026-06-19.md)
- [FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md](../product/FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md)

Stable GitHub policy aliases:

- [PRODUCT_ARCHITECTURE.md](../product/PRODUCT_ARCHITECTURE.md)
- [PRD.md](../product/PRD.md)
- [FEATURE_ACCEPTANCE_MATRIX.md](../product/FEATURE_ACCEPTANCE_MATRIX.md)

## Product Chain

```text
Document Library -> Knowledge Base -> Index Layer -> RAG -> Orchestration -> Document / Skill / Agent / A2A
```

Chinese canonical chain:

```text
文档库 → 知识库 → 索引层 → RAG → 编排层 → 文档/Skill/Agent/A2A
```

## Current Boundary

Stage3 completion means Provider / Gateway / ModelRoute / Profile / readiness / binding / rollback / audit mechanisms are established enough for product code governance.

It does not mean all registered external runtimes are integrated. External projects remain governed as:

- capability Provider candidates with evidence,
- template assets,
- architecture references absorbed into product contracts,
- rejected references with no architecture gain,
- deferred references with explicit blockers.
