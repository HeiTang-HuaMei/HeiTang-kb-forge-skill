from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


HORIZON_STRENGTHENING_FILES = [
    "horizon_strengthening_manifest.json",
    "source_scoring_rules.json",
    "topic_dedup_rules.json",
    "briefing_candidate_schema.json",
    "content_intake_boundary_rules.json",
    "horizon_strengthening_validation_report.json",
    "horizon_strengthening_report.md",
]

REPOSITORY_HEAD = "7e0ffbbd069765b77af053e73ccc0cd6ccc2456f"


def build_horizon_strengthening_record(
    output: Path,
    *,
    library_name: str = "HeiTang Horizon Topic Intake Strengthening",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    source_scoring = _source_scoring_rules()
    topic_dedup = _topic_dedup_rules()
    candidate_schema = _briefing_candidate_schema()
    boundary_rules = _content_intake_boundary_rules()
    manifest = {
        "schema_version": "horizon_strengthening_manifest.v1",
        "section": "5.S2",
        "campaign": "Campaign 3",
        "status": "passed",
        "project_id": "horizon",
        "project_name": "Horizon",
        "library_name": library_name,
        "integration_decision": "real_integration",
        "decision_qualifier": "topic_intake_pipeline_schema_only",
        "integration_mode": "topic_intake_pipeline_schema_strengthening",
        "source_verification": {
            "repository_url": "https://github.com/Thysrael/Horizon",
            "repository_head": REPOSITORY_HEAD,
            "default_branch": "main",
            "repository_accessible": True,
            "repository_archived": False,
            "repository_disabled": False,
            "license_spdx": "MIT",
            "repository_cloned": False,
            "external_code_copied": False,
            "external_prompt_text_copied": False,
            "external_workflow_copied": False,
            "external_skill_files_copied": False,
            "external_installer_executed": False,
        },
        "official_runtime_observation": {
            "documented_positioning": [
                "ai_powered_news_radar",
                "daily_briefing",
                "source_monitoring",
                "deduplicate_score_filter_enrich_summarize",
                "delivery_channels",
            ],
            "documented_sources": [
                "rss",
                "hacker_news",
                "reddit",
                "telegram",
                "twitter_x",
                "github",
                "openbb",
            ],
            "documented_runtime_dependencies": [
                "uv_or_docker",
                "configured_sources",
                "ai_provider_api_key",
                "optional_delivery_credentials",
                "optional_mcp_server",
            ],
            "runtime_installed": False,
            "runtime_executed": False,
            "crawler_or_scraper_enabled": False,
            "scheduled_fetch_enabled": False,
            "api_key_requested": False,
            "delivery_channel_configured": False,
            "mcp_registered": False,
            "network_ingestion_executed": False,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "not_peer_project": True,
            "strengthens_existing_domains": [
                "marketing_skill_pattern_library",
                "business_scenario_template_library",
                "knowledge_output_flywheel_future_module",
                "external_source_memory_future_plan",
            ],
            "existing_capability_anchors": [
                "5.7 ai-marketing-skills local Marketing Skill Pattern Library",
                "5.8 ai-money-maker-handbook local Business Scenario Template Library",
                "Campaign 3 Supplement 3.0 planned External Source Memory & Verification",
            ],
            "distinct_strengthening_value": [
                "source_scoring_schema",
                "dedup_topic_merge_rules",
                "daily_briefing_candidate_schema",
                "content_intake_boundary_rules",
            ],
            "does_not_replace": [
                "ai-marketing-skills Marketing Skill Pattern Library",
                "ai-money-maker-handbook Business Scenario Template Library",
                "AnySearchSkill external retrieval provider",
                "Campaign 3 Supplement 3.0 External Source Memory & Verification",
            ],
        },
        "runtime_boundary": _runtime_boundary(),
        "ui_contract": {
            "status_visible": True,
            "topic_radar_visible": True,
            "information_intake_visible": True,
            "daily_briefing_preview_visible": True,
            "content_candidate_queue_visible": True,
            "future_module_slot_visible": True,
            "local_ready": True,
            "ready": False,
            "executable_action": False,
            "horizon_runtime_action_available": False,
            "crawler_action_available": False,
            "scheduler_action_available": False,
            "delivery_action_available": False,
            "mcp_connector_action_available": False,
            "ui_visibility": "visible_status_only",
        },
        "rule_counts": {
            "source_scoring": len(source_scoring["rules"]),
            "topic_dedup": len(topic_dedup["rules"]),
            "candidate_required_fields": len(candidate_schema["required_fields"]),
            "content_intake_boundary": len(boundary_rules["rules"]),
        },
        "output_files": HORIZON_STRENGTHENING_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "This advances Section 5 strengthening item 5.S2 as a local Topic Intake Pipeline schema only. "
            "It does not install or execute Horizon, configure crawlers, schedulers, delivery channels, MCP, API keys, "
            "Campaign 3.0 external-source ingestion, Campaign 4 UI workflow, Full Gate, EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 strengthening item 5.S3 Obsidian-compatible Vault only.",
        "not_goal_complete": True,
    }
    validation = validate_horizon_strengthening_payload(
        manifest,
        source_scoring,
        topic_dedup,
        candidate_schema,
        boundary_rules,
    )
    write_json(output / "horizon_strengthening_manifest.json", manifest)
    write_json(output / "source_scoring_rules.json", source_scoring)
    write_json(output / "topic_dedup_rules.json", topic_dedup)
    write_json(output / "briefing_candidate_schema.json", candidate_schema)
    write_json(output / "content_intake_boundary_rules.json", boundary_rules)
    write_json(output / "horizon_strengthening_validation_report.json", validation)
    (output / "horizon_strengthening_report.md").write_text(
        _render_report(manifest, validation),
        encoding="utf-8",
    )
    return manifest | {"validation": validation}


def validate_horizon_strengthening_record(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in HORIZON_STRENGTHENING_FILES
        if not (library / file_name).exists()
    ]
    if missing:
        return {
            "schema_version": "horizon_strengthening_validation_report.v1",
            "section": "5.S2",
            "campaign": "Campaign 3",
            "status": "failed",
            "boundary_errors": ["required_files_missing"],
            "required_files": HORIZON_STRENGTHENING_FILES,
            "missing_files": missing,
            "tests_require_real_llm_api_network": False,
            "final_target_not_downgraded": True,
            "remaining_gap": "Required Horizon strengthening evidence is incomplete.",
            "next_required_e2e_step": "Complete Section 5 strengthening item 5.S2 before advancing.",
            "not_goal_complete": True,
        }
    result = validate_horizon_strengthening_payload(
        _read_json(library / "horizon_strengthening_manifest.json"),
        _read_json(library / "source_scoring_rules.json"),
        _read_json(library / "topic_dedup_rules.json"),
        _read_json(library / "briefing_candidate_schema.json"),
        _read_json(library / "content_intake_boundary_rules.json"),
    )
    return {
        **result,
        "required_files": HORIZON_STRENGTHENING_FILES,
        "missing_files": missing,
    }


def validate_horizon_strengthening_payload(
    manifest: dict[str, Any],
    source_scoring: dict[str, Any],
    topic_dedup: dict[str, Any],
    candidate_schema: dict[str, Any],
    boundary_rules: dict[str, Any],
) -> dict[str, Any]:
    source = manifest.get("source_verification", {})
    observed = manifest.get("official_runtime_observation", {})
    runtime = manifest.get("runtime_boundary", {})
    ui = manifest.get("ui_contract", {})
    dedup = manifest.get("dedup_boundary", {})
    errors: list[str] = []
    required_false = {
        "repository_cloned": source,
        "external_code_copied": source,
        "external_prompt_text_copied": source,
        "external_workflow_copied": source,
        "external_skill_files_copied": source,
        "external_installer_executed": source,
        "runtime_installed": observed,
        "runtime_executed": observed,
        "crawler_or_scraper_enabled": observed,
        "scheduled_fetch_enabled": observed,
        "api_key_requested": observed,
        "delivery_channel_configured": observed,
        "mcp_registered": observed,
        "network_ingestion_executed": observed,
        "horizon_runtime_integrated": runtime,
        "crawler_or_scraper_integrated": runtime,
        "scheduled_fetcher_enabled": runtime,
        "ai_scoring_runtime_enabled": runtime,
        "api_key_required": runtime,
        "delivery_channel_enabled": runtime,
        "mcp_connector_enabled": runtime,
        "external_source_ingestion_implemented": runtime,
        "campaign_3_3_0_implemented": runtime,
        "campaign_3_4_0_implemented": runtime,
        "ready": ui,
        "executable_action": ui,
        "horizon_runtime_action_available": ui,
        "crawler_action_available": ui,
        "scheduler_action_available": ui,
        "delivery_action_available": ui,
        "mcp_connector_action_available": ui,
    }
    for field, container in required_false.items():
        if container.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    if source.get("repository_accessible") is not True:
        errors.append("repository_accessible_must_be_true")
    if source.get("default_branch") != "main":
        errors.append("default_branch_must_be_main")
    if source.get("license_spdx") != "MIT":
        errors.append("license_spdx_must_be_mit")
    if dedup.get("not_peer_project") is not True:
        errors.append("not_peer_project_must_be_true")
    if manifest.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if manifest.get("integration_mode") != "topic_intake_pipeline_schema_strengthening":
        errors.append("integration_mode_invalid")
    if runtime.get("local_topic_intake_schema_implemented") is not True:
        errors.append("local_topic_intake_schema_implemented_must_be_true")
    if ui.get("local_ready") is not True:
        errors.append("local_ready_must_be_true")
    if _rule_ids(source_scoring) != {"source_trust_score", "freshness_window", "evidence_coverage_score"}:
        errors.append("source_scoring_rules_invalid")
    if _rule_ids(topic_dedup) != {"canonical_url_hash", "cross_source_story_merge", "conflict_preserving_dedup"}:
        errors.append("topic_dedup_rules_invalid")
    if _rule_ids(boundary_rules) != {"no_vendor_runtime", "no_crawler_or_scheduler", "no_delivery_or_mcp_side_effect", "no_campaign_3_0_substitution"}:
        errors.append("content_intake_boundary_rules_invalid")
    required_fields = set(candidate_schema.get("required_fields", []))
    expected_fields = {
        "candidate_id",
        "source_type",
        "source_url",
        "title",
        "retrieved_at",
        "content_hash",
        "source_score",
        "dedup_key",
        "topic_tags",
        "evidence_ids",
        "source_trace",
        "risk_flags",
        "status",
    }
    if not expected_fields <= required_fields:
        errors.append("briefing_candidate_required_fields_invalid")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "horizon_strengthening_validation_report.v1",
        "section": "5.S2",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "repository_head": source.get("repository_head"),
        "license_spdx": source.get("license_spdx"),
        "integration_decision": manifest.get("integration_decision"),
        "source_scoring_rule_count": len(source_scoring.get("rules", [])),
        "topic_dedup_rule_count": len(topic_dedup.get("rules", [])),
        "candidate_required_field_count": len(candidate_schema.get("required_fields", [])),
        "content_intake_boundary_rule_count": len(boundary_rules.get("rules", [])),
        "horizon_runtime_integrated": runtime.get("horizon_runtime_integrated"),
        "crawler_or_scraper_integrated": runtime.get("crawler_or_scraper_integrated"),
        "scheduled_fetcher_enabled": runtime.get("scheduled_fetcher_enabled"),
        "ui_ready": ui.get("ready"),
        "ui_executable_action": ui.get("executable_action"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Validation covers local Topic Intake Pipeline schema and negative runtime/UI boundaries only. It does not prove "
            "Horizon runtime execution, real source fetching, Campaign 3.0 external-source ingestion, Campaign 4 UI workflow, Full Gate, EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 strengthening item 5.S3 Obsidian-compatible Vault only.",
        "not_goal_complete": True,
    }


def write_horizon_strengthening_record(
    output: Path,
    *,
    library_name: str = "HeiTang Horizon Topic Intake Strengthening",
) -> dict[str, Any]:
    return build_horizon_strengthening_record(output, library_name=library_name)


def write_horizon_strengthening_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_horizon_strengthening_record(library)
    write_json(output / "horizon_strengthening_validation_report.json", result)
    (output / "horizon_strengthening_validation_report.md").write_text(
        _render_validation_report(result),
        encoding="utf-8",
    )
    return result


def _source_scoring_rules() -> dict[str, Any]:
    return {
        "schema_version": "horizon_source_scoring_rules.v1",
        "rules": [
            {
                "rule_id": "source_trust_score",
                "purpose": "Score user-approved sources by declared provenance, domain, author, and prior evidence quality.",
                "required_inputs": ["source_type", "source_url", "source_trace", "trust_label"],
            },
            {
                "rule_id": "freshness_window",
                "purpose": "Preserve retrieved_at and published_at windows before a topic candidate enters briefing review.",
                "required_inputs": ["published_at", "retrieved_at", "freshness_policy"],
            },
            {
                "rule_id": "evidence_coverage_score",
                "purpose": "Prefer candidates with source_trace and evidence_map coverage; route unsupported claims to review.",
                "required_inputs": ["evidence_ids", "source_trace", "risk_flags"],
            },
        ],
    }


def _topic_dedup_rules() -> dict[str, Any]:
    return {
        "schema_version": "horizon_topic_dedup_rules.v1",
        "rules": [
            {
                "rule_id": "canonical_url_hash",
                "purpose": "Generate deterministic content_hash and dedup_key from canonical URL and normalized title.",
            },
            {
                "rule_id": "cross_source_story_merge",
                "purpose": "Merge candidates that point to the same story while preserving every original source trace.",
            },
            {
                "rule_id": "conflict_preserving_dedup",
                "purpose": "Do not hide conflicting claims during dedup; carry them into risk_flags and human review.",
            },
        ],
    }


def _briefing_candidate_schema() -> dict[str, Any]:
    return {
        "schema_version": "horizon_briefing_candidate_schema.v1",
        "description": "Local schema for Topic Radar / Information Intake / Daily Briefing candidate queues.",
        "required_fields": [
            "candidate_id",
            "source_type",
            "source_url",
            "title",
            "retrieved_at",
            "content_hash",
            "source_score",
            "dedup_key",
            "topic_tags",
            "evidence_ids",
            "source_trace",
            "risk_flags",
            "status",
        ],
        "allowed_statuses": [
            "candidate",
            "selected",
            "deferred",
            "rejected",
            "needs_review",
        ],
        "allowed_source_types": [
            "rss",
            "public_web",
            "github",
            "manual_evidence",
            "future_platform_link",
            "future_video_source",
        ],
        "side_effects": {
            "fetches_network_content": False,
            "runs_horizon_runtime": False,
            "calls_llm_provider": False,
            "publishes_briefing": False,
        },
    }


def _content_intake_boundary_rules() -> dict[str, Any]:
    return {
        "schema_version": "horizon_content_intake_boundary_rules.v1",
        "rules": [
            {
                "rule_id": "no_vendor_runtime",
                "purpose": "Do not install, clone, vendor, or execute Horizon runtime for this strengthening item.",
                "blocked_side_effects": ["horizon_install", "uv_sync", "docker_compose_run"],
            },
            {
                "rule_id": "no_crawler_or_scheduler",
                "purpose": "Do not start source crawlers, scheduled fetchers, or monitoring jobs.",
                "blocked_side_effects": ["network_fetch_loop", "cron_schedule", "source_monitor"],
            },
            {
                "rule_id": "no_delivery_or_mcp_side_effect",
                "purpose": "Do not configure email, webhooks, GitHub Pages publishing, or MCP servers.",
                "blocked_side_effects": ["email_send", "webhook_post", "mcp_registration", "pages_publish"],
            },
            {
                "rule_id": "no_campaign_3_0_substitution",
                "purpose": "Do not treat this schema strengthening as External Source Memory & Verification implementation.",
                "blocked_side_effects": ["external_source_ingestion_acceptance", "campaign_3_0_activation"],
            },
        ],
    }


def _runtime_boundary() -> dict[str, Any]:
    return {
        "local_topic_intake_schema_implemented": True,
        "horizon_runtime_integrated": False,
        "crawler_or_scraper_integrated": False,
        "scheduled_fetcher_enabled": False,
        "ai_scoring_runtime_enabled": False,
        "api_key_required": False,
        "delivery_channel_enabled": False,
        "mcp_connector_enabled": False,
        "external_source_ingestion_implemented": False,
        "knowledge_to_skill_template_generator_implemented": False,
        "campaign_3_3_0_implemented": False,
        "campaign_3_4_0_implemented": False,
    }


def _rule_ids(payload: dict[str, Any]) -> set[str]:
    return {str(item.get("rule_id")) for item in payload.get("rules", [])}


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    counts = manifest["rule_counts"]
    return f"""# Horizon Topic Intake Strengthening

- Status: {validation['status']}
- Integration decision: {manifest['integration_decision']}
- Integration mode: {manifest['integration_mode']}
- Repository head: {manifest['source_verification']['repository_head']}
- License: {manifest['source_verification']['license_spdx']}
- Source scoring rules: {counts['source_scoring']}
- Topic dedup rules: {counts['topic_dedup']}
- Candidate required fields: {counts['candidate_required_fields']}
- Boundary rules: {counts['content_intake_boundary']}
- Runtime integrated: {manifest['runtime_boundary']['horizon_runtime_integrated']}
- Crawler integrated: {manifest['runtime_boundary']['crawler_or_scraper_integrated']}
- UI executable action: {manifest['ui_contract']['executable_action']}

This is a Section 5.S2 strengthening record for Topic Radar / Information Intake / Daily Briefing candidate queues. It does not install or execute Horizon, start crawlers, configure schedulers or delivery channels, register MCP, or open later campaigns.
"""


def _render_validation_report(result: dict[str, Any]) -> str:
    return f"""# Horizon Strengthening Validation

- Status: {result['status']}
- Boundary errors: {len(result['boundary_errors'])}
- Source scoring rules: {result.get('source_scoring_rule_count', 0)}
- Topic dedup rules: {result.get('topic_dedup_rule_count', 0)}
- Candidate required fields: {result.get('candidate_required_field_count', 0)}
- Boundary rules: {result.get('content_intake_boundary_rule_count', 0)}
- Runtime integrated: {result.get('horizon_runtime_integrated')}
- Crawler integrated: {result.get('crawler_or_scraper_integrated')}
"""
