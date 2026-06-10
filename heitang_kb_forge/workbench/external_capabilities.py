from __future__ import annotations

import json
from collections import defaultdict
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.workbench.productization import P1_PAGE_SPECS, make_p1_workbench_bundle


S_A_CONTRACT_INCLUSION_VERSION = "s_a_contract_inclusion.1"
SOURCE_REGISTRY_RELATIVE_PATH = Path("docs/roadmap/external_projects/external_project_registry.json")

S_A_CONTRACT_OUTPUT_FILES = [
    "external_capability_registry.json",
    "external_capability_registry.md",
    "s_a_contract_inclusion_matrix.json",
    "s_a_contract_inclusion_matrix.md",
    "planned_adapter_registry.json",
    "future_adapter_registry.json",
    "provider_required_registry.json",
    "benchmark_capability_mapping.json",
    "internal_capability_anchor_registry.json",
    "workbench_capability_matrix.json",
    "workbench_error_taxonomy.json",
    "workbench_template_registry.json",
    "workbench_p1_gate_report.json",
    "planned_adapter_status_report.json",
    "planned_adapter_status_report.md",
    "provider_boundary_report.json",
    "provider_boundary_report.md",
]

BLOCKED_REASON_TAXONOMY = [
    ("external_project_registry_only", "Registry and roadmap entry only; no runtime integration is claimed."),
    ("benchmark_only_not_runtime", "Benchmark pattern only; it must not be treated as bundled runtime."),
    ("planned_adapter_not_implemented", "Adapter is planned but not implemented or ready."),
    ("future_adapter_after_v4", "Adapter or capability is explicitly post-v4."),
    ("provider_required", "Requires a user-configured provider boundary before runtime use."),
    ("secret_required", "Requires explicit user-provided secret material; no fixture may include it."),
    ("network_required", "Requires network access and cannot be counted as local-ready."),
    ("external_runtime_required", "Requires an external runtime that is not bundled."),
    ("license_review_required", "Requires license review before any implementation work."),
    ("security_review_required", "Requires security review before any implementation work."),
    ("needs_verification", "Project identity, fit, or runtime status still needs verification."),
    ("not_p1_blocker", "Not part of the P1 local Workbench completion gate."),
    ("post_v4_target", "Work is reserved for post-v4 planning."),
    ("ui_visibility_only", "UI may display the boundary only; it must not expose execution."),
    ("template_reference_only", "Template inspiration only; not runtime functionality."),
]

CONTRACT_STATUS_BY_PROJECT = {
    "llm_wiki_v2": ["future_adapter", "capability_anchor"],
    "weknora": ["future_adapter", "capability_anchor"],
    "n8n": ["future_adapter", "provider_required", "workflow_export"],
    "anysearchskill": ["provider_required", "planned_adapter"],
    "andrej_karpathy_skills": ["benchmark_only", "capability_anchor"],
    "last30days_skill": ["provider_required", "future_adapter"],
    "skill_prompt_generator": ["benchmark_only", "future_adapter"],
    "mmskills": ["future_adapter"],
    "jellyfish": ["template_reference", "future_adapter"],
    "story_flicks": ["template_reference", "future_adapter"],
    "seedance2_skill": ["provider_required", "template_reference", "future_adapter"],
    "ai_marketing_skills": ["template_reference"],
    "rtk": ["benchmark_only"],
    "opendataloader": ["planned_adapter"],
    "paddleocr": ["planned_adapter"],
    "mineru": ["planned_adapter"],
    "docling": ["planned_adapter"],
    "marker": ["planned_adapter"],
    "surya": ["planned_adapter"],
    "unstructured": ["planned_adapter"],
    "llamaindex": ["benchmark_only"],
    "ragas": ["benchmark_only", "future_adapter"],
    "deepeval": ["benchmark_only", "future_adapter"],
}

