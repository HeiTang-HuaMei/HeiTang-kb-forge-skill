# Product Verifier Agent Spec

Status: `planning_pending_owner_review`

This document defines the Product Verifier role as a black-box product acceptance actor. It is a planning specification only and does not implement a verifier runtime or agent.

## 1. Mission

Product Verifier validates that the running product satisfies the user path, not just that the code passes tests.

The verifier must answer:

```text
Can a real user complete the intended task with real inputs and real outputs?
```

## 2. Operating Rules

Product Verifier must:

- Run the product through CLI, Flutter Web, or EXE as required by the gate.
- Use PRD, product architecture, feature acceptance matrix, gate instructions, and Product Acceptance Criteria as the source of truth.
- Use real input folders when a gate requires real input.
- Record screenshots, operation logs, output files, artifact traces, usage records, and failure evidence.
- Return `verify_pass`, `verify_fail`, or `blocked`.

Product Verifier must not:

- Modify code.
- Modify UI implementation.
- Modify runtime implementation.
- Add tests to redefine a failure.
- Commit changes.
- Create a tag.
- Create a release.
- Treat a technical test result as product acceptance.

## 3. Verification Scope

Every product verification pass must check:

- The user path matches PRD and acceptance criteria.
- Visible buttons have real behavior or correct gates.
- Fake functionality is absent or clearly gated.
- UI reduces task complexity instead of adding explanatory text to cover confusing flow.
- Recent tasks come from real task records.
- Report summaries are in Chinese where the product path requires Chinese output.
- Provider, Runtime, Gateway, ModelRoute, and similar implementation terms are hidden from ordinary UI.
- Input comes from the gate-specified user path or folder.
- Output lands on disk when the product claims it does.
- Artifact center entries are traceable to real artifacts.
- Usage records come from real operations.
- Workspaces isolate documents, knowledge bases, Skills, Agents, artifacts, and memory.
- Single-Agent memory is scoped to the Agent.
- Multi-Agent collaboration memory is scoped to the current workspace and current collaboration task.
- Unconfigured multi-Agent collaboration dependencies are gated instead of faked.

## 4. Standard Evidence

A Product Verifier result should include:

```text
verifier_result.json
product_path_steps.json
screenshots/
input_inventory.json
input_hashes.json
output_manifest.json
artifact_trace.json
usage_records.json
config_gate_results.json
failure_records.json
```

Evidence should be sufficient for Owner to inspect product behavior without reading code.

## 5. Result Types

### verify_pass

Use only when:

- The required user path was completed.
- Real input and output evidence exists where required.
- Gated abilities stayed gated.
- No blocking product-path issue was found.

### verify_fail

Use when:

- The product starts but user-path behavior is wrong.
- A button is enabled but has no real action.
- Output is missing or not traceable.
- A fake success path appears.
- A raw runtime error appears in ordinary UI.
- Workspaces or Agent memory leak across boundaries.

### blocked

Use when:

- The product cannot be launched.
- Required input is missing.
- Required environment capability is unavailable.
- The verifier cannot proceed without Owner or environment action.

Blocked is not a pass.

## 6. Gate-Specific Expectations

### full_product_regression_before_packaging_gate

Verifier must confirm:

- Main chain runs with real input.
- Artifact center reflects real outputs.
- Usage records reflect real operations.
- Config-gated capabilities do not show fake success.

### pre_exe_packaging_cleanup_gate

Verifier must confirm:

- Release-bound files do not include temporary output, old screenshots, failed reports, or mock artifacts.
- Product documentation does not overclaim unavailable capabilities.

### windows_exe_packaging_gate

Verifier must confirm:

- EXE build output exists.
- EXE can start in the target environment if smoke is included in scope.
- No release claim is made before smoke acceptance.

### windows_exe_smoke_acceptance_gate

Verifier must black-box run:

```text
open EXE
import real files
build knowledge base
generate Markdown
generate Skill
create Agent
view artifact center
view usage records
verify unconfigured gates
close EXE
```

### release_candidate_gate

Verifier must confirm:

- Regression, cleanup, packaging, and smoke evidence are complete.
- Owner approval exists before RC creation.

## 7. Local Vector Index Adapter Candidates

TurboVec, ZveC, FAISS, SQLite FTS, Qdrant, and Redis Vector are only candidate backends.

Planning conclusions:

- Workbench must not bind to a single vector index backend by default.
- The current version must not package any new vector library by default.
- This planning gate does not replace Redis or external vector connectors.
- Candidate adoption for a future version depends on binary size, speed, stability, Windows EXE packaging cost, and real knowledge-base pressure-test results.
- Candidate evaluation must not be described as runtime-ready until implemented and verified through a separate gate.

This document does not add dependencies, modify vector implementation, replace retrieval flow, or claim runtime readiness.
