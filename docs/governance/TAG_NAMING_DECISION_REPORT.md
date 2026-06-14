# Tag Naming Decision Report

Generated at: 2026-06-14T12:12:14+08:00

## Decision

Current Campaign 1-3 work is a campaign closure and baseline validation chain, not a product version release.

Do not create any new `v3.0.x-integrated-closure` tags. Campaign 1-3 baseline CI validation must use:

```text
campaign-1-3-baseline-rc.1
campaign-1-3-baseline-rc.2
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

## Safety Rules

- Do not delete these historical tags in this correction step.
- Do not attach GitHub Releases to them.
- Do not use them as formal baseline tags.
- Do not treat them as product version tags.
- Do not generate a Release for Campaign 1-3 baseline validation.
- Do not enter Campaign 4 from tag creation alone.

## Current Next Safe Action

```text
Tag naming policy correction and campaign baseline CI validation only
```

Campaign 4, Campaign 5, Full Gate, EXE packaging, and Release remain blocked until the ordered gates pass.
