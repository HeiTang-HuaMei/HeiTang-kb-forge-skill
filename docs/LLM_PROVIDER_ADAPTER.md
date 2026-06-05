# LLM Provider Adapter

v1.7 adds a minimal provider adapter for evidence validation workflows.

Supported provider modes:

* mock
* openai_compatible placeholder

The mock provider is deterministic and used by tests. The OpenAI-compatible adapter does not perform network calls in tests and requires explicit configuration.

API keys are not written to output files, reports, or call logs.
