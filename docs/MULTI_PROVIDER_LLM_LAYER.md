# Stable Multi-Provider LLM Layer

v2.0 keeps provider behavior offline by default. The stable provider policy defaults to mock provider, disables network access, requires audit logs, and avoids storing real API keys.

`provider-health` checks the local provider registry and reports whether mock or disabled providers are usable. `openai_compatible` remains optional and must not be required for tests.
