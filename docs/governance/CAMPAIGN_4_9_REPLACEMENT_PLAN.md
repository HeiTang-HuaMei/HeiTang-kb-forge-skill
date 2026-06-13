# Campaign 4-9 Replacement Plan v3.0

This governance plan registers the user-approved replacement definitions for future Campaigns 4 through 9. It does not start any future campaign, does not redesign UI, does not change the current Campaign 3 task state, and does not change the Bridge allowlist.

## Replacement Decision

The old future definitions are superseded:

| Campaign | Replacement definition | Current state |
| --- | --- | --- |
| Campaign 4 | Goal-Oriented Product UI Workbench | `not_allowed_yet` |
| Campaign 5 | Chain-Level Local Core Bridge | `not_allowed_yet` |
| Campaign 6 | Agent Runtime & Memory Platform | `not_allowed_yet` |
| Campaign 7 | Configuration System | `not_allowed_yet` |
| Campaign 8 | Full Testing / Full Review | `not_allowed_yet` |
| Campaign 9 | EXE Packaging | `not_allowed_yet` |
| Final Release | GitHub Release after Campaign 9 acceptance | `not_allowed_yet` |

Campaign 3 Supplement 4.0 remains `Knowledge-to-Skill-to-Agent Package & Product Handoff Contract` inside Campaign 3. It is not Campaign 4, Campaign 5, or Agent Runtime, and it must not be deleted, skipped, renamed as Campaign 4, or reduced back to a video-only or Skill-template-only scope.

## Activation Preconditions

Campaign 4 may not start until this exact chain passes:

```text
Campaign 3 Supplement 3.0 External Source Memory & Verification complete
-> Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate complete
-> Campaign 3 Supplement 4.0 Prework / Agent Stable Structure Prework complete
-> Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff complete
-> Campaign 3 Supplement 4.0 Acceptance Gate passed
-> Campaign 3 Final Consistency Gate passed
-> Campaign 1-3 Stage Test Gate passed
-> Campaign 1-3 Integrated Closure passed
-> Closure Pack generated
-> Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed
-> Repository push succeeded
-> Baseline Tag created
-> GitHub CI Green
-> Closure Checklist Green
-> Campaign 4 Entry Gate
```

The repository cleanup gate, baseline push, tag, and CI Green in this chain freeze the Campaign 1-3 functional baseline. They are not the final GitHub Release. Final Release must wait until Campaign 9 EXE acceptance.

Before CI/CL green and Closure Checklist green, all of the following are forbidden:

- entering Campaign 4
- entering Campaign 5
- entering Campaign 6
- entering Campaign 7
- entering Campaign 8
- entering Campaign 9
- entering Final Release
- adding TasteSkill as an active item
- adding Product Design Plugin as an active item
- UI redesign
- Bridge allowlist changes for future campaigns

The current locked Campaign 3 next item remains:

```text
Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator implementation
```

## Campaign 4: Goal-Oriented Product UI Workbench

Campaign 4 turns the lower-level capabilities into a goal-oriented product workbench for ordinary users. It is not Bridge completion, not Agent Runtime completion, not Redis/vector memory completion, not EXE packaging, and not final release.

It must organize the product line around:

```text
Workspace
-> Source Intake
-> Multi-Knowledge Base
-> External Source Verification
-> Skill Factory
-> External Skill Learning / Skill Composer
-> Agent Builder
-> Agent Runtime / Memory handoff display
-> Multi-Agent Workspace
-> Agent Output Verification
-> Export / Audit / Diagnostics
```

Top-level navigation must have no more than seven entries:

1. Workspace
2. Import Materials
3. Knowledge Base
4. Skill / Agent
5. Multi-Agent Workflow
6. Export / Audit
7. Settings / Diagnostics

Campaign 4 must expose task cards and product goals, not raw technical action lists. It must distinguish Agent Package readiness from Agent Runtime readiness, Memory Spec readiness from memory runtime readiness, and Multi-Agent Spec readiness from multi-agent executable runtime.

Forbidden Campaign 4 interpretations:

- Agent package spec is runtime ready
- Agent runtime is ready
- Multi-Agent spec is executable
- short-term or long-term memory runtime is ready
- reference-only Skill is executable
- draft Skill is published
- TasteSkill or Product Design Plugin is active base scope

## Campaign 5: Chain-Level Local Core Bridge

Campaign 5 safely connects Campaign 4 user tasks to local Core actions. Users see tasks, while the Bridge maps those tasks to allowlisted actions.

Required user task flows include:

- `import_to_kb_flow`
- `document_preflight_flow`
- `document_understanding_flow`
- `external_source_verification_flow`
- `knowledge_base_build_flow`
- `search_index_build_flow`
- `skill_generation_flow`
- `external_skill_learning_flow`
- `dedicated_skill_composition_flow`
- `agent_package_generation_flow`
- `agent_output_verification_flow`
- `backend_diagnostics_flow`
- `settings_diagnostics_flow`
- `export_handoff_flow`

