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
