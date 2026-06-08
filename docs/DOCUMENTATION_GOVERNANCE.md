# Documentation Governance

Main branch keeps current product documentation only.

## Policy

- GitHub readers should start from `README.md` and `docs/DOCS_INDEX.md`.
- Historical version details, old implementation notes, legacy drafts, and process roadmaps are available through git history and tags.
- Final gate evidence and the latest Core P0 proof remain committed.
- Local provider configs, API keys, raw local acceptance outputs, large private samples, and full chunk dumps must not be committed.

## Current Retained Entry Points

- `README.md`
- `README.zh-CN.md`
- `CHANGELOG.md`
- `docs/DOCS_INDEX.md`
- `docs/DOCS_INDEX.zh-CN.md`
- `docs/USER_MANUAL.md`
- `docs/USER_MANUAL.zh-CN.md`
- `docs/COMMAND_REFERENCE.md`
- `docs/COMMAND_REFERENCE.zh-CN.md`
- `docs/AGENT_INTEGRATION.md`
- `docs/AGENT_TOOL_INTERFACE_GUIDE.md`
- `docs/MCP_READINESS_GUIDE.md`
- `docs/ICON_GUIDELINES.md`
- `docs/OUTPUT_REPORT_GUIDE.md`
- `docs/OUTPUT_REPORT_GUIDE.zh-CN.md`
- `docs/GOLDEN_DEMO_GUIDE.md`
- `docs/GOLDEN_DEMO_GUIDE.zh-CN.md`
- `docs/VERSION_MATRIX.md`
- `docs/VERSION_MATRIX.zh-CN.md`
- `docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.md`
- `docs/FINAL_PRODUCT_ARCHITECTURE_TRUTH.zh-CN.md`
- `docs/ROADMAP.md`
- `docs/ROADMAP.zh-CN.md`
- `docs/RELEASE_NOTES.md`
- `docs/RELEASE_NOTES.zh-CN.md`
- `docs/00_overview/CURRENT_TRUTH.md`
- `docs/00_overview/CURRENT_TRUTH.zh-CN.md`
- `docs/00_overview/CAPABILITY_MATRIX.md`
- `docs/00_overview/CAPABILITY_MATRIX.zh-CN.md`
- `docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.md`
- `docs/03_core_capabilities/PARSER_BACKEND_STRATEGY.zh-CN.md`
- `docs/10_roadmap/P1_UI_CORE_PARITY.md`
- `docs/10_roadmap/P1_UI_CORE_PARITY.zh-CN.md`
- `docs/10_roadmap/P2_PRODUCTIZATION.md`
- `docs/10_roadmap/P2_PRODUCTIZATION.zh-CN.md`

## Root Evidence

The repository root keeps only current gate JSON files that are part of the final Core truth surface:

- `final_v4_rc_gate_report.json`
- `v4_rc_final_gate_report.json`
- `v310_external_absorption_map.json`
- `v38_external_absorption_map.json`
- `v39_external_absorption_map.json`
- `v312_external_absorption_map.json`

Latest P0 proof is retained under:

- `docs/audits/local_acceptance/pre_v4_p0_after_live_llm/`

## No Longer Kept As Main Docs

- old `V*` version process notes
- old implementation plans and checkpoints
- legacy draft roadmaps
- duplicated capability descriptions covered by current entry docs
- root-level historical audit/report markdown and JSON files not required by the current final gate or current tests
