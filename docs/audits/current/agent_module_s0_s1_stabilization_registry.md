# Agent Module S0/S1 Stabilization Registry

## Scope

```text
status = blocked_requires_s0_s1_stabilization
module = Agent
goal = stabilize existing Agent profile binding and dialogue trace chain before P2 workgroup/A2A expansion
boundary = no Final Owner Review Gate, no package candidate build, no P2 reopen, no capability_chain_status.json change
```

Current Agent capability is not missing. The existing product chain covers:

```text
create assistant profile
-> bind knowledge bases
-> bind Skills
-> send message
-> local/model-backed response boundary
-> conversation history
-> citation trace
-> skill rule trace
-> activity/event records
-> delete/clear/restart recovery
```

Current gap:

```text
The implementation has two parallel chains:

legacy asset chain:
generateAgent -> agent/knowledge_qa_agent -> runAgentDialogue -> chat_history/citation_trace/skill_rule_trace/dialogue_manifest

profile product chain:
createAgentProfile -> agent/catalog/agents.json -> boundKnowledgeBaseIds/boundSkillIds -> sendAgentMessage -> agent/conversations/<agent_id>/conversation.json

The product chain must be stabilized around real Agent/KB/Skill ids, traceable evidence, KB-out-of-scope refusal, and lifecycle consistency before P2 workgroup/A2A expansion.
```

## Capability Landing

```text
P0 affected = agent_p0_single_assistant, assistant_bound_kb_integration, agent_memory_minimal_core
P1 affected = assistant_backend_separation, agent_memory_layer_basic, workbench_agent_harness
P2 related/deferred = a2a_workgroup, office_collaboration_workgroup, research_analysis_workgroup, role_based_workgroup, office_agent_industrialization
```

This registry does not reopen P0/P1/P2 gates. It records stabilization work needed before claiming product-level Agent closure.

## Product Chain Decision

```text
Product UI main truth = Agent Profile chain.

Primary truth files:
agent/catalog/agents.json
agent/conversations/<agent_id>/conversation.json
agent/conversations/<agent_id>/*citation_trace*
agent/conversations/<agent_id>/*skill_rule_trace*
audit/event_ledger.jsonl
artifacts/catalog.json

Legacy compatibility:
agent/knowledge_qa_agent
agent/dialogue/chat_history.jsonl
agent/dialogue/citation_trace.jsonl
agent/dialogue/skill_rule_trace.jsonl
agent/dialogue/agent_dialogue_manifest.json
```

Legacy files may remain for compatibility or asset generation, but product UI state must not treat them as the primary truth when a profile-based assistant exists.

## S0 Defects

These are S0 only when confirmed by reproduction evidence.

```text
AGENT-S0-001 | A user cannot create an assistant profile in a valid workspace.
AGENT-S0-002 | A valid active KB or Skill cannot be bound to an assistant.
AGENT-S0-003 | An unbound assistant answers as if it had KB evidence.
AGENT-S0-004 | A bound assistant fabricates an answer for a question outside bound KB evidence.
AGENT-S0-005 | A bound assistant cannot read the selected KB/Skill during dialogue.
AGENT-S0-006 | Deleting an Agent deletes or corrupts source KB, Skill, source documents, or other assistants.
AGENT-S0-007 | Agent profile, dialogue, export, trace, or diagnostics expose plaintext secrets, tokens, cookies, or authorization headers.
AGENT-S0-008 | UI shows assistant bound to KB/Skill A while runtime uses KB/Skill B.
AGENT-S0-009 | Agent delete/clear/restart lifecycle is unsafe: deleted agents reappear, active agents disappear, or conversations bind to the wrong agent.
```

## S1 Defects

These should be repaired before P2 workgroup/A2A expansion.

```text
AGENT-S1-001 | K1/S1/primary_skill/default_local/reading_summary_skill enter product persistence as real binding ids.
AGENT-S1-002 | Profile chain and runAgentDialogue chain produce divergent binding, conversation, or trace truth.
AGENT-S1-003 | agent/catalog/agents.json and agent_manifest do not agree for the same assistant.
AGENT-S1-004 | conversation.json, dialogue_manifest, chat_history, citation_trace, and skill_rule_trace can drift for the same dialogue.
AGENT-S1-005 | citation_trace cannot trace each answer to kb_id, chunk_id, source_doc_id, and source_trace_id when evidence exists.
AGENT-S1-006 | skill_rule_trace cannot trace each applied rule/instruction to the actual bound skill_id.
AGENT-S1-007 | Bound KB/Skill state is lost or changed after restart.
AGENT-S1-008 | Local fallback or placeholder response can be mistaken for a real model/KB-grounded answer.
AGENT-S1-009 | Event Ledger lacks create, bind, chat, clear, delete, and error lifecycle events for product truth.
AGENT-S1-010 | Agent memory snapshot is missing, cannot be recovered, or is not scoped to the active assistant/conversation.
AGENT-S1-011 | Binding validation does not detect deleted, inactive, or missing KB/Skill ids before dialogue.
AGENT-S1-012 | Agent UI state does not refresh consistently after KB/Skill creation, deletion, or rebinding.
```