INTERNAL_ANCHOR_STATUS = {
    "book_to_skill": ["internal_capability", "implemented"],
    "package_to_skill": ["internal_capability", "implemented"],
    "software_to_manual_to_skill": ["internal_capability", "future_adapter"],
    "aigc_book_content_pipeline": ["internal_capability", "template_reference"],
    "retrieval_and_verification": ["internal_capability", "implemented"],
    "memory_lifecycle": ["internal_capability", "implemented_baseline", "future_adapter"],
    "auto_wiki_knowledge_graph": ["internal_capability", "future_adapter"],
    "workflow_automation_export": ["internal_capability", "future_adapter"],
}

PROJECT_PAGE_MAPPING = {
    "llm_wiki_v2": ["memory_center", "governance"],
    "weknora": ["retrieval_verification", "reports_audit"],
    "n8n": ["task_job_center", "template_library"],
    "anysearchskill": ["retrieval_verification", "vector_hub_provider_storage"],
    "andrej_karpathy_skills": ["skill_factory", "reports_audit"],
    "last30days_skill": ["retrieval_verification", "template_library"],
    "skill_prompt_generator": ["skill_factory", "template_library"],
    "mmskills": ["template_library", "artifact_management"],
    "jellyfish": ["template_library", "artifact_management", "document_generation"],
    "story_flicks": ["template_library", "artifact_management", "document_generation"],
    "seedance2_skill": ["template_library", "artifact_management", "document_generation"],
    "ai_marketing_skills": ["template_library"],
    "rtk": ["memory_center", "reports_audit"],
    "opendataloader": ["import_parsing", "vector_hub_provider_storage"],
    "paddleocr": ["import_parsing", "vector_hub_provider_storage"],
    "mineru": ["import_parsing", "vector_hub_provider_storage"],
    "docling": ["import_parsing", "vector_hub_provider_storage"],
    "marker": ["import_parsing", "vector_hub_provider_storage"],
    "surya": ["import_parsing", "vector_hub_provider_storage"],
    "unstructured": ["import_parsing", "vector_hub_provider_storage"],
    "llamaindex": ["retrieval_verification", "reports_audit"],
    "ragas": ["retrieval_verification", "reports_audit"],
    "deepeval": ["retrieval_verification", "reports_audit"],
}

PROJECT_TEMPLATE_MAPPING = {
    "andrej_karpathy_skills": ["template_manual_operation_skill"],
    "skill_prompt_generator": ["template_manual_operation_skill"],
    "jellyfish": ["template_book_publisher_kb"],
    "story_flicks": ["template_book_publisher_kb"],
    "seedance2_skill": ["template_book_publisher_kb"],
    "ai_marketing_skills": ["template_shopping_ops_agent"],
    "last30days_skill": ["template_product_manager_kb"],
}

PROJECT_ERROR_MAPPING = {
    "provider_required": ["provider_auth_failed"],
    "planned_adapter": ["contract_drift"],
    "future_adapter": ["contract_drift"],
    "needs_verification": ["contract_drift"],
    "workflow_export": ["tool_call_failed"],
}


def load_external_project_registry(repo_root: Path | None = None) -> dict[str, Any]:
    root = repo_root or Path.cwd()
    registry_path = root / SOURCE_REGISTRY_RELATIVE_PATH
    return json.loads(registry_path.read_text(encoding="utf-8"))


