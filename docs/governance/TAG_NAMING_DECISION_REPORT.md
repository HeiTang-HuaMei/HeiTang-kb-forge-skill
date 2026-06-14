# Tag Naming Decision Report

Generated at: 2026-06-14T13:52:14+08:00

## Decision

Current Campaign 1-3 work is a campaign closure and baseline validation chain, not a product version release.

Do not create any new `v3.0.x-integrated-closure` tags. Campaign 1-3 baseline CI validation must use:

```text
campaign-1-3-baseline-rc.1
campaign-1-3-baseline-rc.2
campaign-1-3-baseline-rc.N
```

After CI / Release Check and Closure Checklist are green, the stable campaign baseline tag may be:

```text
campaign-1-3-baseline
```

Product version tags remain reserved for real product releases, for example `v4.2.x` or `v4.3.x`.

## Historical Tags

The following tags are recorded as superseded CI validation tags caused by historical naming policy drift. They are not formal release tags, not baseline tags, and not product version tags:

| tag | release association | decision |
| --- | --- | --- |
| `v3.0.3-integrated-closure` | none found by `gh release view` | keep tag; superseded CI validation tag |
| `v3.0.4-integrated-closure` | none found by `gh release view` | keep tag; superseded CI validation tag |
| `v3.0.5-integrated-closure` | none found by `gh release view` | keep tag; superseded CI validation tag |

`gh release list --limit 50` only showed product releases `v4.2.0`, `v4.1.1`, and `v4.1.0` during this check. No GitHub Release was found for the listed `v3.0.x-integrated-closure` tags.

## Campaign Baseline RC Validation

The corrected Campaign 1-3 baseline validation tag currently used for CI/CL evidence is:

```text
campaign-1-3-baseline-rc.3
```

Validation facts:

- `campaign-1-3-baseline-rc.1` was created under the corrected naming policy, but clean-checkout CI failed.
- `campaign-1-3-baseline-rc.2` was created after repair and CI passed, but Release Check did not trigger, so it was not a green CI/CL chain.
- `campaign-1-3-baseline-rc.3` points to commit `09590d8d4ff03310cd5c55b055631fa009350d4d`.
- CI run `27489725099` for `campaign-1-3-baseline-rc.3` completed with `conclusion=success`.
- Release Check run `27489725098` for `campaign-1-3-baseline-rc.3` completed with `conclusion=success`.
- `gh release view campaign-1-3-baseline-rc.3` returned no GitHub Release.

This RC tag is a campaign baseline validation tag only. It is not a product version tag, not a formal release tag, not a GitHub Release, not a commercial stable release, not EXE delivery, and not Campaign 4 entry.

## Stable Baseline Tag Failure Correction

Recorded at: 2026-06-14T15:17:56+08:00

The attempted stable campaign baseline tag `campaign-1-3-baseline` is recorded as a failed pre-cleanup baseline tag. It must not be treated as a final baseline, product release, GitHub Release, or Campaign 4 entry signal.

Correction facts reported by the user:

- `gh release view campaign-1-3-baseline` returned release not found.
- `git push origin :refs/tags/campaign-1-3-baseline` succeeded.
- `git tag -d campaign-1-3-baseline` succeeded.
- `git ls-remote origin refs/tags/campaign-1-3-baseline` returned no output.
- `git tag --list campaign-1-3-baseline` returned no output.

Decision record:

| tag | status | final baseline | product release | GitHub Release | local/remote state |
| --- | --- | --- | --- | --- | --- |
| `campaign-1-3-baseline` | `superseded_failed_pre_cleanup_baseline_tag` | `not_final_baseline` | `not_product_release` | `no_github_release` | `deleted_from_remote_and_local` |

The failed pre-cleanup `campaign-1-3-baseline` tag must not be recreated in this correction step. Stable baseline reassessment is blocked until the next public repository cleanup/rename/restructure instruction is completed and a later campaign baseline RC validation chain is explicitly allowed.

## Safety Rules

- Do not delete these historical tags in this correction step.
- Do not attach GitHub Releases to them.
- Do not use them as formal baseline tags.
- Do not treat them as product version tags.
- Do not generate a Release for Campaign 1-3 baseline validation.
- Release Check must trigger for `campaign-1-3-baseline-rc.*` and `campaign-1-3-baseline` tags; a CI-only green RC is not enough.
- Do not enter Campaign 4 from tag creation alone.
- Do not recreate `campaign-1-3-baseline` after the failed pre-cleanup deletion correction.
- Do not create a GitHub Release for `campaign-1-3-baseline`.

## Current Next Safe Action

```text
Wait for Clean Public Repository Rename & Restructure instruction
```

The failed pre-cleanup stable baseline tag correction has been recorded only. Do not continue stable `campaign-1-3-baseline` tag closure, do not recreate `campaign-1-3-baseline`, do not create a GitHub Release, and do not enter Campaign 4. The run must stop and wait for the next Clean Public Repository Rename & Restructure instruction.
