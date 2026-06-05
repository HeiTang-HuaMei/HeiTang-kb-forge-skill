# Version Traceability

## v1.6 Responsibility

v1.6 is responsible for:

- progress and large-file/OCR performance baseline
- multimodal knowledge assets
- multimodal evidence map
- Knowledge Package Contract v2
- contract checker
- Knowledge Package Builder UI v1
- bilingual v1.6 documentation
- v1.6 validation tests

## Trace Future Issues To v1.6

Start with v1.6 when investigating:

- large-file progress issues
- OCR cache / resume issues
- missing multimodal assets
- invalid `multimodal_evidence_map.json`
- unstable manifest v2 fields
- unstable evidence v2 fields
- incorrect contract checker decisions

## Boundary

v1.6 does not add Evidence Gate, high-precision retrieval index, Skill generation, Agent Runtime, Tool Runtime, or external connectors.
# v1.7 Traceability

v1.7 introduces governance, retrieval, evidence gate, and LLM evidence validation outputs. These files are opt-in and do not change the default offline package contract.

# v1.8 Traceability

v1.8 owns Skill Package generation, Skill Validation, Agent Package generation, and optional LLM-assisted Skill / Agent file generation. Issues in `SKILL.md`, `skill_manifest.yaml`, rule files, `soul.md`, `system_prompt.md`, or launch checklist generation should be traced to v1.8.

# v1.9 Traceability

v1.9 owns workspace initialization, package/skill/agent registries, relationship graph, provider registry, prompt profile registry, LLM call audit, workspace import/export, and workspace health check.

# v2.0 Traceability

v2.0 owns the stable Agent knowledge supply-chain foundation: `studio-run`, `stable-check`, stable contracts, `provider-health`, reliability scoring, release package snapshots, extension readiness, Studio v2 summaries, and stable bilingual documentation.

Master Skill decomposition learning is reserved for v2.2. Platform export and upload adapters are reserved for v2.4.

# v2.1 Traceability

v2.1 owns input coverage, parser hardening, enhanced source inventory, knowledge quality scoring, review workflow, curated chunks, retrieval evaluation, evidence benchmark, and optional LLM quality assist fallback.

# v2.2 Traceability

v2.2 owns master Skill import, Skill decomposition, profile extraction, derived Skill generation, Skill safety checks, Skill similarity reports, and Skill license reports.

# v2.3 Traceability

v2.3 owns `batch_job_manifest.json`, `batch_item_status.jsonl`, batch retry records, batch summary reports, `package_version_graph.json`, `curated_package/`, `governance_decisions.jsonl`, `impacted_skills.json`, `impacted_agents.json`, and Batch & Governance Center summaries.

Investigate v2.3 first when batch item status, retry records, curation inclusion/exclusion, package lineage, or update impact outputs are wrong.

# v2.3 Checkpoint Fill Traceability

The checkpoint fill owns enhanced Skill template files, Agent compatibility stubs, workspace refresh reports, provider readiness reports, prompt profile versioning reports, `action_center.json`, `run_history.jsonl`, and `studio_v22_summary.json`.

v2.4 platform distribution remains planned and is not part of this checkpoint.