def make_external_capability_bundle(repo_root: Path | None = None) -> dict[str, Any]:
    registry = load_external_project_registry(repo_root)
    page_titles = {page_id: title for page_id, title, _ in P1_PAGE_SPECS}
    page_actions = _page_actions()
    projects = [_project_entry(project, page_titles, page_actions) for project in registry["projects"] if project["rating"] in {"S", "A"}]
    anchors = [_anchor_entry(anchor) for anchor in registry["internal_capability_anchors"] if anchor["rating"] in {"S", "A"}]

    registry_payload = _registry_payload(registry, projects, anchors)
    matrix_payload = _matrix_payload(registry_payload, projects, page_titles)
    planned_payload = _adapter_registry("planned_adapter_registry", projects, "planned_adapter")
    future_payload = _adapter_registry("future_adapter_registry", projects, "future_adapter")
    provider_payload = _provider_registry(projects)
    benchmark_payload = _benchmark_mapping(projects)
    anchor_payload = _anchor_registry(anchors)
    workbench_matrix = _workbench_capability_matrix(projects, page_titles)
    error_taxonomy = _workbench_error_taxonomy(projects)
    template_registry = _workbench_template_registry(projects)
    gate_report = _workbench_p1_gate_report(registry_payload)
    planned_report = _planned_adapter_status_report(projects)
    provider_report = _provider_boundary_report(projects)

    return {
        "external_capability_registry.json": registry_payload,
        "external_capability_registry.md": _render_external_capability_registry_md(registry_payload),
        "s_a_contract_inclusion_matrix.json": matrix_payload,
        "s_a_contract_inclusion_matrix.md": _render_matrix_md(matrix_payload),
        "planned_adapter_registry.json": planned_payload,
        "future_adapter_registry.json": future_payload,
        "provider_required_registry.json": provider_payload,
        "benchmark_capability_mapping.json": benchmark_payload,
        "internal_capability_anchor_registry.json": anchor_payload,
        "workbench_capability_matrix.json": workbench_matrix,
        "workbench_error_taxonomy.json": error_taxonomy,
        "workbench_template_registry.json": template_registry,
        "workbench_p1_gate_report.json": gate_report,
        "planned_adapter_status_report.json": planned_report,
        "planned_adapter_status_report.md": _render_planned_adapter_md(planned_report),
        "provider_boundary_report.json": provider_report,
        "provider_boundary_report.md": _render_provider_boundary_md(provider_report),
    }


def write_external_capability_bundle(output: Path, repo_root: Path | None = None) -> dict[str, Any]:
    bundle = make_external_capability_bundle(repo_root)
    for filename, payload in bundle.items():
        target = output / filename
        if filename.endswith(".json"):
            write_json(target, payload)
        else:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(str(payload), encoding="utf-8", newline="\n")
    registry = bundle["external_capability_registry.json"]
    return {
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "output": str(output),
        "output_files": S_A_CONTRACT_OUTPUT_FILES,
        "s_project_count": registry["rating_counts"]["S"],
        "a_project_count": registry["rating_counts"]["A"],
        "external_project_count": registry["external_project_count"],
        "internal_capability_anchor_count": registry["internal_capability_anchor_count"],
        "external_features_implemented": False,
        "planned_adapters_marked_ready": False,
    }


def inspect_external_capability(project_id: str, repo_root: Path | None = None) -> dict[str, Any]:
    registry = make_external_capability_bundle(repo_root)["external_capability_registry.json"]
    for project in registry["projects"]:
        if project["project_id"] == project_id:
            return project
    raise KeyError(f"Unknown external capability project_id: {project_id}")


def _registry_payload(registry: dict[str, Any], projects: list[dict[str, Any]], anchors: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "registry_id": "s_a_contract_inclusion",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "scope": "S/A external project contract inclusion only. No external project functionality is implemented.",
        "source_registry": SOURCE_REGISTRY_RELATIVE_PATH.as_posix(),
        "source_registry_id": registry["registry_id"],
        "core_repo": registry["core_repo"],
        "core_branch": registry["core_branch"],
        "rating_counts": {
            "S": sum(1 for project in projects if project["rating"] == "S"),
            "A": sum(1 for project in projects if project["rating"] == "A"),
        },
        "external_project_count": len(projects),
        "internal_capability_anchor_count": len(anchors),
        "blocked_reason_taxonomy": _blocked_reason_taxonomy_entries(),
        "projects": projects,
        "internal_capability_anchors": anchors,
        "release_boundary": {
            "p1_gate_changed": False,
            "v4_0_started": False,
            "tag_created": False,
            "release_written": False,
            "external_features_implemented": False,
            "planned_adapters_marked_ready": False,
            "provider_network_api_ready": False,
        },
    }


