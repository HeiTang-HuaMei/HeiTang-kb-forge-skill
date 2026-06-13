# Campaign 3 Supplement 3.0: External Source Memory & Verification

This plan adds External Source Memory & Verification inside Section 5 / Campaign 3 without changing the user-approved 12-section total plan.

## Current State

- Plan state: `accepted_stop_pre_4_0_next`
- Current business item: `STOP before Campaign 3 Supplement 4.0 Entry Reconciliation Gate`
- Campaign 3 status: `accepted_for_campaign_1_3_stage_test_gate`
- Campaign 3 accepted: `true`
- Campaign 4 allowed: `false`
- Final goal complete: `false`

The P0 framework, Generic Web URL Ingestion, Platform Link Preflight, OpenCLI External Search Verification, Manual Evidence Upload, unified Source Trace / Evidence Map, progress events, failure isolation, External Link Import entry, Authenticated Browser Connector Alpha, Video-to-Knowledge / Visual Evidence Understanding foundations, and Knowledge Verification Engine/dashboard foundations have passed. The dedicated Acceptance Gate also passed after governed evidence review, focused Core and regression tests, relevant Flutter tests, and Flutter analysis. The Pre-4.0 Workspace Partition Foundation Gate has also passed as a foundation contract. `supplement_3_0_complete=true`; `campaign_4_active`, `campaign_5_active`, `ui_industrial_workbench_complete`, `local_core_bridge_complete`, and `bridge_execution_accepted` remain `false`. Execution stops before Campaign 3 Supplement 4.0 Entry Reconciliation Gate.

## Locked Sequence

Campaign 3 Supplement 2.0 has passed its closure gate. Campaign 3 Supplement 3.0 has passed its Entry Gate and P0 framework step:

1. `5.11 seedance2-skill`
2. `5.12 RAG-Anything`
3. `5.13 mattpocock/skills`
4. `5.14 Sirchmunk`
5. `5.S1 GBrain strengthening`
6. `5.S2 Horizon strengthening`
7. `5.S3 Obsidian-compatible Vault strengthening`
8. `Campaign 3 Supplement 2.0 closure gate`
9. `Campaign 3 Supplement 3.0 External Source Memory & Verification`
10. `Campaign 3 Supplement 3.0 Acceptance Gate`
11. STOP; Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate has passed.
12. `Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate`
13. `Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`
14. `Campaign 3 final consistency gate`
15. STOP; Campaign 3 Final Consistency Gate has passed.
16. `Campaign 3 Final Consistency Gate`
17. STOP; next safe action is `Run Campaign 1-3 Stage Test Gate only.`
18. `Campaign 1-3 Stage Test Gate`
17. `Campaign 1-3 Integrated Closure Gate`
18. `Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag, and CI/CL green verification`
19. `Campaign 4 Goal-Oriented Product UI Workbench Entry Gate`

The user's short sequence reference to `5.11-5.13` does not delete the already locked `5.14`, `5.S1-5.S3`, or their closure evidence. Supplement 3.0 is inserted after the passed Supplement 2.0 closure gate. Its Entry Gate, bounded industrial implementation items, Acceptance Gate, and the following Pre-4.0 foundation gate have passed. The next safe action is Campaign 3 Supplement 4.0 Entry Reconciliation Gate only.

After Supplement 3.0 acceptance, do not run Campaign 1-3 total closure directly. The Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate has passed as a foundation contract. Supplement 4.0 is a Campaign 3 internal supplement and must complete before the Campaign 3 Final Consistency Gate, Campaign 1-3 Stage Test Gate, Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag, CI/CL green verification, Closure Checklist green, and Campaign 4 Goal-Oriented Product UI Workbench Entry Gate.

## Product Definition

External Source Memory & Verification is the external-source layer of the HeiTang Agent knowledge supply chain.

It must:

1. Turn user-provided public links, platform links, documents, screenshots, long images, subtitles, audio, video, exported HTML, and notes into searchable, traceable knowledge assets.
2. Verify knowledge-base claims and answers against approved external public evidence, OpenCLI search results, visual evidence, and video segment evidence.
3. Preserve backlinks to the original URL, original video timestamp, image index, screenshot region, or manual evidence manifest.
4. Remain a user-triggered evidence and verification system, not an unrestricted crawler.

## Required Source Classes

- Public web pages and HTML
- Public documents and product documentation
- GitHub README content
- Blog articles and API/help documentation
- Xiaohongshu notes
- Douyin videos
- Zhihu articles and answers
- Bilibili videos
- WeChat public articles
- Weibo posts
- User-provided copied text and notes
- Screenshots, long images, subtitles, audio, video, exported HTML, tables, and other manual evidence

