# UI Information Architecture

v1.2.3 is the short-term final UI skeleton.

## Freeze Rules

- The UI information architecture is frozen.
- Future work should add fields, backend wiring, bug fixes, and small style adjustments only.
- The left navigation structure should not be rebuilt.
- The desktop UI remains a presentation layer over the Python CLI.

## Fixed Pages

1. Dashboard
2. Build Package
3. Batch Processing
4. Workspace
5. Lifecycle Update
6. Quality Gate
7. Package Detail
8. Ask Runtime
9. Publish Export
10. Planning Readiness
11. Settings

## Style

- default dark mode
- black / white / gray industrial tool style
- fixed sidebar
- top status bar
- card-based dashboard
- unified empty / success / error / log regions
- raw JSON and raw logs collapsed by default

## Skill-first Boundary

The desktop UI does not own the core engine. OpenClaw, Claude Code, Codex, other Agent frameworks, local CLI users, and future runtimes must continue to call the same headless Python package and CLI.