def _project_entry(project: dict[str, Any], page_titles: dict[str, str], page_actions: dict[str, list[str]]) -> dict[str, Any]:
    statuses = CONTRACT_STATUS_BY_PROJECT[project["project_id"]]
    page_ids = PROJECT_PAGE_MAPPING[project["project_id"]]
    blocked_reasons = _blocked_reasons(project, statuses)
    related_error_codes = _related_error_codes(project, statuses)
    related_actions = sorted({action_id for page_id in page_ids for action_id in page_actions.get(page_id, [])})
    return {
        "project_id": project["project_id"],
        "project_name": project["project_name"],
        "rating": project["rating"],
        "github_url": project["github_url"],
        "contract_status": statuses,
        "implemented": False,
        "ready": False,
        "local_ready": False,
        "executable_action": False,
        "mapped_capabilities": project["mapped_capabilities"],
        "related_workbench_pages": [{"page_id": page_id, "title": page_titles[page_id]} for page_id in page_ids],
        "related_core_actions": related_actions,
        "related_templates": PROJECT_TEMPLATE_MAPPING.get(project["project_id"], []),
        "related_error_codes": related_error_codes,
        "blocked_reason": blocked_reasons[0],
        "blocked_reasons": blocked_reasons,
        "requires_api_key": project["requires_api_key"],
        "requires_network": project["requires_network"],
        "requires_external_runtime": project["requires_external_runtime"],
        "can_execute_locally_before_v4": False,
        "can_execute_after_provider_config": False,
        "p1_gate_impact": "none_not_p1_blocker",
        "post_v4_target": project["post_v4_target"],
        "ui_visibility": "visible_boundary_only",
        "implementation_boundary": _implementation_boundary(project, statuses),
        "source_registry_status": project["current_repo_status"],
        "source_registry_implementation_mode": project["implementation_mode"],
        "license_or_security_review_required": project["license_or_security_review_required"],
    }


def _anchor_entry(anchor: dict[str, Any]) -> dict[str, Any]:
    statuses = INTERNAL_ANCHOR_STATUS[anchor["anchor_id"]]
    implemented = "implemented" in statuses or "implemented_baseline" in statuses
    return {
        "anchor_id": anchor["anchor_id"],
        "anchor_name": anchor["anchor_name"],
        "rating": anchor["rating"],
        "contract_status": statuses,
        "current_status": anchor["current_status"],
        "implemented": implemented,
        "ready": implemented,
        "local_ready": implemented,
        "pre_v4_scope": anchor["pre_v4_scope"],
        "post_v4_target": anchor["post_v4_target"],
        "related_external_benchmarks": anchor["related_external_benchmarks"],
        "implementation_boundary": "Internal Core capability anchor. External benchmark mapping does not implement external project functionality.",
    }


def _blocked_reasons(project: dict[str, Any], statuses: list[str]) -> list[str]:
    reasons = ["external_project_registry_only"]
    if "benchmark_only" in statuses:
        reasons.append("benchmark_only_not_runtime")
    if "planned_adapter" in statuses:
        reasons.append("planned_adapter_not_implemented")
    if "future_adapter" in statuses:
        reasons.append("future_adapter_after_v4")
    if "provider_required" in statuses:
        reasons.append("provider_required")
    if project["requires_api_key"]:
        reasons.append("secret_required")
    if project["requires_network"]:
        reasons.append("network_required")
    if project["requires_external_runtime"]:
        reasons.append("external_runtime_required")
    if project["license_or_security_review_required"]:
        reasons.extend(["license_review_required", "security_review_required"])
    if "needs_verification" in statuses or project["current_repo_status"] == "needs_verification":
        reasons.append("needs_verification")
    reasons.extend(["not_p1_blocker", "post_v4_target", "ui_visibility_only"])
    if "template_reference" in statuses:
        reasons.append("template_reference_only")
    return _unique(reasons)


def _related_error_codes(project: dict[str, Any], statuses: list[str]) -> list[str]:
    codes = ["contract_drift"]
    for status in statuses:
        codes.extend(PROJECT_ERROR_MAPPING.get(status, []))
    if project["requires_network"]:
        codes.append("network_unavailable")
    if project["requires_api_key"]:
        codes.append("secret_risk")
    if project["requires_external_runtime"]:
        codes.append("tool_call_failed")
    return _unique(codes)


