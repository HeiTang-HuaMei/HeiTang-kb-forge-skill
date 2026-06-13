# Rollback Plan

If Section 5 item 5.12 validation fails:

1. Remove only the newly added `heitang_kb_forge/cross_modal_rag_schema` module and its dedicated tests.
2. Remove only the two dedicated cross-modal RAG CLI registrations.
3. Revert only the RAG-Anything registry, workbench status, UI asset, governance, audit index, and Fast Gate entries added by this run.
4. Remove only `artifacts/audits/section_5/rag_anything_cross_modal_rag_schema`.
5. Regenerate the existing S/A contract assets from the pre-run registry.
6. Re-run the prior 5.11 focused gate and sequence tests.

No external runtime, model cache, provider state, database, system dependency, global PATH, registry setting, remote branch, tag, or release is modified, so no machine-level rollback is required.
