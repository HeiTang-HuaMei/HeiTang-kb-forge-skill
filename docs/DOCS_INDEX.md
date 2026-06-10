# Docs Index

Current Core package version: `4.1.1`
Current release line: `v4.1.1`
Latest stable release: `v4.1.0`

This is the canonical documentation entry for the current main branch. Historical version details live in git history and tags, not as accumulated process docs on main.

## Start Here

- [README](../README.md)
- [Current Truth](CURRENT_TRUTH.md)
- [Capability Matrix](CAPABILITY_MATRIX.md)
- [AIGC Book Content Pipeline](AIGC_BOOK_CONTENT_PIPELINE.md)
- [GitHub Profile Copy](GITHUB_PROFILE_COPY.md)
- [Detailed Current Truth](00_overview/CURRENT_TRUTH.md)
- [Detailed Capability Matrix](00_overview/CAPABILITY_MATRIX.md)
- [Final Product Architecture Truth](FINAL_PRODUCT_ARCHITECTURE_TRUTH.md)
- [Documentation Governance](DOCUMENTATION_GOVERNANCE.md)

## Use The Core

- [User Manual](USER_MANUAL.md)
- [Command Reference](COMMAND_REFERENCE.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Version Matrix](VERSION_MATRIX.md)
- [Validation Strategy](testing/VALIDATION_STRATEGY.md)
- [Validation Gate Manifest](testing/VALIDATION_GATE_MANIFEST.json)
- [Test Pruning Register](testing/TEST_PRUNING_REGISTER.md)

## Core Capabilities

- [Parser Backend Strategy](03_core_capabilities/PARSER_BACKEND_STRATEGY.md)
- [P1 Workbench Contract Pack](03_core_capabilities/WORKBENCH_CONTRACT_PACK.md)
- [P1 Workbench Template Registry](03_core_capabilities/WORKBENCH_TEMPLATE_REGISTRY.md)

## Release State

- [Roadmap](ROADMAP.md)
- [Release Notes](RELEASE_NOTES.md)
- Current audit index: `audits/index.md`
- P2.1 parser/OCR backend evidence: `audits/p2_1_parser_ocr_backends/`
- Root gate: `../final_v4_rc_gate_report.json`
- Root gate alias: `../v4_rc_final_gate_report.json`
- Latest P0 proof: `audits/local_acceptance/pre_v4_p0_after_live_llm/`
- Latest P1 final gate re-run proof: `audits/p1_final_gate_rerun/`

## Roadmap Gates

- [P1 UI Core Parity](10_roadmap/P1_UI_CORE_PARITY.md)
- [P2 Productization](10_roadmap/P2_PRODUCTIZATION.md)
- [Pre-v4 External Project Registry](roadmap/external_projects/EXTERNAL_PROJECT_REGISTRY.md)
- [S/A External Contract Inclusion](roadmap/external_projects/S_A_CONTRACT_INCLUSION.md)
- [External Project Inclusion Policy](roadmap/external_projects/EXTERNAL_PROJECT_INCLUSION_POLICY.md)
- [Post-v4 External Roadmap](roadmap/external_projects/POST_V4_EXTERNAL_ROADMAP.md)

## Boundaries

LLM remains optional only; Core tests do not require real LLM/API/network calls. The existing `v4.0.0` and `v4.1.0` tags remain untouched, and `v4.1.1` is the current Test Framework Governance release after P2.1 hardening. Heavy parser/OCR dependencies remain optional and are not bundled by default.
