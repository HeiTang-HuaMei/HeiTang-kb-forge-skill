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

## Safety Rules

- Do not delete these historical tags in this correction step.
- Do not attach GitHub Releases to them.
- Do not use them as formal baseline tags.
- Do not treat them as product version tags.
- Do not generate a Release for Campaign 1-3 baseline validation.
- Release Check must trigger for `campaign-1-3-baseline-rc.*` and `campaign-1-3-baseline` tags; a CI-only green RC is not enough.
- Do not enter Campaign 4 from tag creation alone.

## Current Next Safe Action

```text
Closure Checklist Green verification only
```

The tag naming policy correction and campaign baseline RC CI/CL validation have passed through `campaign-1-3-baseline-rc.3`. Do not create any new `v3.0.x-integrated-closure` tag. Do not create a GitHub Release. Do not create the stable `campaign-1-3-baseline` tag until the ordered Closure Checklist is green. Campaign 4, Campaign 5, Full Gate, EXE packaging, and Release remain blocked until the ordered gates pass.
