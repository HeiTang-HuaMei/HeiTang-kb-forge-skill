# Owner Retest Policy

Owner retest is required when a change affects:

- Windows EXE launch or persistence,
- ordinary user navigation,
- document import, KB build, retrieval, generation, Skill, Agent, or A2A runtime,
- Provider Profile switching,
- Redis, vector DB, LLM, embedding, search, OCR, parser, exporter, or network configuration,
- release policy, tags, or GitHub Release creation.

## Retest Evidence

Retest records should include:

- commit SHA,
- CI run URL,
- EXE path when relevant,
- scenario steps,
- pass/fail result,
- blocking defects,
- whether rollback is required.

## Stop Conditions

Stop before release if:

- UI shows internal Gate/Campaign/Core concepts to ordinary users,
- unconfigured capabilities appear executable,
- secrets appear in UI/logs/docs,
- runtime evidence is missing for a claimed capability,
- external project status is overstated.
