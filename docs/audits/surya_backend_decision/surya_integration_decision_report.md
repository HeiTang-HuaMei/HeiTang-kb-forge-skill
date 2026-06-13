# Surya Integration Decision Report

- Status: `blocked`
- Decision: `needs_strengthening`
- Current environment: `blocked_by_dependency`
- Dependency status: `missing`
- Runtime status: `skipped`
- Optional extra: `parser-surya`
- Supported inputs: .jpeg, .jpg, .pdf, .png, .tif, .tiff
- Benchmark adapter: `true`
- Primary parser: `false`
- OCR benchmark: `true`
- Layout benchmark: `true`
- Requires inference backend: `vllm_or_llama_cpp`
- Runtime invocation blocked until strengthened: `true`
- Structured skipped when missing: `true`
- Repair: Optional dependency 'surya-ocr' or its vllm/llama.cpp inference backend is not installed. Keep Surya as a benchmark candidate until dependency remediation and smoke evidence are complete.
