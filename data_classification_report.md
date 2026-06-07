# Data Classification Report

- Status: needs_review
- Tests require real LLM/API/network: False

```json
{
  "audit_version": "final-pre-v4.0",
  "status": "needs_review",
  "classes": [
    {
      "data_class": "source_documents",
      "sensitivity": "user_private",
      "default_storage": "local_workspace",
      "network_allowed_by_default": false
    },
    {
      "data_class": "kb_packages",
      "sensitivity": "user_private",
      "default_storage": "local_workspace",
      "network_allowed_by_default": false
    },
    {
      "data_class": "agent_memory",
      "sensitivity": "user_private",
      "default_storage": "local_workspace",
      "network_allowed_by_default": false
    },
    {
      "data_class": "diagnostic_reports",
      "sensitivity": "mixed_metadata",
      "default_storage": "local_workspace",
      "network_allowed_by_default": false
    },
    {
      "data_class": "provider_secrets",
      "sensitivity": "secret",
      "default_storage": "environment_reference_only",
      "network_allowed_by_default": false
    }
  ],
  "reason": "Classification is explicit, but final acceptance still needs docs/UI truth validation.",
  "tests_require_real_llm_api_network": false
}
```
