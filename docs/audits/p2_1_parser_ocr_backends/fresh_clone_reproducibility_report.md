# Fresh Clone / Clean Venv Reproducibility

- Status: `pass`
- Default install keeps heavy backends optional: `true`

## Default Install Commands

```powershell
python -m pip install -e .
python -m heitang_kb_forge.cli parser-backend-registry --output .\tmp_parser_registry
python -m heitang_kb_forge.cli parser-backend-matrix --output .\tmp_parser_matrix
python -m heitang_kb_forge.cli parser-backend-inspect docling --output .\tmp_parser_docling
python -m heitang_kb_forge.cli parser-backend-inspect paddleocr --output .\tmp_parser_paddleocr
python -m heitang_kb_forge.cli parser-backend-inspect unstructured --output .\tmp_parser_unstructured
python -m heitang_kb_forge.cli parser-backend-smoke --backend builtin --output .\tmp_parser_builtin_smoke
```

## Optional Backend Install Commands

```powershell
python -m pip install -e ".[parser-docling]"
python -m pip install -e ".[parser-paddleocr]"
python -m pip install -e ".[parser-unstructured]"
```

## Live Acceptance Replay

```powershell
python -m heitang_kb_forge.cli parser-runtime-acceptance --input .\_local_acceptance_inputs\parser_runtime_all_three_clean --output .\tmp_parser_runtime_acceptance --backends docling,paddleocr,unstructured
```

## Notes

- Default install does not install Docling, PaddleOCR, Unstructured, or OCR model files.
- Optional dependency missing behavior is expected and reported as blocked_by_dependency.
- Optional dependency installed behavior is proven by the committed isolated-venv live acceptance report.
