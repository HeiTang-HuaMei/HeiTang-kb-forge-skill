# Workspace Path Boundary Policy

All future workspace operations must use workspace-relative asset references.

Rejected path behavior:

- `../` parent-directory escape
- absolute path escape
- repo-root output
- system path output
- home/profile path output
- open-any-path behavior
- implicit cross-workspace read

Repair rule: convert user input into an allowlisted workspace asset reference,
then preserve source trace and audit scope.