Campaign 5 may connect only Agent Package layer actions such as `generate-agent`, `generate-bound-agent`, `validate-agent-package`, `export-agent-package`, and `verify-agent-output`. It must not connect Agent Runtime actions such as `run-agent-task`, `run-multi-agent-workflow`, `agent-memory-read`, `agent-memory-write`, or `agent-runtime-execute`; those belong to Campaign 6.

Bridge safety remains mandatory: allowlist only, input/output schema validation, path boundary, timeout, structured error, audit log, dry-run/smoke mode, and no arbitrary shell execution.

Forbidden Bridge actions include `shell`, `run-command`, `arbitrary-command`, `exec`, `powershell`, `bash`, `cmd`, `open-any-path`, and `install-any-package`.

## Campaign 6: Agent Runtime & Memory Platform

Campaign 6 makes Agent Packages runnable, auditable, memory-aware, and isolated.

It must support:

- `simple_single_agent_mode_runtime`
- `advanced_single_agent_mode_runtime`

It may support:

- `simple_multi_agent_mode_runtime`
- `advanced_multi_agent_mode_runtime`

If Multi-Agent Runtime is not fully implemented, the truthful status is:

```text
multi_agent_spec_ready = true
multi_agent_runtime_ready = false
multi_agent_executable = false
```

Required runtime capabilities include creating an agent runtime, loading an Agent Package, running an Agent with KB and Skill, enforcing tool permissions, writing run logs and audit traces, verifying output, and exporting run reports.

Memory semantics must include short-term, long-term, private agent, shared workflow, workspace, run, and audit memory. Redis is short-term/session/run-state infrastructure; Vector DB is long-term semantic memory. Missing Redis or Vector DB must degrade to local JSONL/SQLite or keyword/structured search fallback without crashing.

Agent A must not read Agent B private memory. Workspace A must not read Workspace B data. Shared multi-agent memory requires explicit authorization.

## Campaign 7: Configuration System

Campaign 7 makes API, proxy, DB, Redis, vector DB, workspace path, Agent runtime, Agent memory backend, multi-agent shared memory, and OpenCLI/external verification configurable, detectable, and diagnosable.

Defaults:

- LLM disabled
- SQLite default
- keyword / structured search default
- Redis optional but supported
- vector DB optional but supported
- Agent memory fallback enabled
- Agent runtime local/offline mode default
- OpenCLI optional but supported

Required checks include `check-api-proxy`, `check-db`, `check-redis`, `check-vector-db`, `check-agent-runtime`, `check-agent-memory-backend`, and `check-opencli`.

## Campaign 8: Full Testing / Full Review

Campaign 8 runs the full validation campaign after UI, Bridge, Agent Runtime, Memory, and configuration are complete.

It must cover Core Full Gate, UI Full Gate, backend smoke and missing-dependency tests, document and external-source tests, knowledge verification, Skill and external Skill learning tests, Agent Package tests, Agent runtime tests, Agent output verification tests, Agent memory isolation tests, multi-agent workflow tests, configuration tests, Bridge tests, export tests, packaging smoke, `git diff --check`, Release Check, and Full Review.

Focused tests, Fast Gate, scoped tests, or a single green command do not count as Campaign 8 acceptance.

## Campaign 9: EXE Packaging

Campaign 9 packages the Windows EXE for ordinary users.

Required deliverables include Windows EXE, installer, portable package, first-run setup, default workspace, default SQLite, dependency checker, backend diagnostics, config wizard, diagnostics report, default local config, user guide, install guide, and diagnostics guide.

EXE acceptance requires install/run smoke and must prove that a user can open the UI, create a workspace, import files, preflight, check backends, run Document Understanding, build/search/verify KBs, generate and learn Skills, create and bind Agents, run a basic Agent task, verify Agent output, inspect run logs, configure API/proxy/DB/Redis/vector DB/OpenCLI, diagnose Agent memory backend, and export reports, Agent packages, and workspace packages.

Redis, Vector DB, LLM, and OpenCLI missing states must not crash. They must display degraded, optional, or not configured states and keep the baseline product usable.

## Final Release

Final Release may start only after Campaign 9 acceptance. If the Campaign 1-3 closure chain already produced a baseline tag, final release must use a new release tag and must not overwrite the baseline tag.

Final Release actions include final commit, push, tag, GitHub Release, Workspace status sync, HANDOFF sync, task_log sync, and global pitfall log sync.

## Current Registration Boundary

This file is a governance registration artifact only. It does not:

- enter Campaign 4
- enter Campaign 5
- enter Campaign 6
- enter Campaign 7
- enter Campaign 8
- enter Campaign 9
- enter Final Release
- generate Campaign 4 product docs under `docs/product`
- generate Campaign 5 bridge contract docs under `docs/bridge`
- generate Campaign 6 runtime docs under `docs/agent_runtime`
- change UI navigation
- change Bridge allowlist
- add TasteSkill or Product Design Plugin to active scope
- change the current Campaign 3 next item
- mark any future campaign complete
