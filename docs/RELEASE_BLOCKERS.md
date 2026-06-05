# Release Blockers

v2.5 detects release blockers such as missing required files, failed local checks, unsafe platform claims, missing mock boundaries, suspicious secrets, and dangerous command snippets.

Critical blockers set `release_ready=false`.

XHS must be documented as not being an official XHS upload API. MCP must remain stub-only. OpenClaw, Codex, and Claude Code must not be described as real runtimes executed by v2.5.

