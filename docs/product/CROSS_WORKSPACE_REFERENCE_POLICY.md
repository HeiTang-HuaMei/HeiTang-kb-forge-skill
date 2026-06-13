# Cross-Workspace Reference Policy

Default rule: workspace assets are private to their owning `workspace_id`.

Allowed cross-workspace access requires an explicit reference record with:

- requesting_workspace_id
- source_workspace_id
- asset_id or kb_id
- access_scope
- reason
- source_trace
- audit_scope

Forbidden by default:

- implicit cross-workspace reads
- global knowledge-base search without a scope
- global Agent memory reads
- denied_kb_ids being overridden by allowed scopes
- treating imported or cloned knowledge as the original source without trace
