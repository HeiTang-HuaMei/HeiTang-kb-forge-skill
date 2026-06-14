# Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate Plan

This gate governs the public repository surface before push, tag, CI verification, and Campaign 4 Entry. It is registered now as a future gate only.

## Execution Position

This gate may execute only after all of the following are true:

1. Campaign 3 Supplement 4.0 Knowledge-to-Skill Template Generator completed.
2. Campaign 3 Supplement 4.0 Acceptance Gate passed.
3. Campaign 3 Final Consistency Gate passed.
4. Campaign 1-3 Stage / Functional Test Gate passed.
5. Campaign 1-3 Integrated Closure Gate passed.
6. Closure Pack generated.

Locked order:

```text
4.0 completed
-> Campaign 3 Final Consistency Gate
-> Campaign 1-3 Stage / Functional Test Gate
-> Campaign 1-3 Integrated Closure Gate
-> Closure Pack generated
-> Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate
-> push
-> tag
-> CI Green verification
-> Closure Checklist Green
-> Campaign 1-3 Integrated Review and New Conversation Handoff Gate
-> Campaign 4 Entry Gate
```

This gate must not run early. Current Campaign 3 Supplement 4.0 implementation work does not execute repository cleanup, rename, push, tag, or CI verification.

## Goal

The goal is to govern the GitHub public surface before push/tag. It is not a historical evidence deletion task.

The gate must:

- classify active docs, milestone evidence, legacy root reports, temporary current-run files, and obsolete duplicate docs;
- keep local dependency directories, model caches, repository audit packs, current-run outputs, latest audit outputs, temp/build/dist/runtime environments, and package-manager directories out of commits;
- migrate public product naming to `HeiTang Knowledge Workbench`;
- preserve the Python import namespace `heitang_kb_forge` for compatibility;
- check forbidden tracked files, secrets, and large runtime binaries before push;
- allow tag only after push succeeds;
- allow Campaign 4 Entry only after tag-related CI/CL is green, Closure Checklist is green, and the Campaign 1-3 Integrated Review and New Conversation Handoff Gate passes.

## First Required Action

The first action is read-only inventory. Do not delete, move, rename, push, tag, or run CI as part of the inventory step.

Required inventory outputs:

```text
artifacts/audits/repository_public_surface_cleanup/file_inventory.json
artifacts/audits/repository_public_surface_cleanup/git_status_snapshot.txt
artifacts/audits/repository_public_surface_cleanup/tracked_files.txt
artifacts/audits/repository_public_surface_cleanup/untracked_files.txt
artifacts/audits/repository_public_surface_cleanup/large_file_report.json
artifacts/audits/repository_public_surface_cleanup/root_surface_report.json
artifacts/audits/repository_public_surface_cleanup/docs_surface_report.json
artifacts/audits/repository_public_surface_cleanup/artifacts_surface_report.json
```

Required statistics:

- root file count;
- root directory count;
- tracked file count;
- untracked file count;
- largest files;
- largest directories;
- root-level JSON/report files;
- `docs/audits` file count;
- `artifacts/audits` file count;
- ignored versus unignored local cache/dependency files.

Required special checks:

```text
_local_dependency_remediation/
.heitang_cache/
repo_surface_audit_pack/
repo_surface_audit_pack.zip
repo_tracked_snapshot.zip
dist/
build/
tmp/
.venv/
node_modules/
.dart_tool/
__pycache__/
.env
provider_config.yaml
token
secret
cookie
credential
```

## File Classes

Every file must be classified into one of:

- `active_docs`
- `milestone_evidence`
- `legacy_root_reports`
- `temporary_current_run`
- `obsolete_duplicate_docs`

Deletion candidates require a manifest entry with reason, replacement or archive path, and `safe_to_delete = true`. No file may be deleted merely because it looks old.

## Required Future Governance Outputs