def _implementation_boundary(project: dict[str, Any], statuses: list[str]) -> str:
    status_text = ", ".join(statuses)
    return (
        f"{project['project_name']} is included as {status_text} for post-v4 planning and UI visibility only. "
        "This pass does not copy external code, add dependencies, call APIs, bundle runtimes, or expose a Run action."
    )


def _matrix_payload(registry_payload: dict[str, Any], projects: list[dict[str, Any]], page_titles: dict[str, str]) -> dict[str, Any]:
    return {
        "matrix_id": "s_a_contract_inclusion_matrix",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "source_registry": registry_payload["source_registry"],
        "external_project_count": len(projects),
        "rating_counts": registry_payload["rating_counts"],
        "entries": [
            {
                "project_id": project["project_id"],
                "project_name": project["project_name"],
                "rating": project["rating"],
                "contract_status": project["contract_status"],
                "mapped_capabilities": project["mapped_capabilities"],
                "workbench_page_ids": [page["page_id"] for page in project["related_workbench_pages"]],
                "workbench_pages": [page_titles[page["page_id"]] for page in project["related_workbench_pages"]],
                "blocked_reason": project["blocked_reason"],
                "blocked_reasons": project["blocked_reasons"],
                "can_execute_locally_before_v4": False,
                "p1_gate_impact": project["p1_gate_impact"],
                "post_v4_target": project["post_v4_target"],
                "ui_visibility": project["ui_visibility"],
            }
            for project in projects
        ],
        "gate_boundary": {
            "p1_gate_changed": False,
            "v4_0_started": False,
            "external_features_implemented": False,
            "planned_adapters_marked_ready": False,
        },
    }


def _adapter_registry(registry_id: str, projects: list[dict[str, Any]], status: str) -> dict[str, Any]:
    rows = [project for project in projects if status in project["contract_status"]]
    return {
        "registry_id": registry_id,
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "status_filter": status,
        "entry_count": len(rows),
        "ready_count": 0,
        "can_execute_locally_before_v4_count": 0,
        "entries": [_compact_project(project) for project in rows],
    }


def _provider_registry(projects: list[dict[str, Any]]) -> dict[str, Any]:
    rows = [
        project
        for project in projects
        if "provider_required" in project["contract_status"]
        or project["requires_api_key"]
        or project["requires_network"]
        or project["requires_external_runtime"]
    ]
    return {
        "registry_id": "provider_required_registry",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "entry_count": len(rows),
        "ready_count": 0,
        "provider_network_api_ready": False,
        "entries": [_compact_project(project) for project in rows],
    }


def _benchmark_mapping(projects: list[dict[str, Any]]) -> dict[str, Any]:
    rows = [
        project
        for project in projects
        if {"benchmark_only", "capability_anchor", "template_reference"} & set(project["contract_status"])
    ]
    return {
        "mapping_id": "benchmark_capability_mapping",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "entry_count": len(rows),
        "runtime_integration_count": 0,
        "entries": [
            {
                "project_id": project["project_id"],
                "project_name": project["project_name"],
                "contract_status": project["contract_status"],
                "mapped_capabilities": project["mapped_capabilities"],
                "implementation_boundary": project["implementation_boundary"],
            }
            for project in rows
        ],
    }


def _anchor_registry(anchors: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "registry_id": "internal_capability_anchor_registry",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "entry_count": len(anchors),
        "entries": anchors,
    }


def _workbench_capability_matrix(projects: list[dict[str, Any]], page_titles: dict[str, str]) -> dict[str, Any]:
    page_rows: dict[str, list[dict[str, Any]]] = defaultdict(list)
    for project in projects:
        for page in project["related_workbench_pages"]:
            page_rows[page["page_id"]].append(
                {
                    "project_id": project["project_id"],
                    "project_name": project["project_name"],
                    "rating": project["rating"],
                    "contract_status": project["contract_status"],
                    "blocked_reason": project["blocked_reason"],
                    "ui_visibility": project["ui_visibility"],
                    "can_execute_locally_before_v4": False,
                }
            )
    return {
        "matrix_id": "workbench_external_capability_matrix",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "scope": "Extends Workbench visibility only; no new major page or executable action is added.",
        "page_count": len(page_rows),
        "pages": [
            {
                "page_id": page_id,
                "title": page_titles[page_id],
                "external_capability_count": len(page_rows[page_id]),
                "external_capabilities": sorted(page_rows[page_id], key=lambda row: row["project_id"]),
            }
            for page_id in sorted(page_rows)
        ],
    }


