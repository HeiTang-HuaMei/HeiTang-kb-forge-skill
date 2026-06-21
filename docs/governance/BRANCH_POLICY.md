# Branch Policy

## Branches

- `main`: protected product history.
- `feature/workbench-ui-prototype`: current Workbench product branch.
- short-lived feature branches: one gate or repair scope only.

## Rules

- Do not rewrite shared branch history without Owner approval.
- Do not delete historical tags.
- Do not create stable tags from feature gates.
- Keep unrelated dirty files out of commits.
- Keep build outputs, generated runtime outputs, and local logs out of commits.

## Required Before Merge

- PR fast gate green.
- Product baseline impact declared.
- Secret and overclaim scans clean or manually reviewed.
- Owner retest checklist attached when the change affects EXE behavior, user path, Provider configuration, Agent/A2A runtime, or release policy.
