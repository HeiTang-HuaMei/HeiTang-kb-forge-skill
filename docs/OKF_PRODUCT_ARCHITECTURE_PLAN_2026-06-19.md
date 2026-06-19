# OKF Product Architecture Plan - 2026-06-19

This document records a future product architecture layer only. It does not introduce runtime behavior, UI navigation, or user-visible feature changes in the current rc10 structure-cleanup slice.

## Official Baseline

OKF refers to Open Knowledge Format as defined in the `GoogleCloudPlatform/knowledge-catalog` repository. HeiTang KB Forge will treat that SPEC as the future baseline for an open knowledge format layer that makes parsed knowledge executable, portable, versionable, and reusable across the product.

- SPEC: <https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md>
- Repository: <https://github.com/GoogleCloudPlatform/knowledge-catalog>

The current baseline is OKF version 0.1 draft. The SPEC defines OKF as an open, human- and agent-friendly knowledge representation format. Its minimal structure is a directory of Markdown files with YAML frontmatter, without requiring a schema registry, central authority, or mandatory tooling.

The linked repository includes the implementation source materials for this architecture baseline, while also stating that the repository contents are not an official Google product. Product copy and acceptance documents must therefore describe OKF as a format/specification baseline, not as a built-in Google service or already-enabled HeiTang runtime capability.

For HeiTang KB Forge, OKF must be treated as a product architecture standardization layer, not as a new product area. Future implementation must follow these official concepts:

- Knowledge Bundle: a self-contained hierarchical collection of knowledge documents and the unit of distribution.
- Concept: one Markdown document representing one knowledge unit.
- Concept ID: the concept file path without the `.md` suffix.
- Frontmatter: a YAML metadata block at the top of each concept file.
- Body: Markdown content after the frontmatter.
- Links: standard Markdown links between concepts.
- Citations: links from concept content to supporting external sources.

Future OKF export should respect the official bundle model:

- A bundle is a directory tree of Markdown files.
- `index.md` and `log.md` are reserved filenames.
- Bundles may be distributed as Git repositories, archive files, or subdirectories in larger repositories.
- Every non-reserved `.md` concept should contain parseable YAML frontmatter.
- Every concept frontmatter must contain a non-empty `type` field.
- Consumers should tolerate optional-field gaps, unknown types, unknown frontmatter keys, broken links, and missing index files.

Owner context: OKF is intended here as the executable standardization layer that turns the LLM Wiki idea into a concrete product specification for HeiTang KB Forge. The future implementation source of truth remains the linked OKF SPEC above.

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