def _workbench_error_taxonomy(projects: list[dict[str, Any]]) -> dict[str, Any]:
    reason_projects: dict[str, list[str]] = defaultdict(list)
    for project in projects:
        for reason in project["blocked_reasons"]:
            reason_projects[reason].append(project["project_id"])
    return {
        "taxonomy_id": "workbench_external_blocked_reason_taxonomy",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "blocked_reason_count": len(BLOCKED_REASON_TAXONOMY),
        "blocked_reasons": [
            {
                "blocked_reason": reason,
                "definition": definition,
                "local_ready_allowed": False,
                "p1_gate_impact": "none",
                "project_ids": sorted(reason_projects.get(reason, [])),
            }
            for reason, definition in BLOCKED_REASON_TAXONOMY
        ],
    }


def _workbench_template_registry(projects: list[dict[str, Any]]) -> dict[str, Any]:
    rows = [project for project in projects if project["related_templates"] or "template_reference" in project["contract_status"]]
    return {
        "registry_id": "workbench_external_template_registry",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "scope": "Template and scenario reference only; no runtime or copied external content.",
        "entry_count": len(rows),
        "entries": [
            {
                "project_id": project["project_id"],
                "project_name": project["project_name"],
                "contract_status": project["contract_status"],
                "related_templates": project["related_templates"],
                "blocked_reasons": project["blocked_reasons"],
                "can_execute_locally_before_v4": False,
            }
            for project in rows
        ],
    }


def _workbench_p1_gate_report(registry_payload: dict[str, Any]) -> dict[str, Any]:
    return {
        "gate_id": "p1_workbench_gate_external_capability_boundary",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "p1_gate_changed": False,
        "p1_gate_impact": "none",
        "p1_full_operation_gate_status": "unchanged_by_s_a_contract_inclusion",
        "not_v4_0_workbench_rc": True,
        "external_capability_boundary": {
            "external_project_count": registry_payload["external_project_count"],
            "internal_capability_anchor_count": registry_payload["internal_capability_anchor_count"],
            "all_external_projects_can_execute_locally_before_v4": False,
            "planned_adapters_marked_ready": False,
            "provider_network_api_ready": False,
            "ui_visibility_only": True,
        },
    }


def _planned_adapter_status_report(projects: list[dict[str, Any]]) -> dict[str, Any]:
    planned = [project for project in projects if "planned_adapter" in project["contract_status"]]
    future = [project for project in projects if "future_adapter" in project["contract_status"]]
    return {
        "report_id": "planned_adapter_status_report",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "planned_adapter_count": len(planned),
        "future_adapter_count": len(future),
        "ready_count": 0,
        "implemented_count": 0,
        "can_execute_locally_before_v4_count": 0,
        "entries": [_compact_project(project) for project in sorted(planned + future, key=lambda row: row["project_id"])],
    }


def _provider_boundary_report(projects: list[dict[str, Any]]) -> dict[str, Any]:
    provider_rows = _provider_registry(projects)["entries"]
    return {
        "report_id": "provider_boundary_report",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "entry_count": len(provider_rows),
        "provider_network_api_ready": False,
        "n8n_bundled_runtime": False,
        "anysearchskill_api_callable": False,
        "weknora_embedded": False,
        "llm_wiki_memory_engine_implemented": False,
        "entries": provider_rows,
    }


def _compact_project(project: dict[str, Any]) -> dict[str, Any]:
    return {
        "project_id": project["project_id"],
        "project_name": project["project_name"],
        "rating": project["rating"],
        "github_url": project["github_url"],
        "contract_status": project["contract_status"],
        "blocked_reason": project["blocked_reason"],
        "blocked_reasons": project["blocked_reasons"],
        "requires_api_key": project["requires_api_key"],
        "requires_network": project["requires_network"],
        "requires_external_runtime": project["requires_external_runtime"],
        "can_execute_locally_before_v4": False,
        "post_v4_target": project["post_v4_target"],
        "ui_visibility": project["ui_visibility"],
    }


