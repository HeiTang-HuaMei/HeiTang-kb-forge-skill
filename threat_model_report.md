# Threat Model Report

- Status: needs_review
- Tests require real LLM/API/network: False

```json
{
  "audit_version": "final-pre-v4.0",
  "status": "needs_review",
  "trust_boundaries": [
    "local filesystem",
    "optional provider config",
    "optional UI shell",
    "future BYO storage adapter"
  ],
  "assets": [
    "source_documents",
    "kb_packages",
    "agent_memory",
    "diagnostic_reports",
    "provider_secrets"
  ],
  "threats": [
    {
      "id": "unexpected_network_upload",
      "severity": "P0",
      "mitigation": "default no-network policy, network audit, no hidden upload report"
    },
    {
      "id": "secret_leakage_in_reports",
      "severity": "P0",
      "mitigation": "secret pattern scan and config secret handling report"
    },
    {
      "id": "agent_kb_scope_escape",
      "severity": "P0",
      "mitigation": "child KB access tests and final red-team validation"
    },
    {
      "id": "memory_isolation_failure",
      "severity": "P0",
      "mitigation": "child private memory isolation tests"
    },
    {
      "id": "false_product_claims",
      "severity": "P1",
      "mitigation": "docs truth and Core/UI contract drift checks"
    }
  ],
  "tests_require_real_llm_api_network": false
}
```
