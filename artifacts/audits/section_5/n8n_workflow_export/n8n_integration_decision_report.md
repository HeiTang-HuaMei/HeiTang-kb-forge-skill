# n8n Integration Decision

- Section: `5.4`
- Decision: `real_integration`
- Integration mode: `workflow_export`
- Local exporter: implemented
- Export validation: passed
- n8n runtime integrated: no
- n8n runtime bundled: no
- n8n runtime started: no
- External code copied: no
- Credentials embedded: no
- Dangerous command nodes: 0

`real_integration` is limited to the requested workflow export, webhook contract, external automation manifest, and offline validator. Import and execution require a user-owned n8n instance and are not claimed.

The generated workflow is inactive and contains only a Webhook node and Respond to Webhook node.

Next required item: Section 5 item 5.5 MMSkills only.
