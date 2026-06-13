# Document Output Governance Policy

This policy prevents audit evidence, runtime logs, generated reports, and caches from turning the product repository into an unbounded report archive.

## Document Classes

| Class | Long-term location | Retention |
| --- | --- | --- |
| Product docs | `docs/product/`, `docs/architecture/`, `docs/user_guide/`, `docs/release/` | Long-term |
| Governance rules | `docs/governance/` | Long-term, rule files only |
| Contracts and schemas | `docs/contracts/`, `schemas/`, `heitang_kb_forge/contracts/` | Long-term |
| Audit evidence | `artifacts/audits/` by default | Retention-managed |
| Runtime logs and caches | `.codex/`, `_runtime_cache/`, `_local_dependency_remediation/`, adapter cache dirs | Not committed by default |

## Audit Storage Rules

1. Audit evidence defaults to `artifacts/audits/`, not new flat directories under `docs/audits/`.
2. `docs/audits/` is the index surface: it may contain `AUDIT_INDEX.md`, `AUDIT_MANIFEST.json`, and promoted `release/` or `milestone/` summaries.
3. Every governed run must have one `run_manifest.json` and one `run_summary.md` as its entry points.
4. Detailed subreports must live under the run directory, not as new flat files.
5. A run should prefer machine-readable JSON plus one human-readable summary. Do not generate a separate Markdown file for every small action unless it is release evidence.
6. Existing historical `docs/audits/*` directories are legacy evidence. They may be indexed, promoted, or migrated, but new runs should not copy that pattern.

## Retention Policy

| Tier | Path | Rule |
| --- | --- | --- |
| latest | `artifacts/audits/latest/` | Keep the newest 3 runs only |
| daily | `artifacts/audits/daily/YYYYMMDD/` | Keep 7 days |
| failed-debug | `artifacts/audits/daily/YYYYMMDD/failed-debug/` | Keep 3 days unless promoted |
| milestone | `artifacts/audits/milestone/vX.Y.Z/` | Long-term |
| release | `artifacts/audits/release/vX.Y.Z/` | Long-term |

## Git Policy

1. `artifacts/audits/latest/` and `artifacts/audits/daily/` are not committed by default.
2. Runtime logs, `progress_events.jsonl`, retry logs, model cache, runtime cache, and local dependency environments are not committed by default.
3. Milestone and release evidence may be committed only when summarized through `run_summary.md`, indexed in `AUDIT_MANIFEST.json`, and intentionally promoted.
4. If full logs are needed for a release, store a short summary in Git and keep bulky logs outside Git unless explicitly promoted.

## Pre-Generation Checklist

Before generating documents or reports, decide:

1. Is this product, governance, contract, audit, or runtime output?
2. Is there already an index or manifest entry that should be updated instead of creating a new file?
3. Does this run need both JSON and Markdown, or is `run_manifest.json` plus `run_summary.md` enough?
4. Does the output belong in Git?
5. What is the retention tier and cleanup date?
6. Is the output a release or milestone artifact, or only short-lived diagnostic evidence?

## Required Indexes

- `docs/audits/AUDIT_MANIFEST.json` is the machine-readable source of truth for promoted or governed audit runs.
- `docs/audits/AUDIT_INDEX.md` is the human-readable index.
- Every `AUDIT_MANIFEST.json` entry must declare `run_id`, `type`, `scope`, `status`, `evidence_dir`, `retention`, `keep_in_git`, `run_manifest`, `run_summary`, and `summary`.

## Forbidden Patterns

- Do not add unindexed flat runtime logs to `docs/audits/`.
- Do not commit `progress_events.jsonl` except as promoted release evidence.
- Do not commit model cache, runtime cache, local virtual environments, or dependency remediation environments.
- Do not treat generated audit evidence as product documentation.
- Do not mark short-lived latest or daily evidence as milestone or release evidence without a summary and manifest entry.
