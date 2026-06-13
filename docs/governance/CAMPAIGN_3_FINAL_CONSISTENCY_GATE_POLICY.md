# Campaign 3 Final Consistency Gate Policy

Status: `next_required_not_started_in_current_lock`

This policy defines the Campaign 3 Final Consistency Gate. The gate is the only next safe action after Campaign 3 Supplement 4.0 Acceptance Gate. It has not passed in the current locked state, and historical downstream artifacts, if present in the workspace, are not counted as current-sequence acceptance.

## Activation

Campaign 3 Final Consistency Gate may start only after Campaign 3 Supplement 4.0 Acceptance Gate passes. That prerequisite passed. This policy does not itself run the gate.

When the gate is run in its own locked item, the expected passing output is:

```text
accepted_for_campaign_1_3_stage_test_gate
```

## Required Coverage

The gate covers:

- Campaign 3 mainline items 5.1 through 5.14
- Campaign 3 strengthening records 5.S1 through 5.S3
- Campaign 3 Supplement 2.0 closure
- Campaign 3 Supplement 3.0 External Source Memory & Verification
- Pre-4.0 Workspace Partition Foundation Gate
- Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract
- Product Output Surface and External Trend Alignment Gate
- repository cleanup/push/tag/CI sequence boundaries before Campaign 4

## Product Output Surface Guard

The Final Consistency Gate explicitly verifies four product output surfaces:

```text
knowledge_package
document_outputs
skill_outputs
agent_creation_package
```

`document_outputs` must remain independent of `skill_outputs` and must include:

```text
Markdown
DOCX / Word
PDF
PPTX / PowerPoint
```

The existing `generate-documents` Core capability is recognized as `existing_core_capability`. If its smoke tests are present, the gate records them as existing evidence. The gate must not implement a new document generator or pull document/PPT runtime from an external project.

## External Trend Alignment Guard

The gate confirms the future reference queue records:

- `andrej-karpathy-skills`
- `Presenton`
- `CodeGraph`
- `Understand Anything`
- `NVlabs/LongLive`
- `claude-plugins-official`
- `pi-mono`

Every item must remain `needs_verification` or `reference_only` with `implementation_mode = not_integrated`, no runtime dependency added, no npm install, no GPU/runtime integration, and no MCP/plugin execution.

## Stop Rule

After this gate passes in its own locked item, business implementation stops. The only next safe action becomes:

```text
Run Campaign 1-3 Stage Test Gate only.
```

Failure must stop and write checkpoint plus resume evidence. A failed Final Consistency Gate must not open Campaign 1-3 Stage Test, Closure, Repository Cleanup, push, tag, CI, or Campaign 4.
