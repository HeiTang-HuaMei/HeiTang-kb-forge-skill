# P2.2 Supplemental Version Plan

## Status

User-approved Core integration supplement for v4.2.0 / P2.2:

- Anything2Skill
- SkillX
- Anthropic Skills / skill-creator

This supplement strengthens the existing P2.2 objective. It does not replace the roadmap, create another release line, or start P2.3+.

## P2.2 Objective

```text
Existing Knowledge Asset
-> Evidence Window
-> Methodology Module
-> Skill Candidate
-> Skill Hierarchy
-> Skill Suite / Skill Pack
-> Validation / Diff / Installability / Governance
-> UI + CLI Industrial Closure
```

## Integration Levels

| Reference | Integration | Fused capability | Explicit exclusion |
| --- | --- | --- | --- |
| Anything2Skill | L3 `contract_absorbed` + L4 `capability_fused` | evidence-to-candidate contracts, supporting evidence, confidence, risk flags, unsupported-claim detection | no paper reproduction, training workflow, external benchmark runtime, or L5 runtime integration |
| SkillX | L3 `contract_absorbed` + L4 `capability_fused` | Planning / Functional / Atomic hierarchy, routing, dependency graph, duplicate/conflict detection, merge/split recommendations | no trajectory mining, self-evolving Skill runtime, or complete SkillX runtime |
| Anthropic Skills / skill-creator | L3 `contract_absorbed` + partial L4 `packaging_governance_fused` | SKILL.md packaging, description/trigger checks, allowed-file boundary, installability, evaluation and optimization notes | no Anthropic platform binding, Claude Skills runtime, upload flow, account dependency, or provider API |

## Route Preservation

The existing external-project roadmap remains authoritative:

- LLM Wiki v2 remains under Living Knowledge / Memory Lifecycle.
- WeKnora remains under Auto Wiki / Knowledge Graph.
- n8n remains under Workflow Export / Automation Boundary.
- AnySearchSkill / last30days remain under External Retrieval / Trend Radar.
- Jellyfish / MMSkills / story-flicks / seedance2-skill remain under AIGC / Multimodal.
- andrej-karpathy-skills / skill-prompt-generator remain part of the existing Skill Governance reference route.

## Slice Placement

- Slice 4: Evidence Windows + Methodology Module.
- Slice 5: Skill Candidates + Anything2Skill contract.
- Slice 6: Skill Hierarchy + SkillX contract.
- Slice 7: Skill Pack / SKILL.md packaging + Anthropic skill-creator contract.
- Slice 8: Suite-level validation / diff / installability.
- Slice 9: UI industrial closure.
- Slice 10: docs / release / v4.2.0.

## Hard Boundaries

- No L5 external runtime integration.
- No runtime vendoring or copied external project code.
- No real external provider, API, account, upload flow, Docker, or database.
- No new external project beyond the three user-approved references.
- No P2.3+ work.
- No v4.2.0 release before Slice 10.
- No historical tag modification.
