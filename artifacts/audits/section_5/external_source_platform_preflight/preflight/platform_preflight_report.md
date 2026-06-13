# Platform Link Preflight Report

- Status: `passed`
- Decision: `real_integration / platform_preflight_only`
- Source count: `7`
- Boundary: this step detects platform and readability state only; it does not fetch platform content, call OpenCLI, use authenticated browser sessions, import manual evidence, accept Supplement 3.0, or open Campaign 4.

## Sources

| Platform | Readability state | Next paths |
| --- | --- | --- |
| xiaohongshu | auth_required | opencli_external_search_verification, authenticated_browser_visible_content, manual_evidence_upload |
| douyin | video_without_transcript | opencli_external_search_verification, authenticated_browser_visible_content, manual_evidence_upload, video_to_knowledge_ingestion |
| zhihu | partial_readable | opencli_external_search_verification, authenticated_browser_visible_content, manual_evidence_upload |
| bilibili | video_without_transcript | opencli_external_search_verification, manual_evidence_upload, video_to_knowledge_ingestion |
| wechat_public_article | partial_readable | opencli_external_search_verification, manual_evidence_upload, authenticated_browser_visible_content |
| weibo | login_required | opencli_external_search_verification, authenticated_browser_visible_content, manual_evidence_upload |
| other_or_unknown_platform | needs_opencli_verification | generic_web_url_ingestion, opencli_external_search_verification, manual_evidence_upload |

## Validation Errors

- None