def _blocked_reason_taxonomy_entries() -> list[dict[str, Any]]:
    return [
        {
            "blocked_reason": reason,
            "definition": definition,
            "local_ready_allowed": False,
            "p1_gate_impact": "none",
        }
        for reason, definition in BLOCKED_REASON_TAXONOMY
    ]


def _page_actions() -> dict[str, list[str]]:
    bundle = make_p1_workbench_bundle()
    rows: dict[str, list[str]] = defaultdict(list)
    for action in bundle.action_contracts:
        rows[action.page_id].append(action.action_id)
    return {page_id: sorted(action_ids) for page_id, action_ids in rows.items()}


def _render_external_capability_registry_md(payload: dict[str, Any]) -> str:
    lines = [
        "# S/A External Capability Registry",
        "",
        "This is contract inclusion only. It does not implement external project functionality, add dependencies, call APIs, or bundle external runtimes.",
        "",
        "## Summary",
        "",
        f"- S projects: {payload['rating_counts']['S']}",
        f"- A projects: {payload['rating_counts']['A']}",
        f"- Internal capability anchors: {payload['internal_capability_anchor_count']}",
        "- External features implemented: false",
        "- Planned adapters marked ready: false",
        "- Provider/network/API ready: false",
        "- v4.0 started: false",
        "",
        "## Projects",
        "",
        "| Project | Rating | Contract status | Blocked reason | Post-v4 target |",
        "| --- | --- | --- | --- | --- |",
    ]
    lines.extend(
        f"| {project['project_name']} | {project['rating']} | {', '.join(project['contract_status'])} | {project['blocked_reason']} | {project['post_v4_target']} |"
        for project in payload["projects"]
    )
    return "\n".join(lines) + "\n"


def _render_matrix_md(payload: dict[str, Any]) -> str:
    lines = [
        "# S/A Contract Inclusion Matrix",
        "",
        "Workbench visibility only. Entries are not ready, not installed, and not executable before v4.",
        "",
        "| Project | Pages | Status | Local executable before v4 |",
        "| --- | --- | --- | --- |",
    ]
    lines.extend(
        f"| {entry['project_name']} | {', '.join(entry['workbench_pages'])} | {', '.join(entry['contract_status'])} | false |"
        for entry in payload["entries"]
    )
    return "\n".join(lines) + "\n"


def _render_planned_adapter_md(payload: dict[str, Any]) -> str:
    lines = [
        "# Planned Adapter Status Report",
        "",
        "- Ready count: 0",
        "- Implemented count: 0",
        "- Can execute locally before v4 count: 0",
        "",
        "| Project | Status | Blocked reason |",
        "| --- | --- | --- |",
    ]
    lines.extend(
        f"| {entry['project_name']} | {', '.join(entry['contract_status'])} | {entry['blocked_reason']} |"
        for entry in payload["entries"]
    )
    return "\n".join(lines) + "\n"


def _render_provider_boundary_md(payload: dict[str, Any]) -> str:
    lines = [
        "# Provider Boundary Report",
        "",
        "Provider, network, secret, and external runtime capabilities are not local-ready in this pass.",
        "",
        "- n8n bundled runtime: false",
        "- AnySearchSkill API callable: false",
        "- WeKnora embedded: false",
        "- LLM Wiki memory engine implemented: false",
        "",
        "| Project | API key | Network | External runtime |",
        "| --- | --- | --- | --- |",
    ]
    lines.extend(
        f"| {entry['project_name']} | {str(entry['requires_api_key']).lower()} | {str(entry['requires_network']).lower()} | {str(entry['requires_external_runtime']).lower()} |"
        for entry in payload["entries"]
    )
    return "\n".join(lines) + "\n"


def _unique(values: list[str]) -> list[str]:
    seen = set()
    result = []
    for value in values:
        if value not in seen:
            seen.add(value)
            result.append(value)
    return result