## Workstream A: Link-to-Knowledge Ingestion

Supported inputs:

- Single URL and multiple URLs
- `urls.txt`
- `links.csv`
- Browser bookmark HTML
- Links extracted from Markdown
- Copied body text
- Screenshot or long image
- Subtitle, audio, or video file
- Exported HTML
- Manual note

Every successful ingestion must produce normalized chunks, metadata, `source_trace`, `evidence_map`, `content_hash`, and a backlink.
All long ingestion and verification operations require progress events and failure isolation.

Backlinks must resolve to:

- The original web page for web content
- The original article for article content
- The original video plus timestamp for video segments
- The original image index or screenshot region for visual evidence
- The manual evidence manifest for user-provided material

## Workstream B: Generic Web URL Ingestion

Required pipeline:

```text
URL preflight
-> public readability decision
-> HTML fetch
-> main-content extraction
-> navigation/advertisement/footer cleanup
-> metadata extraction
-> chunk build
-> source trace
-> evidence map
```

Required metadata:

- `source_url`
- `source_type`
- `title`
- `author`
- `published_at`
- `retrieved_at`
- `content_hash`
- `language`
- `domain`
- `canonical_url`

Duplicate URLs and unchanged content hashes must be handled deterministically. Changed content must create refresh/change evidence.

## Workstream C: Platform Link Preflight

Platform links must be detected before generic page handling.

Required platforms:

- Xiaohongshu
- Douyin
- Zhihu
- Bilibili
- WeChat public articles
- Weibo
- Other or unknown platforms

Required preflight states:

- `public_readable`
- `partial_readable`
- `login_required`
- `auth_required`
- `blocked_by_platform`
- `anti_crawl_detected`
- `paywall_or_permission_required`
- `video_without_transcript`
- `needs_opencli_verification`
- `needs_manual_evidence`

An unreadable source must still record its platform, failure reason, structured state, and next available path. Silent failure is forbidden.

## Workstream D: OpenCLI External Search Verification

OpenCLI is an External Source Verification Adapter, not a page crawler.

Inputs may include:

- URL
- Claim
- Title
- Keywords

Required pipeline:

```text
input
-> public-source search
-> candidate-source discovery
-> multi-source comparison
-> confidence scoring
-> evidence map
-> verification report
```

OpenCLI output must enter the standard evidence pipeline. A natural-language summary alone is not accepted evidence.

OpenCLI must support graceful degradation when unavailable, rate-limited, or rejected by an external service.

## Workstream E: Authenticated Browser Connector

The connector is a user-authorized local visible-content reader. It is not a cookie import tool, simulated-login tool, platform crawler, anti-detection tool, or paywall bypass.

Required states:

- `auth_required`
- `user_authorized_session`
- `visible_content_readable`
- `visible_content_partial`
- `user_cancelled`
- `session_expired`
- `permission_denied`
- `manual_evidence_required`

Required boundaries:

- The user logs in independently.
- The user explicitly starts the read.
- Only content currently visible to the user may be read.
- Cookies must not be exported, imported, uploaded, or stored in plaintext.
- Login, CAPTCHA, platform controls, and paywalls must not be bypassed.
- The user can pause, revoke, and clear the authorized session.

## Workstream F: Manual Evidence Upload

Supported manual evidence:

- Copied text
- Screenshot and long image
- Video and audio
- Subtitle
- Exported HTML
- User note
- Screen-recording transcript
- Spreadsheet
- Image asset

Required outputs:

- `manual_evidence_manifest.json`
- `manual_evidence_blocks.jsonl`
- `manual_source_trace.json`
- `manual_evidence_map.json`
- `manual_evidence_validation_report.json`
- `manual_evidence_report.md`

Current status: `passed_manual_evidence_only`.

Evidence:

- `artifacts/audits/section_5/external_source_manual_evidence/run_manifest.json`
- `artifacts/audits/section_5/external_source_manual_evidence/manual_evidence_manifest.json`
- `artifacts/audits/section_5/external_source_manual_evidence/manual_evidence_blocks.jsonl`
- `artifacts/audits/section_5/external_source_manual_evidence/manual_source_trace.json`
- `artifacts/audits/section_5/external_source_manual_evidence/manual_evidence_map.json`
- `artifacts/audits/section_5/external_source_manual_evidence/manual_evidence_validation_report.json`
- `artifacts/audits/section_5/external_source_manual_evidence/manual_evidence_report.md`
- `tests/test_external_source_manual_evidence.py`

