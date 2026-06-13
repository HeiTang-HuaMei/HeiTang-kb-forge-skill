# OpenDataLoader Dependency Remediation Report

- Adapter: `opendataloader`
- Missing dependencies: opendataloader-pdf, Java 11+
- Install attempted: `false`
- Post-install check: `blocked_by_dependency`
- Post-install smoke: `blocked`
- Final decision: `needs_strengthening`
- Blocker evidence: Optional dependency 'opendataloader-pdf' or Java 11+ is not installed. Install the parser-opendataloader extra, ensure Java is on PATH, or use backend=builtin.
- Install commands:
  - `python -m pip install opendataloader-pdf>=2,<3`
  - `Install Java 11+ and ensure java is on PATH.`
- Rollback steps:
  - Remove the project-local environment or uninstall opendataloader-pdf from the selected environment.
  - Remove or disable any Java runtime added solely for this adapter.
  - Re-run check-opendataloader-backend and smoke-opendataloader-backend.
