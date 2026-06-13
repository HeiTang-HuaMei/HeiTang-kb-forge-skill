# Pre-Action Checkpoint

- Scope: Section 5 item 5.4 n8n only
- Action: implement an n8n workflow export adapter, webhook contract, validation, and UI status evidence
- External repository: `https://github.com/n8n-io/n8n`
- Runtime boundary: n8n runtime will not be installed, bundled, started, or called
- Network boundary: export and validation are offline
- Credential boundary: generated workflow contains no credentials, tokens, API keys, or secret values
- Execution boundary: generated workflow is inactive and contains no arbitrary command execution node
- Campaign boundary: Campaign 3 remains in progress; Campaign 4 remains blocked
- Final target: not complete
