# Tag Candidate Gate Report

Generated: 2026-06-22

Gate: `tag_candidate_gate`

## 1. Current Branch

```text
feature/workbench-ui-prototype
```

## 2. Current HEAD

```text
a9709e5 docs: verify release candidate gate
```

## 3. Version Source

Primary version source:

```text
web/workbench/flutter_app/pubspec.yaml
```

Recorded value:

```text
version: 4.2.0+1
```

Version selected for RC tag:

```text
4.2.0
```

Build number:

```text
1
```

Secondary confirmation:

```text
pyproject.toml: version = "4.2.0"
```

Existing `v4.2.0-rc.*` tags:

```text
none
```

## 4. Target RC Tag Name

```text
v4.2.0-rc.1
```

Tag type:

```text
annotated RC tag
```

This is not a stable release tag.

## 5. Release Candidate Preconditions

Confirmed previous gate state:

```text
release_candidate_verified
allowed_next_gate: tag_candidate_gate
```

Current HEAD includes:

```text
a9709e5 docs: verify release candidate gate
```

## 6. EXE Smoke Evidence Directory

Latest RC verification smoke evidence:

```text
web/workbench/flutter_app/output/windows_exe_smoke/windows_exe_smoke_20260622_190023/
```

## 7. Windows Native EXE Smoke

Result:

```text
passed
```

Verifier summary:

```text
final_status: windows_exe_smoke_passed
allowed_next_gate: release_candidate_gate
automation_path: windows_native_product_verifier
navigation_status: passed
main_chain_status: passed
product_bug_confirmed: false
```

## 8. Output / Build / Log / Screenshot Submission Check

The following generated evidence and build paths are not submitted by this gate:

```text
web/workbench/flutter_app/output/
web/workbench/flutter_app/build/
screenshots/
logs/
```

## 9. External Adoption Document

Known unrelated dirty file:

```text
docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md
```

This file is intentionally left untouched, unstaged, and excluded from this gate.

## 10. GitHub Release Check

No GitHub Release was created.

No formal release was published.

This gate only permits an annotated RC tag.

## 11. Permission To Create RC Tag

Current Git status check:

```text
only docs/EXTERNAL_PROJECT_ADOPTION.zh-CN.md remains dirty
```

Decision:

```text
allowed_to_create_rc_tag: true
target_tag: v4.2.0-rc.1
```

