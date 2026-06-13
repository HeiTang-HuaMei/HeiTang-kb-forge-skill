# OpenDataLoader Portable Java Rollback Plan

- Delete `_local_dependency_remediation/opendataloader/java`.
- Delete the downloaded JRE ZIP after retaining version and checksum evidence.
- Remove only the process-local `JAVA_HOME` and `PATH` additions used by the smoke command.
- Do not change the machine registry or global PATH.
- Re-run `check-opendataloader-backend` to verify the rollback state.

Rollback is confined to the current project.
