# v3.8 External Benchmark Absorption Map

`v38_external_absorption_map.json` is mandatory for v3.8 completion. It turns v3.6 benchmark work into an auditable implementation map for every v3.8 capability.

The map covers multi-query recall, candidate merge/dedup, deterministic rerank, evidence selection, retrieval diagnostics, explainable refusal, golden query evaluation, claim extraction, local verification retrieval, source cross-check, contradiction detection, freshness verification, knowledge accuracy scoring, and verification retrieval trace.

Rules:

- External projects are used for architecture patterns only.
- No external code, prompts, or datasets are copied.
- No risky dependency is added for v3.8.
- Tests require no network and no real LLM/API.
- v3.9 storage/PDF/parser work and v3.10 Agent Runtime remain out of scope.
