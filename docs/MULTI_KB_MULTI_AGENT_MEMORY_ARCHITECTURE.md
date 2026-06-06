# Multi-KB, Multi-Agent, and Memory Isolation Architecture

## Principle

Agent memory must be isolated by default.

A multi-agent system must not allow Agents to read each other's private memory unless an explicit workflow handoff authorizes it.

## Memory Scopes

- Workspace memory
- Knowledge-base memory
- Agent private memory
- Session memory
- Workflow shared memory
- Handoff memory
- Long-term experience memory

## Default Access Rules

- An Agent can read its own private memory.
- An Agent can read bound knowledge-base memory.
- An Agent can read current session memory.
- An Agent cannot read another Agent's private memory.
- An Agent cannot read unbound knowledge bases.
- Shared memory is allowed only inside an explicit workflow.

## External Memory Backends

Candidate optional backends:

- Mem0: persistent Agent memory
- Zep / Graphiti: temporal knowledge graph memory
- LangGraph checkpointer / store: workflow and multi-agent state

All external memory backends must use workspace_id, agent_id, kb_id, workflow_id, and session_id namespaces.
