# Model Gateway and Provider Policy

Model Gateway and Provider configuration are shared infrastructure, not Agent-only features.

## Applies To

- document generation,
- Skill Factory,
- Agent Workspace,
- A2A collaboration,
- retrieval verification when external search or evaluation is configured,
- embedding and vector index flows.

## Provider Readiness Levels

- `reference_only`: registered for governance only; not user-selectable.
- `readiness_only`: adapter contract or local evidence exists; runtime is not loaded.
- `needs_verification`: may be useful but lacks enough evidence.
- `configurable_provider`: configuration, health check, fallback, audit, and rollback evidence exist.
- `runtime_loaded`: allowed only when the runtime has real evidence and the boundary is explicit.

## P2 Model Gateway Broad API Adaptation Scope

P2 model adaptation targets external model APIs, domestic and international. It is a deferred cross-cutting P2 acceptance requirement and must not be used to weaken or retroactively rewrite a completed P2 gate. It must cover multi-Provider onboarding, model capability probing, model availability smoke, model selection policy, module-level binding, fallback, cost/token strategy, error degradation, audit records, and white-box/grey-box/black-box acceptance. It does not target local model training, bundled model weights, GPU inference, or packaging a model runtime into the EXE.

Required provider families:

| Family | Examples | Product Treatment |
| --- | --- | --- |
| International hosted model APIs | OpenAI-compatible services, Claude-compatible services, Gemini-compatible services, Mistral-compatible services, Cohere-compatible services | User configures endpoint, API key reference, model name and capability role. |
| Domestic hosted model APIs | DeepSeek-compatible services, Qwen-compatible services, Zhipu-compatible services, Baidu-compatible services, Tencent-compatible services, Moonshot-compatible services, MiniMax-compatible services, Baichuan-compatible services, iFlytek-compatible services | User configures endpoint, API key reference, model name and capability role. |
| OpenAI-compatible custom endpoint | Self-hosted gateways, enterprise proxies, cloud-compatible endpoints | Treat as custom external API with explicit endpoint, headers, model name and health smoke. |
| Embedding APIs | Hosted or enterprise embedding services | Separate capability role, dimension check, sample embedding smoke and vector-index compatibility evidence. |
| Rerank / verification APIs | Hosted rerank, citation verification or evaluator services | Optional capability role with bounded input, source_trace and validation_report evidence. |

Provider names are configuration choices, not ordinary product modules. Ordinary UI should expose product concepts such as AI model service, embedding service, verification model and connection test. Developer reports may record provider refs and model IDs with secrets masked.

## Capability Roles

Each configured model must declare the role it is allowed to serve:

- chat_answer
- document_generation
- skill_generation
- agent_reasoning
- agent_review
- retrieval_verification
- citation_verification
- ocr_repair
- embedding
- rerank

Missing role support must fail closed with a clear user action, not silently route to an arbitrary model.

## Capability Probe Fields

Each P2 model probe must record:

- provider_family,
- model_alias,
- supported_roles,
- context_window_class,
- cost_class,
- latency_class,
- streaming_supported where applicable,
- structured_output_supported where applicable,
- embedding_dimension for embedding roles,
- health_status,
- failure_reason when not available,
- fallback_priority,
- masked_secret_status.

## Selection Policy

Model selection must be deterministic for the same module, task role, token mode and available provider set. The selector may consider:

- module binding,
- required capability role,
- token mode: Economy, Standard or Deep,
- cost class,
- latency class,
- context-window class,
- reliability or previous smoke status,
- fallback priority,
- region or endpoint family where user configured it.

The selector must record the selected model alias, role, decision reason and fallback reason when applicable. It must not silently route an unsupported role to another model.

## Required Evidence For User Selection

- config schema,
- health or readiness test,
- masked secret handling,
- failure degradation,
- audit record,
- rollback path,
- downstream binding evidence.

## P2 Model API Acceptance Evidence

Before a model provider can be marked user-selectable in P2, the evidence package must include:

- masked configuration read/write evidence,
- harmless minimal request smoke for chat-like models,
- sample embedding and dimension check for embedding models,
- capability probe report,
- deterministic selection policy report,
- module-level binding report,
- timeout, rate-limit and authentication failure handling,
- module-level binding evidence for at least two product modules,
- fallback or disabled-state evidence when a provider fails,
- cost/token policy interaction evidence for Economy, Standard and Deep,
- Event Ledger record with provider family, role, model alias, latency class and masked secret status,
- no plaintext API key, token, cookie or authorization header in reports,
- no local model training, no bundled model weights and no GPU runtime requirement.

## Prohibited Claims

- Do not call a health check workflow execution.
- Do not call a template asset a runtime Provider.
- Do not call a test-only model route a release Provider.
- Do not expose external project names as normal user modules.
- Do not call an unverified endpoint a supported model provider.
- Do not call OpenAI-compatible syntax proof full model-family compatibility.
- Do not claim domestic or international broad support without at least configuration, smoke, fallback and masked-secret evidence for representative provider families.
