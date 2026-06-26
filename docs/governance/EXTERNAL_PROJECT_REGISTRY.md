# External Project Registry Policy

External projects are governed by value to the v3 product chain.

## Registry Classes

- `capability_provider`: enhances parser, OCR, embedding, vector, search, export, Agent memory/tool, A2A export, or quality gates.
- `template_asset`: prompt, method, writing, Skill, Agent, or document template asset.
- `architecture_reference`: architecture source that must be absorbed, rejected, or deferred with a blocker.

## Classification Categories

Every external project must first be classified. Do not treat every external project as a generic capability source.

- `real_integration`: connect the project or library as a real HeiTang adapter, connector, runtime dependency, or built-in tool after dependency, license, local deployment, fallback, and blackbox acceptance checks.
- `absorb`: do not connect code or dependencies; extract a design pattern, data structure, workflow, or validation idea and implement it natively in HeiTang.
- `learn`: learn engineering practice, benchmark method, task governance, or sample organization without adding product runtime.
- `reference`: use as product, UX, market, or concept reference only; do not put it into implementation queues.
- `reject`: explicitly do not adopt; keep the rejection reason so the idea does not keep re-entering the queue.

## Architecture Reference Status

- `candidate_reference`
- `absorbed_into_architecture`
- `rejected_no_architecture_gain`
- `deferred_with_blocker`

## Rules

- Worthwhile references must result in contract, schema, runtime boundary, UI information architecture, test gate, audit model, fallback, Provider classification, or loading-rule improvements.
- Non-useful references must be rejected with a reason.
- Deferred references require a concrete blocker and exit condition.
- Only `real_integration` entries may become runtime dependencies.
- `absorb`, `learn`, and `reference` entries must be folded into existing HeiTang modules instead of creating separate product modules named after the external project.
- Ordinary users should not see external project names as product modules.
- Governance docs may list external project status; product UI should expose natural capability improvements.
- Every non-rejected project must bind to existing capability gates, or be marked `deferred_with_blocker` with the blocker and Owner confirmation need recorded.
- P0/P1/P2 queue binding is registry/status mapping only; it must not complete any P0/P1/P2 gate or change the stage chain.
- Closed P0, P1, or already-run P2 gates may be named only as historical fit, regression, or reference context; they must not receive retrospective evidence, acceptance write-back, or active bindings after closure.
- At any P2 chain position, only P2 gates still present in `remaining_gates`, `P2 Release Gate` regression, or a later Owner-approved capability may accept fresh external-project absorption evidence.
- If no existing gate can own the external project, do not add a new main Gate automatically; mark `deferred_with_blocker` and request Owner confirmation for any new capability row.
- Stage chain must remain P0 -> P0 Release Gate -> P1 -> P1 Release Gate -> P2 -> P2 Release Gate -> Final Owner Review.
