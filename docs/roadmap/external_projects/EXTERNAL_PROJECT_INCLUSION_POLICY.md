# External Project Inclusion Policy

This policy governs pre-v4 external project registry entries.

## Allowed Before v4

- Record project identity, rating, current repo status, mapped capabilities, and post-v4 target.
- Map known Core evidence files when the repo already contains benchmark or planned-adapter references.
- Mark provider, network, external runtime, license, and security review boundaries.
- Add docs and tests proving the registry remains a registry.

## Not Allowed Before v4

- Implement external project functionality.
- Copy external project code, prompts, configs, or raw outputs.
- Add new external dependencies.
- Call external APIs or providers.
- Bundle n8n or any other external runtime.
- Mark planned adapters, future adapters, provider-required actions, or needs-verification entries as ready.
- Change P1 real workflow evidence or final gate status.
- Start v4.0, create a tag, or write a release.

## Review Rule

Every S/A project needs a post-v4 target and an explicit boundary before any future contract inclusion. Every provider, network, or external-runtime entry must stay `can_be_ready_before_v4=false`.
