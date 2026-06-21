# Security Policy

## Secret Handling

Secrets must not be committed, rendered in UI, written to logs, or exported by default.

Protected values include:

- API keys and bearer tokens.
- Redis passwords.
- Vector DB tokens.
- Provider credentials.
- External service credentials.

Configuration files may store only masked values or references such as `api_key_ref` and `password_ref`.

## Reporting

Open a private security report with:

- Affected file or workflow.
- Impact and reproduction steps.
- Whether any secret was exposed.
- Whether generated output, logs, or CI artifacts are involved.

Do not paste real secrets into issues, PRs, comments, docs, or test fixtures.

## Release Security Gate

Before a release candidate can move forward:

- no-secret scan must pass,
- overclaim scan must pass,
- provider credentials must remain masked,
- external runtime status must not be overstated,
- release notes must match the v3 product baseline.
