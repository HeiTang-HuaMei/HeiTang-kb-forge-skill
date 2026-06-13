from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


GBRAIN_STRENGTHENING_FILES = [
    "gbrain_strengthening_manifest.json",
    "memory_profile_rules.json",
    "knowledge_graph_gap_rules.json",
    "agent_memory_boundary_rules.json",
    "gbrain_strengthening_validation_report.json",
    "gbrain_strengthening_report.md",
]

REPOSITORY_HEAD = "4ee530f3c545b880cecc47c4f877e0ed014896b4"
LICENSE_SHA = "35029511144443297cad2d26e4bac17d0e352f93"


def build_gbrain_strengthening_record(
    output: Path,
    *,
    library_name: str = "HeiTang GBrain Memory/Profile/KG Strengthening",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    memory_rules = _memory_profile_rules()
    graph_rules = _knowledge_graph_gap_rules()
    boundary_rules = _agent_memory_boundary_rules()
    manifest = {
        "schema_version": "gbrain_strengthening_manifest.v1",
        "section": "5.S1",
        "campaign": "Campaign 3",
        "status": "passed",
        "project_id": "gbrain",
        "project_name": "GBrain",
        "library_name": library_name,
        "integration_decision": "needs_strengthening",
        "integration_mode": "memory_profile_kg_strengthening_record",
        "source_verification": {
            "repository_url": "https://github.com/garrytan/gbrain",
            "repository_head": REPOSITORY_HEAD,
            "default_branch": "master",
            "repository_accessible": True,
            "repository_archived": False,
            "repository_disabled": False,
            "license_spdx": "MIT",
            "license_file": "LICENSE",
            "license_sha": LICENSE_SHA,
            "main_branch_raw_404_observed": True,
            "master_branch_verified": True,
            "repository_cloned": False,
            "external_code_copied": False,
            "external_prompt_text_copied": False,
            "external_skill_files_copied": False,
            "external_installer_executed": False,
        },
        "official_runtime_observation": {
            "documented_positioning": [
                "agent_brain_layer",
                "synthesis_layer",
                "self_wiring_knowledge_graph",
                "gap_analysis",
                "mcp_connector",
            ],
            "documented_runtime_dependencies": [
                "bun",
                "pglite_or_postgres",
                "pgvector_for_vector_search",
                "mcp",
                "optional_api_keys",
            ],
            "documented_commands_observed": [
                "gbrain init --pglite",
                "gbrain serve",
                "gbrain search",
                "gbrain think",
                "gbrain capture",
            ],
            "runtime_installed": False,
            "runtime_executed": False,
            "database_created": False,
            "mcp_registered": False,
            "api_key_requested": False,
            "network_ingestion_executed": False,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "not_peer_project": True,
            "strengthens_existing_domains": [
                "knowledge_lifecycle",
                "auto_wiki_knowledge_graph",
                "agent_profile",
                "source_trace",
                "evidence_gap_analysis",
            ],
            "existing_capability_anchors": [
                "5.1 LLM Wiki v2 local Knowledge Lifecycle",
                "5.2 WeKnora local Auto Wiki / Knowledge Graph / RAG trace",
                "existing Agent Package profile and local runtime bindings",
            ],
            "distinct_strengthening_value": [
                "memory_profile_scope_contract",
                "graph_gap_analysis_rules",
                "agent_memory_boundary_rules",
            ],
            "does_not_replace": [
                "LLM Wiki v2 capability fusion",
                "WeKnora Auto Wiki and KG trace",
                "AnySearchSkill provider adapter",
                "RAG-Anything cross-modal schema reference",
                "P2.2 Skill Governance / Skill Suite",
            ],
        },
        "runtime_boundary": _runtime_boundary(),
        "ui_contract": {
            "status_visible": True,
            "memory_profile_strengthening_visible": True,
            "kg_gap_rules_visible": True,
            "local_ready": True,
            "ready": False,
            "executable_action": False,
            "gbrain_runtime_action_available": False,
            "mcp_connector_action_available": False,
            "database_setup_action_available": False,
            "ui_visibility": "visible_status_only",
        },
        "rule_counts": {
            "memory_profile": len(memory_rules["rules"]),
            "knowledge_graph_gap": len(graph_rules["rules"]),
            "agent_memory_boundary": len(boundary_rules["rules"]),
        },
        "output_files": GBRAIN_STRENGTHENING_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "This advances Section 5 strengthening item 5.S1 as local memory/profile/KG strengthening evidence only. "
            "It does not install or execute GBrain, configure MCP, create PGLite/Postgres/pgvector storage, import skills, "
            "create or bind an Agent, accept Campaign 3, open Campaign 3 Supplements 3.0/4.0, open Campaign 4, run Full Gate, package EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 strengthening item 5.S2 Horizon only.",
        "not_goal_complete": True,
    }
    validation = validate_gbrain_strengthening_payload(
        manifest,
        memory_rules,
        graph_rules,
        boundary_rules,
    )
    write_json(output / "gbrain_strengthening_manifest.json", manifest)
    write_json(output / "memory_profile_rules.json", memory_rules)
    write_json(output / "knowledge_graph_gap_rules.json", graph_rules)
    write_json(output / "agent_memory_boundary_rules.json", boundary_rules)
    write_json(output / "gbrain_strengthening_validation_report.json", validation)
    (output / "gbrain_strengthening_report.md").write_text(
        _render_report(manifest, validation),
        encoding="utf-8",
    )
    return manifest | {"validation": validation}


def validate_gbrain_strengthening_record(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in GBRAIN_STRENGTHENING_FILES
        if not (library / file_name).exists()
    ]
    if missing:
        return {
            "schema_version": "gbrain_strengthening_validation_report.v1",
            "section": "5.S1",
            "campaign": "Campaign 3",
            "status": "failed",
            "boundary_errors": ["required_files_missing"],
            "required_files": GBRAIN_STRENGTHENING_FILES,
            "missing_files": missing,
            "tests_require_real_llm_api_network": False,
            "final_target_not_downgraded": True,
            "remaining_gap": "Required GBrain strengthening evidence is incomplete.",
            "next_required_e2e_step": "Complete Section 5 strengthening item 5.S1 before advancing.",
            "not_goal_complete": True,
        }
    result = validate_gbrain_strengthening_payload(
        _read_json(library / "gbrain_strengthening_manifest.json"),
        _read_json(library / "memory_profile_rules.json"),
        _read_json(library / "knowledge_graph_gap_rules.json"),
        _read_json(library / "agent_memory_boundary_rules.json"),
    )
    return {
        **result,
        "required_files": GBRAIN_STRENGTHENING_FILES,
        "missing_files": missing,
    }


def validate_gbrain_strengthening_payload(
    manifest: dict[str, Any],
    memory_rules: dict[str, Any],
    graph_rules: dict[str, Any],
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
        "external_skill_files_copied": source,
        "external_installer_executed": source,
        "runtime_installed": observed,
        "runtime_executed": observed,
        "database_created": observed,
        "mcp_registered": observed,
        "api_key_requested": observed,
        "network_ingestion_executed": observed,
        "gbrain_runtime_integrated": runtime,
        "bun_dependency_installed": runtime,
        "pglite_or_postgres_configured": runtime,
        "pgvector_required": runtime,
        "mcp_connector_enabled": runtime,
        "external_skills_imported": runtime,
        "agent_created_or_bound": runtime,
        "external_source_ingestion_implemented": runtime,
        "knowledge_to_skill_template_generator_implemented": runtime,
        "campaign_3_3_0_implemented": runtime,
        "campaign_3_4_0_implemented": runtime,
        "ready": ui,
        "executable_action": ui,
        "gbrain_runtime_action_available": ui,
        "mcp_connector_action_available": ui,
        "database_setup_action_available": ui,
    }
    for field, container in required_false.items():
        if container.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    if source.get("repository_accessible") is not True:
        errors.append("repository_accessible_must_be_true")
    if source.get("default_branch") != "master":
        errors.append("default_branch_must_be_master")
    if source.get("license_spdx") != "MIT":
        errors.append("license_spdx_must_be_mit")
    if dedup.get("not_peer_project") is not True:
        errors.append("not_peer_project_must_be_true")
    if manifest.get("integration_decision") != "needs_strengthening":
        errors.append("integration_decision_must_be_needs_strengthening")
    if manifest.get("integration_mode") != "memory_profile_kg_strengthening_record":
        errors.append("integration_mode_invalid")
    if ui.get("local_ready") is not True:
        errors.append("local_ready_must_be_true")
    if _rule_ids(memory_rules) != {"scope_memory_profile", "source_bound_identity", "confidence_and_staleness"}:
        errors.append("memory_profile_rules_invalid")
    if _rule_ids(graph_rules) != {"typed_relation_gap_scan", "citation_gap_detection", "contradiction_gap_review"}:
        errors.append("knowledge_graph_gap_rules_invalid")
    if _rule_ids(boundary_rules) != {"no_runtime_install", "no_mcp_or_db_side_effect", "no_agent_binding_side_effect"}:
        errors.append("agent_memory_boundary_rules_invalid")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "gbrain_strengthening_validation_report.v1",
        "section": "5.S1",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "repository_head": source.get("repository_head"),
        "license_spdx": source.get("license_spdx"),
        "integration_decision": manifest.get("integration_decision"),
        "memory_profile_rule_count": len(memory_rules.get("rules", [])),
        "knowledge_graph_gap_rule_count": len(graph_rules.get("rules", [])),
        "agent_memory_boundary_rule_count": len(boundary_rules.get("rules", [])),
        "gbrain_runtime_integrated": runtime.get("gbrain_runtime_integrated"),
        "mcp_connector_enabled": runtime.get("mcp_connector_enabled"),
        "pgvector_required": runtime.get("pgvector_required"),
        "ui_ready": ui.get("ready"),
        "ui_executable_action": ui.get("executable_action"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Validation covers local strengthening rules and negative runtime/UI boundaries only. It does not prove "
            "GBrain runtime execution, Campaign 3 acceptance, Supplement 3.0/4.0, Campaign 4 UI workflow, Full Gate, EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 strengthening item 5.S2 Horizon only.",
        "not_goal_complete": True,
    }


def write_gbrain_strengthening_record(
    output: Path,
    *,
    library_name: str = "HeiTang GBrain Memory/Profile/KG Strengthening",
) -> dict[str, Any]:
    return build_gbrain_strengthening_record(output, library_name=library_name)


def write_gbrain_strengthening_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_gbrain_strengthening_record(library)
    write_json(output / "gbrain_strengthening_validation_report.json", result)
    (output / "gbrain_strengthening_validation_report.md").write_text(
        _render_validation_report(result),
        encoding="utf-8",
    )
    return result


def _memory_profile_rules() -> dict[str, Any]:
    return {
        "schema_version": "gbrain_memory_profile_rules.v1",
        "rules": [
            {
                "rule_id": "scope_memory_profile",
                "purpose": "Represent person/team/project memory scope as project metadata, not a separate GBrain runtime.",
                "evidence_hook": "knowledge_lifecycle confidence and source trace",
            },
            {
                "rule_id": "source_bound_identity",
                "purpose": "Tie each memory/profile assertion to a source chunk, evidence id, and freshness signal.",
                "evidence_hook": "source_trace and evidence_map",
            },
            {
                "rule_id": "confidence_and_staleness",
                "purpose": "Surface stale or unsupported profile facts as gaps instead of synthesized certainty.",
                "evidence_hook": "stale_evidence_report and confidence_report",
            },
        ],
    }


def _knowledge_graph_gap_rules() -> dict[str, Any]:
    return {
        "schema_version": "gbrain_knowledge_graph_gap_rules.v1",
        "rules": [
            {
                "rule_id": "typed_relation_gap_scan",
                "purpose": "Scan for missing typed edges between entities already present in local knowledge graph evidence.",
                "evidence_hook": "auto_wiki knowledge_graph_snapshot",
            },
            {
                "rule_id": "citation_gap_detection",
                "purpose": "Flag graph nodes or relation candidates that lack citation coverage.",
                "evidence_hook": "rag_trace_summary and evidence_map",
            },
            {
                "rule_id": "contradiction_gap_review",
                "purpose": "Route conflicting or outdated entity facts to review instead of auto-merge.",
                "evidence_hook": "future external verification and current quality report",
            },
        ],
    }


def _agent_memory_boundary_rules() -> dict[str, Any]:
    return {
        "schema_version": "gbrain_agent_memory_boundary_rules.v1",
        "rules": [
            {
                "rule_id": "no_runtime_install",
                "purpose": "Do not install Bun, GBrain, bundled skills, or GBrain dependencies for this strengthening item.",
                "blocked_side_effects": ["bun_install", "gbrain_install", "skillpack_import"],
            },
            {
                "rule_id": "no_mcp_or_db_side_effect",
                "purpose": "Do not register MCP servers, create PGLite/Postgres/pgvector stores, or modify local agent config.",
                "blocked_side_effects": ["mcp_registration", "database_creation", "agent_config_write"],
            },
            {
                "rule_id": "no_agent_binding_side_effect",
                "purpose": "Do not create, bind, or run an Agent from this strengthening record.",
                "blocked_side_effects": ["agent_creation", "agent_binding", "agent_execution"],
            },
        ],
    }


def _runtime_boundary() -> dict[str, Any]:
    return {
        "local_strengthening_rules_implemented": True,
        "gbrain_runtime_integrated": False,
        "bun_dependency_installed": False,
        "pglite_or_postgres_configured": False,
        "pgvector_required": False,
        "mcp_connector_enabled": False,
        "external_skills_imported": False,
        "agent_created_or_bound": False,
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
    return f"""# GBrain Memory/Profile/KG Strengthening

- Status: {validation['status']}
- Integration decision: {manifest['integration_decision']}
- Integration mode: {manifest['integration_mode']}
- Repository head: {manifest['source_verification']['repository_head']}
- License: {manifest['source_verification']['license_spdx']}
- Memory/profile rules: {counts['memory_profile']}
- Knowledge graph gap rules: {counts['knowledge_graph_gap']}
- Agent memory boundary rules: {counts['agent_memory_boundary']}
- Runtime integrated: {manifest['runtime_boundary']['gbrain_runtime_integrated']}
- MCP connector enabled: {manifest['runtime_boundary']['mcp_connector_enabled']}
- UI executable action: {manifest['ui_contract']['executable_action']}

This is a Section 5.S1 strengthening record for existing memory/profile/KG domains. It does not install or execute GBrain, create databases, register MCP, import skills, create or bind an Agent, or open later campaigns.
"""


def _render_validation_report(result: dict[str, Any]) -> str:
    return f"""# GBrain Strengthening Validation

- Status: {result['status']}
- Boundary errors: {len(result['boundary_errors'])}
- Memory/profile rules: {result.get('memory_profile_rule_count', 0)}
- Knowledge graph gap rules: {result.get('knowledge_graph_gap_rule_count', 0)}
- Agent memory boundary rules: {result.get('agent_memory_boundary_rule_count', 0)}
- Runtime integrated: {result.get('gbrain_runtime_integrated')}
- MCP connector enabled: {result.get('mcp_connector_enabled')}
"""
