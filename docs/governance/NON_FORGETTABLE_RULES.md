# Non-Forgettable Rules

These rules must be read before continuing HeiTang KB Forge target-mode implementation. They are project-local mirrors of WorkSpace rules and past pitfalls.

## Full Access Execution

The current goal is authorized for Full Access Execution inside the project and WorkSpace boundary. Do not repeatedly ask whether allowed project-scope installs, remediation, tests, packaging steps, retries, checkpointing, or sub-agent lifecycle actions may proceed. High-risk actions still require checkpoint, rollback plan, action report, and recovery behavior.

## Dependency Remediation

Dependency remediation is allowed. Missing dependencies, missing Java, missing Python packages, missing parser binaries, or missing model assets cannot be treated as final blockers until remediation has been attempted and recorded. Reports must include install command, source, version, path, risk, rollback plan, post-check, and smoke evidence.

## Retry / Recovery

Network interruptions, request limits, long-running tasks, and failed commands require checkpoint plus bounded retry. Recovery evidence must identify the last successful command, last failed command, active artifacts, and next safe continuation point. No infinite retry loops.

## Sub-Agent Lifecycle

Sub-agents must be registered, concurrency-limited, consolidated, closed, and archived. Sub-agent output is advisory until the main agent verifies evidence and updates project artifacts. Idle or blocked sub-agents must not accumulate.

## Goal Drift Control

Do not treat partial slices, Fast Gate, UI actions, contract-only work, fixture-only results, structured skipped results, or a single command with exit code 0 as final completion. The final target remains the local executable Agent knowledge supply-chain workbench with verified KBs, Skills, Agent binding, multi-Agent workflow, external evidence verification, UI workflow, and EXE delivery.

## Document Output Governance

Rules may live in `docs/governance`, but runtime evidence must not endlessly sprawl under `docs/audits`. New ordinary run evidence should use `artifacts/audits/latest/<run_id>/run_manifest.json` and `run_summary.md`, then be indexed through `docs/audits/AUDIT_MANIFEST.json` only when promoted. Retention and `keep_in_git` must be explicit.

## Runtime Cache Policy

Model, parser, OCR, adapter, embedding, vector, and browser/build caches must not silently write to C drive system paths. Cache locations must be project-local or WorkSpace-local, configurable, diagnosable, and recorded in remediation or runtime reports.

## Progress Events

Tasks longer than 3 seconds need visible status. Tasks longer than 30 seconds need progress events, log path, and recovery strategy. Long DU, KB build, package build, dependency remediation, packaging, and UI workflow actions must expose progress to Core/UI surfaces.

## Pitfall Prevention

Pitfalls must become prevention mechanisms. A repeated or high-impact pitfall must update `D:\HeiTang-Codex-WorkSpace\01_全局复利与踩坑日志.md`, project rules, and at least one test, Gate, checklist, or manifest. Recording the pitfall without a prevention hook does not count as resolved.

## Project Memory Lock

Before business implementation resumes, confirm the Pre-Run Checklist in `PROJECT_CONTROL_INDEX.md`. If project-local rules conflict with obsolete historical MVP text, this target-mode memory lock wins.

## External Source Safety

Campaign 3 Supplement 3.0 is planned after Campaign 3 Supplement 2.0, not active now. External-source work must remain user-triggered and traceable. Do not bypass login, CAPTCHA, paywalls, or platform controls; do not import, save, or upload cookies; do not implement an unlimited crawler or high-frequency platform collection. Authorized browser reading is limited to content currently visible to the user and must be revocable.

## Campaign 3 Supplement 4.0 And Closure Chain

Campaign 3 Supplement 4.0 is Knowledge-to-Skill-to-Agent Package & Product Handoff Contract inside Section 5 / Campaign 3. It is not Campaign 4. Future Campaigns 4-9 are governed by `CAMPAIGN_4_9_REPLACEMENT_PLAN.md`: Campaign 4 Goal-Oriented Product UI Workbench, Campaign 5 Chain-Level Local Core Bridge, Campaign 6 Agent Runtime & Memory Platform, Campaign 7 Configuration System, Campaign 8 Full Testing / Full Review, and Campaign 9 EXE Packaging. After Supplement 3.0 acceptance, stop and run the Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate only; do not run Campaign 1-3 total closure directly. Supplement 4.0 starts only after the Pre-4.0 gate passes. Campaign 4 stays blocked until Pre-4.0, Supplement 4.0, Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, baseline tag, CI/CL green verification, and Closure Checklist green all pass. Before CI/CL green, do not enter Campaigns 4-9, add TasteSkill/Product Design Plugin as active scope, redesign UI, or change future Campaign Bridge allowlists.

## Product Output Surface And External Trend Alignment

HeiTang Knowledge Workbench has four distinct product output surfaces: `knowledge_package`, `document_outputs`, `skill_outputs`, and `agent_creation_package`. `document_outputs` are formal product outputs, not audit-report side effects and not covered by Skill Outputs; they include Markdown, DOCX / Word, PDF, and PPTX / PowerPoint through existing `generate-documents`. andrej-karpathy-skills, Presenton, CodeGraph, Understand Anything, NVlabs/LongLive, claude-plugins-official, and pi-mono are future/reference only unless a later ordered gate explicitly integrates them; do not add runtime dependencies, npm installs, GPU/runtime integration, or MCP/plugin execution for this guard.
