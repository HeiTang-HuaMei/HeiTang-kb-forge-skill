# Unstructured Dependency Remediation Report

- Adapter: `unstructured`
- Missing dependencies: none
- Install attempted: `false`
- Post-install check: `available`
- Post-install smoke: `pass`
- Final decision: `real_integration`
- Blocker evidence: None
- Install commands:
  - `python -m pip install -e ".[parser-unstructured]"`
  - `python -m pip install "unstructured[md]>=0.16,<1"`
- Rollback steps:
  - Remove the project-local environment or uninstall unstructured from the selected environment.
  - Re-run check-unstructured-backend and smoke-unstructured-backend.
