# AnySearchSkill Integration Decision

- Section: `5.3`
- Decision: `needs_strengthening`
- Integration mode: `provider_adapter`
- Core adapter: implemented
- External runtime bundled: no
- External code copied: no
- API key: optional, environment-only
- Real anonymous smoke: passed
- Real retrieval run: passed
- Source trace: 3 non-empty sources
- Secrets persisted: no

The provider adapter supports disabled mode, configurable base URL, proxy and reverse-proxy fields, structured anonymous mode, proxy errors, and normalized source trace. Both the real anonymous smoke and the real retrieval command called the documented AnySearch MCP endpoint successfully.

The decision remains `needs_strengthening` because the desktop External Source Center and Local Core Bridge do not yet configure or execute the provider, real proxy-path smoke has not run, and provider terms remain a release-stage review item. Campaign 3 is still in progress.

Next required item: Section 5 item 5.4 n8n only.
