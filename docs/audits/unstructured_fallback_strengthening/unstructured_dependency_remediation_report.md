# Unstructured Dependency Remediation Report

- Adapter: `unstructured`
- Missing dependencies: unstructured
- Install attempted: `false`
- Post-install check: `blocked_by_dependency`
- Post-install smoke: `blocked`
- Final decision: `needs_strengthening`
- Blocker evidence: Optional dependency 'unstructured' is not installed. Install the parser-unstructured extra or use backend=builtin.
- Install commands:
  - `python -m pip install -e ".[parser-unstructured]"`
  - `python -m pip install "unstructured[md]>=0.16,<1"`
- Rollback steps:
  - Remove the project-local environment or uninstall unstructured from the selected environment.
  - Re-run check-unstructured-backend and smoke-unstructured-backend.
