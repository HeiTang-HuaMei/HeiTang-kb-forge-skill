# Rollback Plan

1. Remove the local engineering governance rule-pack module if 5.13 evidence is rejected.
2. Remove the 5.13 focused tests and validation gate entry.
3. Remove mattpocock_skills from external registry/UI capability status if registry validation fails.
4. Remove this run from AUDIT_MANIFEST/AUDIT_INDEX and restore plan/ledger next item to 5.13.
5. Do not alter earlier Section 5 evidence or global WorkSpace rules.

No external repository clone, dependency install, global PATH change, or user data migration is involved.
