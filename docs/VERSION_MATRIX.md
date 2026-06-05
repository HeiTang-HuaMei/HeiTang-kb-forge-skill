# Version Matrix

Current project version: `2.6.0-alpha.1`

| Version | Status | Main Capability | Test Coverage | Known Limits | Checkpoint / Tag |
| --- | --- | --- | --- | --- | --- |
| v1.6 | Implemented | Contract v2, multimodal, OCR, complex ingestion | pytest | local only | historical |
| v1.7 | Implemented | governance, retrieval, evidence gate | pytest | no SaaS | v1.7.0 |
| v1.8 | Implemented | Skill / Agent package generation | pytest | local/mock LLM only | compressed checkpoint |
| v1.9 | Implemented | workspace, registry, prompt profiles, LLM audit | pytest | local workspace only | compressed checkpoint |
| v2.0 | Implemented | stable foundation, provider health, reliability | pytest | no master Skill learning | compressed checkpoint |
| v2.1 | Implemented | input hardening, quality, review, eval | pytest | mock quality assist | compressed checkpoint |
| v2.2 | Implemented | master Skill learning, derived Skill, templates | pytest | no platform runtime | compressed checkpoint |
| v2.3 | Implemented | batch jobs, lineage, curation, update impact | pytest | no platform distribution | v2.3.0-dev |
| v2.3.1-dev | Implemented | post-v2.3 industrial hardening | pytest | stubs only | v2.3.1-dev |
| v2.4 | Implemented | offline platform export and mock publish | pytest | no real platform runtime | v2.4.0-dev |
| v2.4.1-dev | Implemented | post-v2.4 platform hardening | pytest | static checks only | v2.4.1-dev |
| v2.5.0-dev | Implemented | local release quality gate | pytest | not external certification | v2.5.0-dev |
| v2.5.1-alpha.1 | Implemented | release engineering / CLI architecture convergence | pytest | alpha checkpoint | historical |
| v2.6.0-alpha.1 | Implemented | provider registry governance, security, fallback, redaction, cost guard, opt-in live smoke | pytest | alpha checkpoint, no default network, live smoke is Preview | current |
| v2.7 planned | Planned | runtime compatibility smoke | planned | not implemented | planned |
| v2.8 planned | Planned | domain Skill factory | planned | not implemented | planned |
| v2.9 planned | Planned | Feishu / personal KB / mobile / installer / iOS | planned | not implemented | planned |
| v3.x planned | Planned | SaaS / permissions / team collaboration | planned | not implemented | planned |

Notes:

- v2.4 is offline export / mock publish, not real platform execution.
- v2.5 is local release quality gate, not external platform certification.
- v2.6 is opt-in and does not make network calls by default. It does not claim every provider was live-tested.
- v2.7+ rows are Planned and must not be described as completed.

