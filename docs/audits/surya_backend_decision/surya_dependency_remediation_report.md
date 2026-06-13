# Surya Dependency Remediation Report

- Adapter: `surya`
- Missing dependencies: surya_ocr, vllm_or_llama_server
- Install attempted: `false`
- Post-install check: `blocked_by_dependency`
- Post-install smoke: `blocked`
- Final decision: `needs_strengthening`
- Blocker evidence: Optional dependency 'surya-ocr' or its vllm/llama.cpp inference backend is not installed. Keep Surya as a benchmark candidate until dependency remediation and smoke evidence are complete.
- Install commands:
  - `python -m pip install surya-ocr>=0.20,<1`
  - `Install or configure vllm for NVIDIA GPU, or llama.cpp llama-server for CPU/Apple Silicon.`
- Rollback steps:
  - Uninstall surya-ocr from the selected environment if installed for this adapter.
  - Stop any vllm container or llama-server process started for Surya.
  - Remove downloaded Surya model/runtime assets if they were created for this adapter.
