# v3.6 Capability Gap Map

S-level external verification retrieval capabilities are marked as P0/P1 gaps. Local PDF parsing and token reduction capabilities are mapped to v3.9/parser hardening track.
Every capability includes a deterministic local path, optional LLM-assisted path, offline fallback, and tests_require_real_llm_api_network=false.

- Capability count: 86
- Network required for tests: false

## S-level Verification Capabilities

- claim_verification
- external_source_cross_check
- contradiction_detection
- freshness_verification
- knowledge_accuracy_scoring
- verification_retrieval_trace

See `capability_gap_map.json` for the full map.