Manual evidence uses the same trace, evidence, failure-isolation, and progress contracts as fetched sources. Current implementation records copied or pasted text plus metadata-only manual file evidence; it blocks suspected API keys, tokens, cookies, passwords, and secrets; it does not read arbitrary local file content; and it must not be represented as OCR completion, authenticated browser reading, OpenCLI expansion, platform fetch success, video transcription, UI workflow acceptance, Core Bridge execution acceptance, or Supplement 3.0 acceptance.

## Workstream G: Video-to-Knowledge Ingestion

Supported sources:

- Douyin video
- Bilibili video
- Public video URL
- User-uploaded video
- User-uploaded subtitles
- User-uploaded audio

Required pipeline:

```text
video source
-> title/author/description
-> subtitle read or audio transcription
-> summary and segment location
-> keyframe extraction
-> keyframe OCR
-> video segment chunks
-> timestamp trace
-> original-video backlink
```

Video chunks must include:

- `source_url`
- `platform`
- `title`
- `author`
- `duration`
- `timestamp_start`
- `timestamp_end`
- `transcript`
- `ocr_text`
- `visual_summary`
- `chunk_id`
- `backlink`

## Workstream H: Visual Evidence Understanding

Required source types:

- Platform images and long images
- Video keyframes
- Product-document screenshots
- GitHub README images and architecture diagrams
- Tables, flowcharts, code screenshots, and presentation frames
- User-uploaded screenshots

Required pipeline:

```text
image/frame/screenshot
-> OCR
-> layout understanding
-> text/visual alignment
-> multimodal chunk
-> image trace
-> evidence map
```

Required chunk types:

- `text`
- `image_ocr`
- `video_segment`
- `video_keyframe_ocr`
- `table_ocr`
- `layout_block`
- `mixed_multimodal`

OCR failure must be isolated and reported without failing the entire import.

## Workstream I: Knowledge Verification Engine

Required verification pipeline:

```text
knowledge chunk, document, answer, or claim
-> claim extraction
-> external-source search
-> supporting-source collection
-> conflicting-source collection
-> credibility scoring
-> freshness checking
-> confidence scoring
-> correctness report
```

Required verification states:

- `verified`
- `partially_verified`
- `unsupported`
- `outdated`
- `conflicting`
- `low_confidence`
- `needs_human_review`

Required reports:

- `claim_verification_report.json`
- `claim_verification_report.md`
- `knowledge_correctness_report.json`
- `knowledge_correctness_report.md`
- `answer_grounding_report.json`
- `answer_grounding_report.md`

## Planned Core Package

The implementation may add `heitang_kb_forge/external_sources/` with focused modules for:

- source and platform preflight
- generic URL reading
- OpenCLI verification
- authenticated visible-content sessions
- manual evidence import
- video transcript and keyframe processing
- OCR and layout understanding
- multimodal chunk building
- source, timestamp, and image traces
- source confidence, claim extraction, conflict detection, freshness checks, and correctness reports

This directory is a planned implementation boundary, not evidence that the capability exists.

## Planned CLI and Core Actions

External link ingestion:

- `ingest-link`
- `batch-ingest-links`
- `import-bookmarks`
- `extract-links`
- `check-external-source`
- `refresh-external-source`

Platform handling:

- `detect-platform-link`
- `preflight-platform-link`
- `extract-platform-visible-content`

OpenCLI verification:

- `search-external-source`
- `verify-external-source`
- `build-external-evidence`

Authorized visible-content reading:

- `start-authenticated-browser-session`
- `read-visible-browser-source`
- `clear-authenticated-browser-session`

Manual evidence:

- `import-manual-evidence`
- `build-manual-evidence-map`

Video, OCR, and multimodal processing:

- `transcribe-video-source`
- `extract-video-keyframes`
- `extract-visual-evidence`
- `ocr-source-images`
- `build-multimodal-chunks`
- `build-image-trace`
- `build-timestamp-trace`

Knowledge verification:

- `verify-knowledge-base`
- `verify-answer`
- `verify-claims`
- `generate-correctness-report`

These names are planned contracts only until Campaign 3.0 implementation, tests, and real evidence exist.

## Campaign 3.0 Local Core Bridge Allowlist Impact

Every Campaign 3.0 Core action that is implemented must be explicitly added to the Local Core Bridge allowlist with parameter and no-shell tests before UI execution. The P0 action set must have real Core Bridge allowlist registrations in Campaign 3.0. Arbitrary shell execution is forbidden.