## Not S0/S1 Yet

```text
full autonomous agent executor
P2 multi-agent / A2A industrialization
advanced workgroup orchestration
role market or agent marketplace
large Agent service/repository architecture extraction
external tool execution expansion
long-horizon autonomous planning
advanced memory consolidation beyond basic recovery truth
```

These belong after Agent profile binding, trace, refusal, lifecycle, and restart truth are stable.

## Binding Rules

Agent dialogue must resolve and persist:

```text
agent_id
conversation_id
bound_kb_ids
bound_skill_ids
active_kb_scope
active_skill_scope
answer_policy_id
```

Forbidden product persistence:

```text
K1
S1
primary_skill
default_local
reading_summary_skill
```

These values may appear only as test aliases, display aliases, or legacy compatibility markers with an explicit field such as:

```text
test_alias_only = true
legacy_compatibility_only = true
```

## Dialogue Execution Rule

Correct product execution chain:

```text
sendAgentMessage(agent_id, message)
-> load agent profile
-> load bound KB ids
-> load bound Skill ids
-> validate KB/Skill still active
-> retrieve only within selected KB scope
-> apply bound Skill instructions/constraints
-> generate or produce clearly labeled local fallback response
-> validate citation_trace
-> refuse or ask for more data when evidence is missing
-> write conversation
-> write citation_trace
-> write skill_rule_trace
-> write event
-> update artifact/activity records where applicable
```

Invalid product execution chain:

```text
send message
-> choose any current KB implicitly
-> fall back to K1/S1
-> write local placeholder answer
-> show success as if it were grounded in the selected KB
```

## KB Boundary Rule

```text
If an Agent is bound to KBs:
  It may answer only from bound_kb_ids.
  If no evidence is found, it must say the current knowledge base has no basis for the answer.
  It must not fabricate or cite unbound sources.

If an Agent is not bound to a KB:
  It must not present a knowledge-base answer.
  It may prompt the user to bind a knowledge base first.

If an Agent has a Skill but no KB:
  It may perform process/template guidance.
  It must not claim the guidance is based on user KB evidence.
```

## Stabilization Requirements

Minimum product chain:

```text
create assistant
-> bind KB
-> bind Skill
-> ask in-scope question
-> show answer and sources
-> ask out-of-scope question
-> refuse or explain missing basis
-> clear conversation
-> delete assistant
-> restart recovery
```

Minimum artifacts:

```text
agent/catalog/agents.json
agent/conversations/<agent_id>/conversation.json
agent/conversations/<agent_id>/citation_trace.jsonl or equivalent trace file
agent/conversations/<agent_id>/skill_rule_trace.jsonl or equivalent trace file
agent activity records
event_ledger records
artifact_lifecycle records where applicable
memory snapshot/recovery records where applicable
```

## Execution Order

```text
1. Audit agent_product_workflow.dart, generateAgent, runAgentDialogue, createAgentProfile, sendAgentMessage, deleteAgentProfile, conversation persistence, citation_trace, and skill_rule_trace.
2. Reproduce one S0/S1 defect at a time and record exact evidence.
3. Make Agent Profile chain the product UI truth.
4. Mark generateAgent/runAgentDialogue outputs as legacy compatibility or adapt them to read profile binding truth.
5. Replace persisted K1/S1/primary_skill/default_local semantics with resolved real ids.
6. Repair KB/Skill binding validation before dialogue.
7. Repair citation_trace and skill_rule_trace to point to real KB/Skill/source ids.
8. Repair KB-out-of-scope refusal.
9. Repair create/bind/chat/clear/delete/restart lifecycle truth.
10. Defer P2 workgroup/A2A expansion until S0/S1 is clear.
```

## Acceptance

White-box:

```text
agents_catalog_correct = true
agent_ids_are_real = true
bound_kb_ids_are_real = true
bound_skill_ids_are_real = true
no_product_persisted_k1_s1_default_local = true
send_agent_message_reads_profile_chain = true
legacy_dialogue_not_product_truth_or_reads_profile_truth = true
conversation_trace_consistent = true
citation_trace_to_kb_source_chunk = true
skill_rule_trace_to_real_skill = true
event_ledger_lifecycle_correct = true
delete_agent_does_not_delete_kb_or_skill = true
restart_recovery_correct = true
```

Black-box:

```text
create_agent_passed = true
bind_kb_passed = true
bind_skill_passed = true
in_scope_answer_with_source_passed = true
out_of_scope_refusal_passed = true
clear_conversation_passed = true
delete_agent_safe_passed = true
restart_recovery_passed = true
missing_deleted_kb_skill_explains_next_action = true
local_fallback_clearly_labeled = true
```

## Current Judgment

```text
Agent product capability exists.
It is currently best described as a bound-KB/Skill assistant with profile, conversation, trace, and workgroup evidence entry points.
The current risk is not lack of Agent capability, but two chains competing for product truth and fallback ids leaking into real binding semantics.
Current priority is S0/S1 stabilization of profile binding, source trace, KB-out-of-scope refusal, lifecycle consistency, and restart recovery.
Do not expand into P2 workgroup/A2A industrialization until these defects are cleared.
```
