# Workspace Partition And Asset Isolation Plan

Status: `foundation_ready`

This Pre-4.0 foundation contract defines workspace ownership and asset isolation
for later Skill, Agent Package, memory, and multi-agent specifications.

It does not implement Campaign 4 UI, Campaign 5 Bridge execution, Agent runtime,
or KB access-scope runtime enforcement.

| Asset Type | Default Scope | Path Root | Cross-Workspace Default |
| --- | --- | --- | --- |
| `sources` | `workspace_private` | `workspace/sources` | `denied_without_explicit_reference` |
| `knowledge_bases` | `workspace_private` | `workspace/knowledge_bases` | `denied_without_explicit_reference` |
| `skills` | `workspace_private` | `workspace/skills` | `denied_without_explicit_reference` |
| `agents` | `workspace_private` | `workspace/agents` | `denied_without_explicit_reference` |
| `workflows` | `workspace_private` | `workspace/workflows` | `denied_without_explicit_reference` |
| `runs` | `workspace_private` | `workspace/runs` | `denied_without_explicit_reference` |
| `reports` | `workspace_private` | `workspace/reports` | `denied_without_explicit_reference` |
| `audits` | `workspace_private` | `workspace/audits` | `denied_without_explicit_reference` |
| `exports` | `workspace_private` | `workspace/exports` | `denied_without_explicit_reference` |
| `memory` | `workspace_private` | `workspace/memory` | `denied_without_explicit_reference` |
| `settings` | `workspace_private` | `workspace/settings` | `denied_without_explicit_reference` |

Legacy artifacts are handled by `legacy_default_workspace` compatibility:
register without moving, deleting, or renaming historical files.
