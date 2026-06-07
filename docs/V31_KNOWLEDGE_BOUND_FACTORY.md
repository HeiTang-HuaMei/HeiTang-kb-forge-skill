# v3.1 Agent / Skill Factory

v3.1 adds an opt-in local factory for Agent and Skill package generation. The hardening target is two first-class Agent creation modes: `kb_bound` and `standalone`.

## Scope

- Reuse the existing Skill and Agent package generators.
- Support KB-bound Agent generation for RAG, knowledge service, and enterprise KB scenarios.
- Support standalone Agent generation for planning, coaching, writing, operations, QA, project management, and prompt optimization scenarios.
- Enforce the trusted KB gate by default for KB-bound generation.
- Validate generated Skill and Agent packages.
- Write factory manifest, trace, quality, and Markdown reports.
- Keep default build, run, and pipeline behavior unchanged unless enabled.

## Agent Modes

### `kb_bound`

- Agent is bound to one or more knowledge packages.
- Retrieval binding is enabled.
- Citation, evidence, answer, and refusal policies are grounded in the bound KB.
- Untrusted KBs must block strict generation unless explicitly allowed.
- Generated packages must expose `knowledge_binding.enabled: true`, package ID/path, trust status, retrieval config, citation policy, evidence policy, and refusal policy.

### `standalone`

- Agent can be created without a knowledge package.
- Retrieval binding is disabled or optional.
- Agent is defined by system prompt, soul/profile, capabilities, tools config, memory policy, output contract, answer policy, refusal policy, and eval cases.
- Standalone Agents must not pretend to have KB citations.
- Generated packages must expose `knowledge_binding.enabled: false`.

## Commands

```powershell
python -m heitang_kb_forge.cli generate-bound-agent --package .\tmp_package --output .\tmp_factory
python -m heitang_kb_forge.cli generate-agent --mode kb_bound --package .\tmp_package --output .\tmp_agent
python -m heitang_kb_forge.cli generate-agent --mode standalone --output .\tmp_agent
```

Config-driven runs support:

```yaml
knowledge_bound_factory:
  enabled: true
  skill_name: Demo Knowledge Skill
  agent_name: Demo Knowledge Agent
  mode: kb_bound
```

## Output Files

KB-bound outputs include:

- `skill_package/SKILL.md`
- `agent_package/system_prompt.md`
- `skill_validation/skill_validation_result.json`
- `knowledge_bound_factory_manifest.json`
- `knowledge_bound_factory_trace.json`
- `knowledge_bound_factory_quality_report.json`
- `knowledge_bound_factory_report.md`

Standalone Agent package outputs must include:

- `agent_manifest.json`
- `agent_profile.yaml`
- `soul.md`
- `system_prompt.md`
- `capabilities.yaml`
- `tools.yaml`
- `memory_policy.yaml`
- `output_contract.yaml`
- `answer_policy.md`
- `refusal_policy.md`
- `eval_cases.jsonl`
- `smoke_test_report.json`
- `smoke_test_report.md`
- `validation_report.json`
- `validation_report.md`

## Validation Requirements

- `standalone` mode must not require a KB package.
- `standalone` mode must require answer policy, refusal policy, memory policy, capabilities, output contract, and eval cases.
- `kb_bound` mode must require KB binding and retrieval policy.
- `kb_bound` mode must block untrusted KBs in strict mode.
- Offline smoke tests must run for both modes.

## Boundaries

v3.1 is local and deterministic by default. It does not deploy Agents, call real LLM APIs, or call external Agent platforms.
