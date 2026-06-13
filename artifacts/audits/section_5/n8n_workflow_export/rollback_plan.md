# Rollback Plan

1. Remove only the n8n export module, its CLI commands, focused tests, and Section 5 item 5.4 evidence.
2. Restore n8n to its prior future-adapter registry status.
3. Remove the n8n Fast Gate entry without changing other validation gates.
4. Do not remove or alter any external n8n installation because this task does not install one.
5. If export validation fails, retain the failure evidence and classify the integration as `needs_strengthening`; do not claim import or runtime success.