```text
docs/governance/REPOSITORY_PUBLIC_SURFACE_CLEANUP_AND_RENAME_PLAN.md
docs/governance/PUBLIC_REPOSITORY_FILE_POLICY.md
docs/governance/DOC_RETENTION_POLICY.md
docs/governance/REPOSITORY_RENAME_MIGRATION_NOTE.md
docs/governance/RENAMING_COMPATIBILITY_MATRIX.json

artifacts/audits/repository_public_surface_cleanup/PUBLIC_SURFACE_FILE_INVENTORY.json
artifacts/audits/repository_public_surface_cleanup/ROOT_FILE_MIGRATION_MANIFEST.json
artifacts/audits/repository_public_surface_cleanup/DELETION_CANDIDATE_MANIFEST.json
artifacts/audits/repository_public_surface_cleanup/RENAMING_COMPATIBILITY_MATRIX.json
artifacts/audits/repository_public_surface_cleanup/PUBLIC_SURFACE_CLEANUP_REPORT.md
artifacts/audits/repository_public_surface_cleanup/UPDATED_GITIGNORE_REPORT.md
artifacts/audits/repository_public_surface_cleanup/PUSH_TAG_SAFETY_REPORT.md
```

## Gitignore Requirements

Before any push safety check can pass, `.gitignore` must cover:

```gitignore
_local_dependency_remediation/
.heitang_cache/
repo_surface_audit_pack/
repo_surface_audit_pack.zip
repo_tracked_snapshot.zip
artifacts/audits/current_run/
artifacts/audits/latest/
tmp/
tmp_*/
.cache/
.pytest_cache/
.coverage
coverage/
.venv/
node_modules/
.dart_tool/
build/
dist/
__pycache__/
.env
.env.*
!.env.example
provider_config.yaml
local_provider_config.yaml
*.secret
*.token
*.cookie
credentials.*
```

If any forbidden local dependency, cache, current-run, audit-pack, secret, or large runtime binary is already tracked, the gate must stop and report it. If removal from Git index is needed, use cached removal only and preserve local files unless the user explicitly requests deletion.

## Rename Compatibility

Public name:

```text
Old public name: HeiTang KB Forge Skill
New public name: HeiTang Knowledge Workbench
```

Repository recommendation:

```text
Old repo: HeiTang-kb-forge-skill
New repo: HeiTang-Knowledge-Workbench
```

Compatibility rules:

- Keep `heitang_kb_forge` import namespace.
- Keep existing CLI commands.
- New CLI alias `heitang-workbench` is optional and must be separately validated.
- Do not hard rename the Python package in this gate unless compatibility tests prove safe.

## Push / Tag / CI Safety

Push may run only after the safety report confirms:

- no forbidden tracked local dependency/cache/current-run/audit-pack files;
- no unreviewed staged files;
- no secret, token, cookie, credential, or unsafe local config;
- no large runtime binary or model weight unless explicitly allowed;
- required tests, JSON parse checks, README links, and `git diff --check` passed.

Tag may run only after push succeeds.

Campaign 1-3 baseline CI validation must use `campaign-1-3-baseline-rc.N` tags. Do not create new `v3.0.x-integrated-closure` tags; historical `v3.0.x-integrated-closure` tags are superseded CI validation tags only, not release tags, not baseline tags, and not product version tags. The final stable campaign baseline tag may be `campaign-1-3-baseline` only after CI / Release Check and Closure Checklist are green. Product version tags remain reserved for real product releases such as `v4.2.x` or `v4.3.x`.

Campaign 4 Entry may open only after tag-related CI/CL is green, Closure Checklist is green, and the Campaign 1-3 Integrated Review and New Conversation Handoff Gate writes:

```text
docs/governance/CAMPAIGN_1_2_3_INTEGRATED_REVIEW_REPORT.md
docs/governance/CAMPAIGN_1_2_3_EXTERNAL_PROJECT_INTEGRATION_REVIEW.md
docs/governance/CAMPAIGN_1_2_3_CAPABILITY_REVIEW_MATRIX.md
artifacts/audits/current_run/new_conversation_handoff_prompt.md
artifacts/audits/current_run/campaign_1_2_3_handoff_manifest.json
```

Those review and handoff files must contain real final commit hash, tag name, push status, CI status, Stage / Functional Test result, Integrated Closure result, Repository Cleanup / Rename / Push-Tag Safety result, `git diff --check` result, JSON parse result, forbidden tracked files check result, and secret check result. They must not be generated before those facts exist.

## Forbidden Misinterpretations

- Repository cleanup is not final release.
- Rename is not commercial release.
- Push is not release complete.
- Tag is not EXE ready.
- CI green is not Campaign 4 complete.
- Campaign 1-3 review and handoff reports are not Campaign 4 implementation.
- Pre-4.0 is not runtime isolation complete.
- 4.0 is not Campaign 4.
- Campaign 4 must not start before CI green.

`not_goal_complete = true`
