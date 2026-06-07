# v3.6 能力差距图

S-level 外部验证检索能力被标为 P0/P1 差距；本地 PDF 解析与 token 降耗能力被映射到 v3.9/parser hardening track。
每个 capability 都包含本地确定性路径、可选 LLM 辅助路径、离线 fallback，并声明 tests_require_real_llm_api_network=false。

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
