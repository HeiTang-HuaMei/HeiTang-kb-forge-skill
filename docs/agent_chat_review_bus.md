# Agent Chat Review Bus

## Design Goal

This review bus gives Claude Code and Codex a lightweight, auditable handoff channel without any extra service. It stores short review messages in a dedicated Git ref, separate from normal branches, so code branches stay clean.

Codex writes code, runs focused validation, commits, and pushes. Claude Code reads the result, reviews risk, and sends review or approval feedback. Both agents use the same append-only JSONL stream.

## Git Ref

Dedicated ref:

```text
refs/agent-chat/kb-forge
```

The ref points to a commit containing one file:

```text
agent_chat.jsonl
```

The tool must not write this data to a normal branch.

## Message Schema

Storage format is JSONL. Each line is one JSON object.

Required fields:

```json
{
  "id": "msg_000001",
  "from": "claude-code",
  "type": "review",
  "reply_to": null
}
```

Recommended fields:

```json
{
  "body": "Review bus ready.",
  "commit": "abc1234",
  "ts": "2026-06-17T12:00:00Z",
  "target": "git_ref_review_bus_setup_gate",
  "status": "ready"
}
```

`id` values are generated as `msg_000001`, `msg_000002`, and so on. `reply_to` is either `null` or an existing message id.

## Type Semantics

Allowed `type` values:

- `review`: review request, review result, or channel readiness note.
- `risk`: a blocking concern, regression risk, missing evidence, or unsafe operation.
- `done`: implementation, fix, or validation completion.

No other message types are accepted.

## Agent Split

Claude Code responsibilities:

- Send `review` when opening or completing a review.
- Read `risk` or `done` from Codex.
- Approve, reject, or request follow-up based on evidence.

Codex responsibilities:

- Read the latest `review`.
- Implement only the requested code and validation.
- Send `risk` when a problem blocks safe completion.
- Send `done` when the fix and validation are complete.

Only one side writes at a time. The other side should read only until the writer finishes.

## CLI Usage

Show the latest messages:

```powershell
python scripts/agent_chat.py chat
python scripts/agent_chat.py chat --limit 5
python scripts/agent_chat.py chat --json
```

Append a message:

```powershell
python scripts/agent_chat.py send --from claude-code --type review --body "Please review commit abc1234."
python scripts/agent_chat.py send --from codex --type risk --reply-to msg_000001 --body "Validation failed; stopping before push."
python scripts/agent_chat.py send --from codex --type done --reply-to msg_000001 --commit abc1234 --target git_ref_review_bus_setup_gate --status passed --body "Focused tests passed."
```

Validate the current ref:

```powershell
python scripts/agent_chat.py validate
```

Validate a local JSONL file:

```powershell
python scripts/agent_chat.py validate --file tmp/agent_chat.jsonl
```

If the ref does not exist, `chat` prints `empty chat` and `validate` reports a valid empty chat.

## Conflict Handling

`send` fetches the latest `refs/agent-chat/kb-forge` from `origin` before appending. It then creates a temporary blob, tree, and commit, updates the local dedicated ref, and pushes:

```text
refs/agent-chat/kb-forge:refs/agent-chat/kb-forge
```

The tool never uses force push. If the push is rejected, stop. Fetch the latest ref, reread the chat, and retry the send after resolving the new context.

## Safety Rules

- Do not record API keys, tokens, passwords, private keys, or secrets.
- Do not paste large logs. Summarize the issue and point to a commit, test command, or artifact path.
- Do not write review messages to normal branches.
- Do not use force push, reset, ref deletion, checkout, or branch creation for this bus.
- `send` must read the latest remote ref before writing.
- Push conflicts must stop or retry; never overwrite the remote ref.
- Keep message bodies at or below 4000 characters.

## Not Suitable For

- Large logs, test transcripts, screenshots, binaries, or long audit evidence.
- Secret sharing or credential handoff.
- Replacing pull requests, CI, release gates, or formal approvals.
- Multi-writer chat without coordination.
- Long-term product documentation or campaign planning.
