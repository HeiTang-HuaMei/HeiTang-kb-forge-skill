# Tag Policy

Tags are release evidence, not task markers.

## Stable Tags

Stable tags require:

- current product baseline agreement,
- release gate green,
- Owner retest sign-off,
- no-secret scan pass,
- overclaim scan pass,
- release notes that do not overstate runtime integration.

## Release Candidate Tags

RC tags require:

- rc candidate gate green,
- explicit remaining risks,
- no claim that unverified external projects are integrated.

## Prohibited

- Do not tag `stable` from normal cleanup or governance work.
- Do not create `v4.3.0` stable until the release policy conditions are satisfied.
- Do not move or delete historical tags without Owner approval.
