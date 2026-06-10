# Local Privacy and Security

Current Core package version: `4.1.0`
Current stable release: `v4.0.0`
Current release candidate line: `v4.1.0`

Current stage: v4.1.0 Parser/OCR industrial release candidate after P2.1 hardening; the stable v4.0.0 / v4.0 tag remains untouched.

HeiTang KB Forge Core is local-first by default.

## Defaults

- Local-first default: source documents, packages, generated documents, memory reports, indexes, and audit reports are written to local workspace/output folders.
- No platform-hosted user data: the Core repo does not provide SaaS hosting, team accounts, or platform-hosted user data.
- LLM optional only: Core features and tests must remain usable without configured LLM providers.
- No hidden upload: commands must not upload documents or generated packages unless a future explicit, reviewed, opt-in feature says so.
- No real LLM/API/network required by tests: deterministic local paths and offline fallbacks are mandatory.

## Storage Boundary

Default storage backend is `local_workspace`.

Future-compatible names such as `local_db`, `byo_cloud`, and BYO cloud are not implemented as current defaults. They must be described as future/optional until implementation, security review, tests, and docs exist.

## Secret Handling

Provider credentials should be referenced by environment variable names such as `api_key_env`. Reports must not store raw API keys. Live provider smoke commands are opt-in and should be avoided in CI.

## Network Boundary

Some optional provider/platform commands include explicit network-related flags. Final audit treats unexpected network/cloud behavior as P0. Static references to URLs or docs are not hidden upload, but any runtime upload path must be explicit, disabled by default, and tested.

## Agent and Memory Boundary

KB-bound agents must not access unauthorized KBs. Child Agent private memory must remain isolated unless workflow shared memory is explicitly enabled. All-history memory injection must not be default behavior.

## v4.0 Gate

The final gate must not say `ready_for_v4_rc` if there is secret leakage, hidden upload, platform-hosted data overclaiming, real LLM/API/network dependency in tests, unsafe memory boundary behavior, or false docs/UI claims.
