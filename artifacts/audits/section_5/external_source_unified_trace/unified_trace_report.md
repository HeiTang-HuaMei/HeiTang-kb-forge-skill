# External Source Unified Trace Report

- Status: `passed`
- Decision: `real_integration / unified_trace_evidence_progress_failure_isolation_only`
- Source count: `13`
- Evidence count: `13`
- Isolated failure count: `7`
- Validation: `passed` with `0` boundary errors

## Pipeline Status

| Pipeline | Status | Decision class | Sources | Evidence | Isolated failures |
| --- | --- | --- | --- | --- | --- |
| Generic Web URL Ingestion | passed | real_integration | 1 | 1 | 0 |
| Platform Link Preflight | passed | preflight_only | 7 | 7 | 7 |
| OpenCLI External Search Verification | passed | verification_result | 3 | 3 | 0 |
| Manual Evidence Upload | passed | manual_evidence | 2 | 2 | 0 |

## Isolated Failures

- `platform_link_preflight` / `blocked`: Xiaohongshu content often requires a user-visible authorized session; no login or anti-detection bypass is allowed.
- `platform_link_preflight` / `skipped`: Douyin links are video-first and do not provide a guaranteed public transcript through generic URL ingestion.
- `platform_link_preflight` / `partial`: Zhihu content may be partially public but can require login, permission, or manual evidence for complete source capture.
- `platform_link_preflight` / `skipped`: Bilibili links are video-first and require transcript, subtitle, or keyframe evidence before knowledge ingestion can be accepted.
- `platform_link_preflight` / `partial`: WeChat public article readability varies by permission, redirects, and platform controls; generic fetch is not accepted as platform extraction.
- `platform_link_preflight` / `blocked`: Weibo posts often require login or visible user session for reliable reading; no login bypass is allowed.
- `platform_link_preflight` / `skipped`: Unknown platform link requires external verification or manual evidence before ingestion.

Boundary: this current-item industrial completion unifies already completed Generic Web URL, Platform Preflight, OpenCLI verification, and Manual Evidence outputs. It does not implement Authenticated Browser, Video/OCR/Visual Evidence, Knowledge Verification Engine, Supplement 4.0, Campaign 4, Closure, Upload, Tag, CI, Full Gate, EXE, or Release.
