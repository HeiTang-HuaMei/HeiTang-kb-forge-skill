# v2.8 Parser Backend Reliability

v2.8.0-alpha.1 adds an opt-in parser backend and knowledge reliability layer.

Default `build`, `batch`, `run`, and `pipeline` behavior remains unchanged unless parser backend mode is enabled.

## Commands

```powershell
python -m heitang_kb_forge.cli parser-backend-list
python -m heitang_kb_forge.cli parse-with-backend --input .\input --output .\parser_output --backend builtin
python -m heitang_kb_forge.cli parse-compare --input .\input --output .\compare --backends builtin,docling,marker
python -m heitang_kb_forge.cli parse-quality-gate --input .\parser_output --output .\quality
python -m heitang_kb_forge.cli parse-reimport-corrected-text --corrected-text .\corrected --output .\reviewed
python -m heitang_kb_forge.cli trusted-kb-gate --package .\package --output .\gate
python -m heitang_kb_forge.cli build --input .\input --output .\package --parser-backend builtin
```

## Backends

- `builtin`: local KB Forge parsers normalized into the parser backend contract.
- `docling`: optional boundary adapter. It is unavailable unless a local Docling integration is explicitly installed and wired.
- `marker`: optional boundary adapter. It is unavailable unless a local Marker integration is explicitly installed and wired.

Docling and Marker are not default dependencies. v2.8 does not call network services.

## Outputs

When parser backend mode is enabled, packages can include:

- `parser_backend_result.json`
- `parser_backend_output.md`
- `parser_backend_output.json`
- `parse_quality_report.json`
- `parse_quality_report.md`
- `ocr_risk_report.json`
- `high_risk_pages.jsonl`
- `high_risk_parse_pages.jsonl`
- `high_risk_chunks.jsonl`
- `manual_review_queue.jsonl`
- `kb_trust_status.json`
- `trusted_kb_gate.json`
- `knowledge_reliability_report.json`

Corrected text re-import also writes `before_after_quality_diff.json`.

## Trust Flow

Parser-backed packages start as `draft_knowledge_package` by default.

The trusted KB gate blocks draft or unknown trust status packages from Skill, Agent, and platform exports unless `--allow-untrusted` is explicitly used. Legacy packages without v2.8 parser trust metadata remain compatible as `legacy_untracked`.

Manual corrected text re-import can promote non-empty corrected text to `reviewed_knowledge_base`.

## Boundaries

- No default parser backend mode.
- No mandatory Docling or Marker dependency.
- No network parser calls.
- No v2.9 platform, mobile, installer, or iOS scope.
- No real external publishing.
