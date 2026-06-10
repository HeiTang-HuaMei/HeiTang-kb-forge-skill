# Audit Index

This index links the current release-grade audit evidence on main.

## Current Release Evidence

- P2.1 Parser/OCR backend evidence system: [p2_1_parser_ocr_backends/](p2_1_parser_ocr_backends/)
- P2.1 backend matrix: [p2_1_parser_ocr_backends/parser_backend_matrix.json](p2_1_parser_ocr_backends/parser_backend_matrix.json)
- P2.1 backend status report: [p2_1_parser_ocr_backends/parser_backend_status_report.md](p2_1_parser_ocr_backends/parser_backend_status_report.md)
- P2.1 capability boundaries: [p2_1_parser_ocr_backends/backend_capability_boundaries.md](p2_1_parser_ocr_backends/backend_capability_boundaries.md)
- P2.1 live acceptance replay: [p2_1_parser_ocr_backends/live_acceptance_replay.md](p2_1_parser_ocr_backends/live_acceptance_replay.md)
- P2.1 failure modes: [p2_1_parser_ocr_backends/failure_mode_report.json](p2_1_parser_ocr_backends/failure_mode_report.json)

## Historical Evidence

- P2.1 raw live runtime acceptance source: [parser_runtime_acceptance/parser_runtime_acceptance_report.json](parser_runtime_acceptance/parser_runtime_acceptance_report.json)
- P1 final gate re-run: [p1_final_gate_rerun/](p1_final_gate_rerun/)
- P1 real workflow V2: [p1_real_workflow_v2/](p1_real_workflow_v2/)
- S/A contract inclusion: [s_a_contract_inclusion/](s_a_contract_inclusion/)

## Boundaries

- `v4.0.0` remains an untouched historical stable tag.
- P2.1 does not bundle Docling, PaddleOCR, or Unstructured in the default install.
- Static Workbench surfaces may show parser/OCR backend status and evidence, but must not imply local heavy runtime execution.
- Unstructured stable surface is `.md/.txt`; PDF/DOCX/image extras are future hardening.
