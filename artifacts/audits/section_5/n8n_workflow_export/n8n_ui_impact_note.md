# n8n UI Impact

Current UI status:

- `workflow_export_adapter`
- `export_validation_passed`
- `runtime_not_bundled`
- blocked reason: `external_runtime_required`

The Task / Job Center and Template Library may display this status. They must not claim that n8n is bundled, imported, running, or workflow execution passed.

The later UI and Core Bridge campaigns must add allowlisted export and validation actions under External Module / Workflow Export settings.
