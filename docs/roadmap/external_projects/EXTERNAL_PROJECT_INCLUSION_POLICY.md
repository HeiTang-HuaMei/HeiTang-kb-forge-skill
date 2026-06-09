# External Project Inclusion Policy

External GitHub projects may enter HeiTang KB Forge through registry, benchmark, template, planned_adapter, future_adapter, provider_required, or capability_anchor contracts before implementation.

Inclusion does not imply that the project is installed, ready, available, executable, or bundled.

## Rules

- No external project code is copied by contract inclusion.
- No external dependency is added by contract inclusion.
- No provider API is called by contract inclusion.
- No API key, token, local provider profile, or raw private input is committed.
- Provider, network, secret, and external runtime requirements must stay blocked until explicit user configuration and post-v4 implementation evidence exist.
- planned_adapter and future_adapter entries must stay not ready.
- needs_verification entries must not become executable actions.
- template_reference entries may only appear as scenarios or template references.
- Contract inclusion must not change the P1 gate, start v4.0, create a tag, or write a release.
