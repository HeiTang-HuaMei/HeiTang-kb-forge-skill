# LLM Quality Gate Assist

v2.5 adds mock-first LLM quality gate assist.

It writes `llm_quality_gate_assist_result.json`, `llm_quality_gate_assist_report.md`, and `llm_quality_gate_suggestions.jsonl`.

The default provider is `mock`. It does not require API keys, does not access the network, does not replace rule gates, and does not replace human review.

Real LLM governance and live smoke are reserved for v2.6.

