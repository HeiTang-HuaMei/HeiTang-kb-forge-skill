# Live Acceptance Replay

- Source acceptance report: `docs/audits/parser_runtime_acceptance/parser_runtime_acceptance_report.json`
- Replay command: `python -m heitang_kb_forge.cli parser-runtime-acceptance --input .\_local_acceptance_inputs\parser_runtime_all_three_clean --output .\tmp_parser_runtime_acceptance --backends docling,paddleocr,unstructured`
- The committed acceptance report stores counts, dependency/runtime status, and text lengths only; it does not commit raw parsed text.
- In a default install without optional extras, replay is expected to report dependency-gated blocked status.
- In the isolated acceptance venv used for P2.1, replay passed for Docling, PaddleOCR, and Unstructured.
