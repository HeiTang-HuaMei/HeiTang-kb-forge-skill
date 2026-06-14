# New Conversation Handoff Prompt

Continue HeiTang Knowledge Workbench from the completed Campaign 1-3 baseline closure.

Current positioning:
- Product: HeiTang Knowledge Workbench, local knowledge supply-chain workbench.
- Import namespace remains `heitang_kb_forge`.
- Campaigns 1, 2, and 3 are closed for the Campaign 4 entry transition.

Verified state:
- Commit: `09590d8d4ff03310cd5c55b055631fa009350d4d`
- Campaign baseline RC tag: `campaign-1-3-baseline-rc.3`
- CI: run `27489725099` success
- Release Check: run `27489725098` success
- GitHub Release created: `false`
- Campaign 4 active: `false`

Integrated capabilities:
- Knowledge Package
- Document Outputs: Markdown / DOCX / PDF / PPTX
- Skill Outputs: Skill Template / Skill Suite
- Agent Creation Package
- Memory Separation / Knowledge Lifecycle
- Evidence Map / Source Trace
- Retrieval / Verification
- Workspace Partition / KB Access Scope
- External Source Memory & Verification
- Document generation
- Skill generation
- Agent package generation

External project degree:
- `real_integration` entries are local bounded capabilities only.
- `reference_only`, `needs_verification`, and `planned_not_active` entries are not runtime integrations.
- Redis / Vector DB memory store connectors are Campaign 8 future targets.
- LongLive/GPU video generation and local large model support are not current product route commitments.

Strict forbidden misinterpretations:
- Do not treat `campaign-1-3-baseline-rc.3` as a product version tag or GitHub Release.
- Do not treat CI green as commercial release completion.
- Do not treat Agent Package as Agent Runtime.
- Do not treat UI handoff as Campaign 4 implementation.
- Do not treat Bridge handoff as Campaign 5 completion.
- Do not package `_local_dependency_remediation/` into EXE artifacts.

Next safe action:
`Open a new conversation and start Campaign 4 Entry Gate only`

Campaign 4 Entry Gate initial target:
- Open Campaign 4 Goal-Oriented Product UI Workbench Entry Gate only.
- Do not start Campaign 4 business implementation until the Entry Gate verifies the Campaign 1-3 handoff evidence.

Long-task strategy:
- Keep checkpoint, RUN_STATE, resume_prompt, and audit evidence current after each gate.
- On 429 / timeout / 502 / 503 / 504 / network failure, retry up to 8 times with backoff 15/30/60/120/240/480/900/1800 seconds.
- On retry exhaustion, write failure_report and resume_prompt, then stop without advancing state.
