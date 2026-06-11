# User Manual

This manual describes the local Core workflow at package version `4.2.0` for the v4.2.0 P2.2 Knowledge-to-Methodology-to-Skill-Suite Industrial Baseline after v4.1.1 Test Framework Governance. The existing `v4.0.0`, `v4.1.0`, and `v4.1.1` tags remain untouched.

## 1. Install Locally

```powershell
python -m pip install -e ".[dev]"
python -m heitang_kb_forge.cli doctor --output .\tmp_doctor
```

Optional local parser extras:

```powershell
python -m pip install -e ".[ocr,pdf-table,parser-docling,parser-marker,parser-paddleocr,parser-unstructured,web]"
```

## 2. Prepare Input Files

Put source files under a local folder such as `.\examples\quickstart\input`.

Supported local input routes include Markdown, TXT, DOCX, text PDF, image/OCR routes when extras are installed, CSV, TSV, XLSX, HTML, EPUB, and ZIP.
Optional parser backends include Docling, PaddleOCR, and Unstructured when their local extras are installed.
The current `parser-unstructured` extra is validated for Markdown/TXT sources.
Use `parser-runtime-acceptance` with a folder that contains backend-supported document and OCR sources to write live runtime evidence for those optional parser/OCR backends; it reports `blocked` when the local dependencies or supported sources are not available.

Inspect the release-grade backend surface before running optional heavy backends:

```powershell
python -m heitang_kb_forge.cli parser-backend-registry --output .\tmp_parser_registry
python -m heitang_kb_forge.cli parser-backend-matrix --output .\tmp_parser_matrix
python -m heitang_kb_forge.cli parser-backend-inspect docling --output .\tmp_parser_docling
python -m heitang_kb_forge.cli parser-backend-inspect paddleocr --output .\tmp_parser_paddleocr
python -m heitang_kb_forge.cli parser-backend-inspect unstructured --output .\tmp_parser_unstructured
python -m heitang_kb_forge.cli parser-backend-smoke --backend builtin --output .\tmp_parser_builtin_smoke
```

In a default install, optional backend inspect commands may report `blocked_by_dependency`; this is expected and preserves the builtin fallback. Install optional extras only in environments prepared for those local runtimes:

```powershell
python -m pip install -e ".[parser-docling]"
python -m pip install -e ".[parser-paddleocr]"
python -m pip install -e ".[parser-unstructured]"
```

## 3. Build a Knowledge Package

```powershell
python -m heitang_kb_forge.cli build --input .\examples\quickstart\input --output .\tmp_package
```

Expected files include `manifest.json`, `chunks.jsonl`, `cards.jsonl`, `qa_pairs.jsonl`, `glossary.jsonl`, `quality_report.json`, and `ingest_report.md`.

## 4. Validate Package Contract

```powershell
python -m heitang_kb_forge.cli check-contract --package .\tmp_package --output .\tmp_contract
```

## 5. Query the KB Locally

```powershell
python -m heitang_kb_forge.cli kb-index --package .\tmp_package --output .\tmp_kb_index
python -m heitang_kb_forge.cli kb-query --package .\tmp_package --query "Summarize this package" --output .\tmp_kb_query
python -m heitang_kb_forge.cli kb-answer --package .\tmp_package --query "What is the main topic?" --output .\tmp_kb_answer
```

## 6. Run Query Rewrite and Retrieval Planning

```powershell
python -m heitang_kb_forge.cli rewrite-query --query "summarize it" --output .\tmp_query_rewrite
python -m heitang_kb_forge.cli plan-retrieval --query "Summarize this package" --purpose answering --package .\tmp_package --output .\tmp_plan_answering
python -m heitang_kb_forge.cli plan-retrieval --query "Verify whether this package is current" --purpose validation --package .\tmp_package --output .\tmp_plan_validation
```

The `answering` and `validation` purposes are intentionally separate. v3.7 does not perform external retrieval or claim verification.

## 7. Run Retrieval Quality and Knowledge Verification

```powershell
python -m heitang_kb_forge.cli eval-retrieval --package .\tmp_package --output .\tmp_retrieval_eval
python -m heitang_kb_forge.cli rerank-results --package .\tmp_package --query "main topic" --output .\tmp_rerank
python -m heitang_kb_forge.cli select-evidence --package .\tmp_package --query "main topic" --output .\tmp_evidence
python -m heitang_kb_forge.cli verify-claims --package .\tmp_package --output .\tmp_claims
python -m heitang_kb_forge.cli check-knowledge-accuracy --package .\tmp_package --output .\tmp_accuracy
```

These commands use local package data and do not require real LLM/API/network calls.

## 8. Generate Documents