Allowlist presence alone will not satisfy Campaign 5 acceptance. Real user-task flow execution, parameter validation, path boundaries, timeout, structured errors, audit logging, and no-shell tests remain required in the Chain-Level Local Core Bridge campaign.

## Required Output Families

External source ingestion:

- `external_source_inventory.json`
- `external_source_preflight.json`
- `link_ingestion_report.json/.md`
- `external_fetch_report.json/.md`
- `external_source_trace.json`
- `external_evidence_map.json`
- `external_change_detection_report.json`

Platform handling:

- `platform_preflight_report.json`
- `platform_extract_report.json/.md`
- `platform_visible_content.jsonl`

OpenCLI verification:

- `external_search_candidates.jsonl`
- `external_verification_report.json/.md`
- `external_source_confidence.json`

Authorized browser reading:

- `auth_source_trace.json`
- `user_consent_record.json`
- `visible_content_extract.jsonl`
- `authenticated_source_evidence_map.json`

Video and visual evidence:

- `video_transcript.jsonl`
- `video_timestamp_trace.json`
- `video_keyframe_manifest.json`
- `video_keyframe_ocr_blocks.jsonl`
- `visual_evidence_manifest.json`
- `image_ocr_blocks.jsonl`
- `layout_blocks.jsonl`
- `multimodal_chunks.jsonl`
- `image_trace.json`
- `timestamp_trace.json`
- `visual_evidence_map.json`
- `visual_understanding_report.md`

## Chunk Metadata Contract

Every chunk must include or explicitly null:

```json
{
  "chunk_id": "...",
  "chunk_type": "text|image_ocr|video_segment|video_keyframe_ocr|table_ocr|layout_block|mixed_multimodal",
  "source_type": "...",
  "source_url": "...",
  "platform": "...",
  "title": "...",
  "author": "...",
  "published_at": "...",
  "retrieved_at": "...",
  "content_hash": "...",
  "text": "...",
  "ocr_text": "...",
  "visual_summary": "...",
  "timestamp_start": "...",
  "timestamp_end": "...",
  "image_index": "...",
  "bbox": "...",
  "backlink": "...",
  "evidence_id": "...",
  "confidence": "..."
}
```

## Campaign 3.0 UI Impact and Future Industrial Acceptance

Campaign 3.0 P0 must implement an External Link Import entry with truthful source states, progress, failure isolation, source trace, and backlink display for the implemented P0 path. Campaign 4 remains the authority for full Goal-Oriented Product UI Workbench acceptance across product-line task flows, reconciled pages, and truthful states.

Required future UI surfaces:

- External Link Import
- Authenticated Browser Connector
- Manual Evidence Upload
- Visual Evidence progress
- Knowledge Verification Dashboard

The UI must show platform type, readability state, failure reason, authorization/manual-evidence choices, OpenCLI verification state, OCR/transcription/chunk progress, source trace, and backlink.

The authorized-browser UI must state:

- only current visible content is read
- cookies are not uploaded or stored in plaintext
- login and CAPTCHA are not bypassed
- authorization can be revoked

## Safety and Compliance Lock

1. Do not bypass login.
2. Do not bypass paywalls.
3. Do not bypass CAPTCHA.
4. Do not bypass platform risk controls.
5. Do not save or upload user cookies.
6. Do not provide cookie import.
7. Do not perform high-frequency bulk platform collection.
8. Do not implement an unlimited crawler.
9. Process only links or evidence explicitly supplied or triggered by the user by default.
10. Recursive reading requires explicit enablement and bounded `depth`, `max_pages`, and `same_domain_only`.
11. Authorized browser reading is limited to current visible content.
12. Every read task is user-triggered.
13. The user can pause, revoke, and clear authorization.
14. Unreadable content must produce a structured reason.
15. Every external source must remain traceable.

Default network limits:

```text
url_depth = 0
max_pages = 1
same_domain_only = true
timeout = 30s
respect_robots = true
```

## Priority Lock

P0, required in Campaign 3.0:

- External Source Memory & Verification framework
- Generic Web URL Ingestion
- Platform Link Preflight
- OpenCLI External Search Verification
- Manual Evidence Upload
- Unified Source Trace and Evidence Map
- UI External Link Import entry and truthful status/progress path
- Core Bridge allowlist registrations and no-shell tests
- Progress events
- Failure isolation

P1, complete when feasible in Campaign 3.0 and otherwise record truthful strengthening gaps:

- Authenticated Browser Connector Alpha
- Basic Video-to-Knowledge Ingestion
- Transcript and timestamp trace
- Basic Visual Evidence Understanding
- Image OCR and keyframe OCR
- Basic Knowledge Verification Engine
- Basic Knowledge Verification Dashboard

P2, later enhancement only:

- Deep platform adapters
- Comment summarization
- High-accuracy automatic video transcription
- Complex table OCR and flowchart understanding
- Multilingual and broader international-site support
- Periodic refresh and expiration reminders

No current hard promise is made for stable full-text access or bulk collection on Xiaohongshu, Douyin, WeChat, Zhihu, comments, private APIs, login bypass, CAPTCHA bypass, or anti-detection behavior.

## Test and Regression Gate

Campaign 3.0 acceptance requires focused tests for:

- public URL fetch, extraction, dedup, content-hash refresh
- platform detection and structured unreadable states
- OpenCLI fallback and graceful degradation
- authorized-session lifecycle and no-cookie/no-shell boundaries
- manual evidence import and traces
- transcript, timestamp, keyframe, OCR, layout, and multimodal chunks
- claim extraction, support/conflict/freshness/grounding reports
- UI state/progress contracts and Core Bridge allowlist
- failure isolation

Regression tests must prove no breakage to:

- PDF import
- DOCX import
- Markdown import
- TXT import
- local HTML import
- image OCR
- existing knowledge-package build
- existing evidence pipeline

## Acceptance Gate

Campaign 3.0 may be accepted only when:

1. Public links can be ingested into traceable chunks.
2. Platform links are detected and produce truthful readability states.
3. Unreadable links do not fail silently.
4. Manual evidence enters the unified evidence pipeline.
5. Web, video, and visual chunks preserve backlinks.
6. OpenCLI candidates have confidence and evidence mappings.
7. OpenCLI unavailability degrades gracefully.
8. Authorized browser reading obeys visible-content and no-cookie boundaries.
9. OCR and multimodal failures are isolated.
10. Knowledge and answer verification report verified, unsupported, outdated, conflicting, low-confidence, and human-review states.
11. Progress events and failure isolation are covered; the P0 External Link Import entry and P0 Core Bridge allowlist registrations have focused tests.
12. Existing local document ingestion and evidence pipelines pass regression tests.
13. Governance, focused tests, relevant UI tests, and `git diff --check` pass.

After Campaign 3.0 acceptance, the Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate passed as a foundation contract before Campaign 3 Supplement 4.0. After Supplement 4.0 acceptance, the expanded Campaign 3 Final Consistency Gate passed and accepted Campaign 3 only for the ordered Stage Test transition. Campaign 4 may open only after Campaign 1-3 Stage Test Gate, Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag creation, CI/CL green verification, Closure Checklist, and Campaign 1-3 review handoff all pass.

## Non-Completion Guard

- Supplement 3.0 Entry Gate passage is not implementation or acceptance.
- P0 framework passage is not Generic Web URL Ingestion, Platform Link Preflight, OpenCLI verification, UI workflow acceptance, Core Bridge execution acceptance, or Supplement 3.0 acceptance.
- Generic Web URL Ingestion passage is not Platform Link Preflight, OpenCLI verification, UI workflow acceptance, Core Bridge execution acceptance, or Supplement 3.0 acceptance.
- Platform Link Preflight passage is not OpenCLI verification, manual evidence processing, UI workflow acceptance, Core Bridge execution acceptance, or Supplement 3.0 acceptance.
- Supplement 3.0 acceptance is not permission to run Campaign 1-3 total closure directly.
- Supplement 3.0 acceptance is not permission to skip the Pre-4.0 Workspace Partition Foundation Gate or Campaign 3 Supplement 4.0.
- Campaign 3 Supplement 4.0 is not Campaign 4.
- Campaign 4 is not 4.0.
- A URL preflight contract alone is not URL ingestion acceptance.
- An OpenCLI adapter contract is not real verification acceptance.
- An allowlist entry is not Core Bridge acceptance.
- A UI entry or dashboard mock is not UI workflow acceptance.
- Fixture-only OCR or video output is not multimodal E2E acceptance.
- Focused tests or Fast Gate are not Full Gate.
- Campaign 1-3 Stage Test Gate, Campaign 1-3 Integrated Closure Gate, Closure Pack generation, Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate, repository push, tag, CI/CL green, Campaign 4, EXE packaging, and release remain blocked.
- `final_target_not_downgraded = true`
- `not_goal_complete = true`
