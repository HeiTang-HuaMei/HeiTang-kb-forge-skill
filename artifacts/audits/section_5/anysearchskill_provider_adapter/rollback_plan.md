# Rollback Plan

1. Remove only the new AnySearch adapter module, its CLI registrations, focused tests, and Section 5 item 5.3 audit artifacts.
2. Restore the AnySearch registry/UI boundary to `provider_required` and `planned_adapter`.
3. Remove the AnySearch Fast Gate entry and impact rule without changing other gates.
4. Do not modify system proxy settings, global environment variables, user credential stores, or external services.
5. If the live anonymous smoke fails, retain the failure evidence and classify the integration as `needs_strengthening`; do not report runtime readiness.