```powershell
python -m heitang_kb_forge.cli generate-documents --package .\tmp_package --output .\tmp_documents
python -m heitang_kb_forge.cli generate-md --package .\tmp_package --output .\tmp_md
python -m heitang_kb_forge.cli generate-docx --package .\tmp_package --output .\tmp_docx
python -m heitang_kb_forge.cli generate-pdf --package .\tmp_package --output .\tmp_pdf
python -m heitang_kb_forge.cli generate-pptx --package .\tmp_package --output .\tmp_pptx
```

## 9. Generate Skill and Agent Packages

```powershell
python -m heitang_kb_forge.cli generate-skill --package .\tmp_package --output .\tmp_skill
python -m heitang_kb_forge.cli generate-agent --mode standalone --output .\tmp_agent_standalone
python -m heitang_kb_forge.cli generate-agent --mode kb_bound --package .\tmp_package --skill .\tmp_skill --output .\tmp_agent_bound
```

`kb_bound` mode requires both `--package` and `--skill`.

## 10. Build a Governable Skill Suite

```powershell
python -m heitang_kb_forge.cli extract-methodology --kb .\tmp_package --out .\tmp_methodology
python -m heitang_kb_forge.cli plan-skill-suite --methodology .\tmp_methodology --out .\tmp_skill_plan
python -m heitang_kb_forge.cli build-skill-suite --plan .\tmp_skill_plan --out .\tmp_skill_suite
python -m heitang_kb_forge.cli validate-skill-suite --suite .\tmp_skill_suite
python -m heitang_kb_forge.cli diff-skill-suite --before .\tmp_old_skill_suite --after .\tmp_skill_suite --out .\tmp_suite_diff
python -m heitang_kb_forge.cli check-skill-suite-installability --suite .\tmp_skill_suite
python -m heitang_kb_forge.cli skill-suite-governance-report --suite .\tmp_skill_suite
python -m heitang_kb_forge.cli export-skill-pack --suite .\tmp_skill_suite --out .\tmp_skill_pack
```

The suite flow keeps source evidence and risk flags attached from methodology extraction through validation, diff, installability, governance, and export. It does not call external provider APIs or vendor external runtimes.

## 11. Run Local Agent Runtime Smoke

```powershell
python -m heitang_kb_forge.cli run-local-agent --package .\tmp_package --agent .\tmp_agent_bound --task "Summarize the package" --output .\tmp_agent_runtime
```

This is a deterministic local runtime smoke, not a SaaS service and not a full autonomous Agent Runtime.

## 12. Inspect Workspace, Storage, and Memory Lifecycle

```powershell
python -m heitang_kb_forge.cli init-workspace --workspace .\tmp_workspace --output .\tmp_workspace_init
python -m heitang_kb_forge.cli scan-workspace --workspace .\tmp_workspace --output .\tmp_workspace_scan
python -m heitang_kb_forge.cli report-storage --workspace .\tmp_workspace --output .\tmp_storage
python -m heitang_kb_forge.cli plan-cleanup --workspace .\tmp_workspace --output .\tmp_cleanup
python -m heitang_kb_forge.cli plan-memory-lifecycle --output .\tmp_memory
```

Cleanup planning is not destructive by default.

## 13. Run Golden Demo Acceptance

```powershell
python -m heitang_kb_forge.cli run-golden-demo-acceptance --package .\tmp_package --output .\tmp_golden --no-require-v37 --no-require-v38 --no-require-v39 --no-require-v310
```

Use the `--require-*` defaults for release evidence once all prior version artifacts are present.

## 14. Run Product Hardening

```powershell
python -m heitang_kb_forge.cli product-hardening --workspace . --package .\tmp_package --output .\tmp_hardening --no-require-v37 --no-require-v38 --no-require-v39 --no-require-v310 --no-require-v311
```

For release evidence, run with default `--require-*` checks and provide all prior artifacts.

## 15. Run Final Pre-v4 Audit

```powershell
python -m heitang_kb_forge.cli final-pre-v4-audit --core-repo . --output .\tmp_final_audit
```

This audit may return `blocked`. That is correct when P0/P1 evidence is missing.

## 16. Read Reports

Inside the `.\tmp_final_audit` output directory, start with:

- `final_v4_rc_gate_report.json`
- `final_product_capability_proof_report.md`
- `final_functionality_truth_matrix.md`
- `final_industrial_red_team_report.md`
- `final_security_privacy_report.md`
- `final_user_workflow_acceptance_report.md`

## Troubleshooting

Use [Troubleshooting](TROUBLESHOOTING.md). Common fixes are installing optional parser extras, checking package paths, reading stable error text, and rerunning doctor.
