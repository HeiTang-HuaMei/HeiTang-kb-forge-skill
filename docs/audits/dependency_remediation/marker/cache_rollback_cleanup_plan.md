# Marker / Surya Cache Rollback and Cleanup Plan

## Protected State

- Legacy cache: `C:\Users\Administrator\AppData\Local\datalab\datalab\Cache`
- Project cache: `D:\HeiTang-Codex-WorkSpace\Project_01_HeiTang_KB_Forge\kb-forge-skill\_local_dependency_remediation\marker\model_cache`
- The migration copies model files. It does not move or delete the legacy cache.
- No system `PATH`, registry entry, or global Java/Python setting is changed.

## Rollback

1. Stop Marker/Surya processes using the project cache.
2. Remove only the project-local `model_cache` directory after resolving and confirming that its absolute path remains under `_local_dependency_remediation\marker`.
3. Clear project-local `HEITANG_MARKER_MODEL_CACHE`, `HEITANG_SURYA_MODEL_CACHE`, and `MODEL_CACHE_DIR` overrides.
4. Re-run dependency checks. The retained legacy cache remains available for diagnosis, but normal HeiTang commands must not silently select it.

## Future Cleanup

1. Require successful workspace-local Markdown and JSON real smoke evidence.
2. Compare source and target file count and byte total.
3. Confirm no Marker/Surya process has the legacy cache open.
4. Create a separate destructive cleanup checkpoint naming the exact legacy path.
5. Delete the legacy cache only under that checkpoint and record reclaimed bytes.

Current decision: retain the C-drive cache. Automatic cleanup is prohibited in this remediation step.
