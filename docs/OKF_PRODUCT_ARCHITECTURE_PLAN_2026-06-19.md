# OKF Product Architecture Plan - 2026-06-19

This document records a future product architecture layer only. It does not introduce runtime behavior, UI navigation, or user-visible feature changes in the current rc10 structure-cleanup slice.

## Placement

OKF is an internal standardization layer between Document Library and Knowledge Base.

User-facing path remains:

```text
Document Library -> Build Knowledge Base
```

Internal product path becomes:

```text
Import sources
-> Document Library
-> OKF standardization package
-> Knowledge Base build
-> Retrieval and verification
-> Template-driven document generation
-> Skill / Agent usage
```

OKF must not become a first-level navigation item.

## Product Definition

Document Library stores parsed, cleaned, and structured source content.

OKF standardization packages wrap Document Library content as portable, versioned, auditable, reusable knowledge assets using Markdown plus YAML frontmatter.

Knowledge Base builds indexes, vectors, retrieval, citations, and generation capability from Document Library content or OKF packages.

## Future Page Placement

Document Library should surface:

- Standardization status
- OKF package count
- Latest standardization time
- Standardization failure reason
- Regenerate OKF
- Export OKF Bundle

Knowledge Base should surface:

- Source: Document Library content
- Source: OKF package
- OKF version
- Citation source
- Build time
- Fallback state

Artifact Center should recognize:

- OKF Bundle
- OKF manifest
- OKF Markdown files
- OKF metadata

Audit Center should record:

- Document Library -> OKF standardization
- OKF -> Knowledge Base build
- OKF export
- OKF version changes

## Version Plan

### rc10

Continue engineering structure cleanup only.

No OKF runtime code, no OKF UI menu, and no main flow behavior change.

### rc11

Update product architecture, PRD, acceptance checklist, user behavior path, and page design notes to include OKF as the internal standardization layer between Document Library and Knowledge Base.

No OKF runtime implementation.

### rc12

Implement Document Library -> OKF export:

- Export OKF Bundle
- Generate OKF manifest
- Record source, title, tags, version, time, and citations
- Show OKF artifacts in Artifact Center
- Record OKF export in Audit Center

Do not force all Knowledge Base builds to use OKF.

### rc13

Implement OKF -> Knowledge Base build:

- Build KB from OKF Bundle
- Keep direct Document Library -> KB build as fallback
- Record whether KB source is OKF or Document Library
- Preserve chunks/cards/qa/quality report generation
- Persist status after restart

### rc14

Implement OKF + Skill personalization:

- Imported external Skill can localize against OKF / KB
- Skill manifest records OKF source, KB source, and versions

### rc15

Implement OKF + Agent usage:

- Agent inherits OKF source, tags, versions, and citations through KB / Skill
- Agent answers, dialogue export, and A2A output remain traceable to knowledge sources
- Agent cannot bypass KB to call unstandardized content directly

## Current Boundaries

Current rc10 work is limited to structure cleanup.

Do not:

- Add OKF first-level navigation
- Add OKF runtime methods
- Change the document generation main chain
- Rename `rc6_runtime`
- Move tests in bulk
- Create a stable tag or GitHub Release
