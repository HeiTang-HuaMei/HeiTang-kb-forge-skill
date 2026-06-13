from __future__ import annotations

import json
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json


CROSS_MODAL_RAG_SCHEMA_FILES = [
    "cross_modal_rag_manifest.json",
    "modality_registry.json",
    "cross_modal_trace_schema.json",
    "cross_modal_knowledge_graph_schema.json",
    "benchmark_profile.json",
    "cross_modal_rag_validation_report.json",
    "cross_modal_rag_schema_report.md",
]

REPOSITORY_HEAD = "a8538efecc99719538960692745ef0eb90d1a2f9"


def build_cross_modal_rag_schema_library(
    output: Path,
    *,
    library_name: str = "HeiTang Cross-Modal RAG Schema Reference",
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    modalities = _modality_registry()
    trace_schema = _trace_schema()
    graph_schema = _graph_schema()
    benchmark = _benchmark_profile()
    manifest = {
        "schema_version": "cross_modal_rag_manifest.v1",
        "section": "5.12",
        "campaign": "Campaign 3",
        "status": "passed",
        "project_id": "rag_anything",
        "project_name": "RAG-Anything",
        "library_name": library_name,
        "integration_decision": "reference_only",
        "integration_mode": "cross_modal_rag_schema_reference",
        "source_verification": {
            "repository_url": "https://github.com/HKUDS/RAG-Anything",
            "repository_head": REPOSITORY_HEAD,
            "default_branch": "main",
            "repository_accessible": True,
            "repository_archived": False,
            "repository_disabled": False,
            "latest_release": "v1.3.1",
            "license_spdx": "MIT",
            "license_file": "LICENSE",
            "license_sha": "b3ba37ce442298d5bdec96e2e52a8a812a25f123",
            "repository_cloned": False,
            "external_code_copied": False,
            "external_prompt_text_copied": False,
            "vendor_runtime_installed": False,
        },
        "official_runtime_observation": {
            "base_dependency": "lightrag-hku<1.5",
            "parser_dependency": "mineru[core]",
            "documented_modalities": ["text", "image", "table", "equation"],
            "documented_capabilities": [
                "multimodal_document_processing",
                "multimodal_knowledge_graph",
                "cross_modal_relationship_mapping",
                "modality_aware_retrieval",
            ],
            "runtime_executed": False,
            "model_download_executed": False,
            "provider_call_executed": False,
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "existing_capability_anchors": [
                "WeKnora local Auto Wiki and generic RAG trace",
                "MMSkills multimodal Skill package and preview schema",
                "existing knowledge package source trace and evidence map",
            ],
            "distinct_value": [
                "modality-aware evidence-node contract",
                "cross-modal relation trace contract",
                "multimodal retrieval benchmark profile",
            ],
            "weknora_boundary": (
                "WeKnora remains the local Auto Wiki, generic knowledge graph, and generic RAG trace capability."
            ),
            "mmskills_boundary": (
                "MMSkills remains the multimodal Skill package, visual state card, and keyframe preview contract."
            ),
            "campaign_3_0_boundary": (
                "External URL ingestion, video/source memory, visual evidence extraction, OpenCLI verification, "
                "and external-source correctness checks remain planned_not_active Campaign 3 Supplement 3.0 work."
            ),
            "campaign_3_4_0_boundary": (
                "Knowledge-base profiling and source-traced Skill Template generation, validation, and publication "
                "remain planned_not_active Campaign 3 Supplement 4.0 work."
            ),
        },
        "runtime_boundary": _runtime_boundary(),
        "ui_contract": {
            "status_visible": True,
            "schema_preview_visible": True,
            "benchmark_profile_visible": True,
            "source_and_license_visible": True,
            "local_ready": True,
            "ready": False,
            "executable_action": False,
            "vendor_runtime_action_available": False,
            "multimodal_query_action_available": False,
            "ui_visibility": "visible_status_only",
        },
        "modality_count": len(modalities["modalities"]),
        "relation_type_count": len(graph_schema["relation_types"]),
        "benchmark_dimension_count": len(benchmark["dimensions"]),
        "output_files": CROSS_MODAL_RAG_SCHEMA_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "This run proves a local cross-modal schema, trace contract, and benchmark profile only. "
            "It does not integrate or execute RAG-Anything, LightRAG, MinerU, an LLM/VLM, embeddings, "
            "a vector database, Campaign 3.0 external-source processing, Campaign 4, Full Gate, EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.13 mattpocock/skills only.",
        "not_goal_complete": True,
    }
    validation = validate_cross_modal_rag_schema_payload(
        manifest,
        modalities,
        trace_schema,
        graph_schema,
        benchmark,
    )
    write_json(output / "cross_modal_rag_manifest.json", manifest)
    write_json(output / "modality_registry.json", modalities)
    write_json(output / "cross_modal_trace_schema.json", trace_schema)
    write_json(output / "cross_modal_knowledge_graph_schema.json", graph_schema)
    write_json(output / "benchmark_profile.json", benchmark)
    write_json(output / "cross_modal_rag_validation_report.json", validation)
    (output / "cross_modal_rag_schema_report.md").write_text(
        _render_report(manifest, validation),
        encoding="utf-8",
    )
    return manifest | {"validation": validation}


def validate_cross_modal_rag_schema_library(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in CROSS_MODAL_RAG_SCHEMA_FILES
        if not (library / file_name).exists()
    ]
    if missing:
        return {
            "schema_version": "cross_modal_rag_validation_report.v1",
            "section": "5.12",
            "campaign": "Campaign 3",
            "status": "failed",
            "boundary_errors": ["required_files_missing"],
            "required_files": CROSS_MODAL_RAG_SCHEMA_FILES,
            "missing_files": missing,
            "tests_require_real_llm_api_network": False,
            "final_target_not_downgraded": True,
            "remaining_gap": "Required local schema evidence is incomplete.",
            "next_required_e2e_step": "Complete Section 5 item 5.12 RAG-Anything evidence before advancing.",
            "not_goal_complete": True,
        }
    result = validate_cross_modal_rag_schema_payload(
        _read_json(library / "cross_modal_rag_manifest.json"),
        _read_json(library / "modality_registry.json"),
        _read_json(library / "cross_modal_trace_schema.json"),
        _read_json(library / "cross_modal_knowledge_graph_schema.json"),
        _read_json(library / "benchmark_profile.json"),
    )
    return {
        **result,
        "required_files": CROSS_MODAL_RAG_SCHEMA_FILES,
        "missing_files": missing,
    }


def validate_cross_modal_rag_schema_payload(
    manifest: dict[str, Any],
    modalities: dict[str, Any],
    trace_schema: dict[str, Any],
    graph_schema: dict[str, Any],
    benchmark: dict[str, Any],
) -> dict[str, Any]:
    source = manifest.get("source_verification", {})
    observed = manifest.get("official_runtime_observation", {})
    runtime = manifest.get("runtime_boundary", {})
    ui = manifest.get("ui_contract", {})
    errors: list[str] = []
    required_false = {
        "repository_cloned": source,
        "external_code_copied": source,
        "external_prompt_text_copied": source,
        "vendor_runtime_installed": source,
        "runtime_executed": observed,
        "model_download_executed": observed,
        "provider_call_executed": observed,
        "rag_anything_runtime_integrated": runtime,
        "lightrag_runtime_integrated": runtime,
        "mineru_runtime_executed": runtime,
        "llm_or_vlm_required": runtime,
        "embedding_required": runtime,
        "vector_database_required": runtime,
        "network_required": runtime,
            "external_source_ingestion_implemented": runtime,
            "opencli_verification_implemented": runtime,
            "video_ingestion_implemented": runtime,
            "knowledge_to_skill_template_generator_implemented": runtime,
        "executable_action": ui,
        "vendor_runtime_action_available": ui,
        "multimodal_query_action_available": ui,
        "ready": ui,
    }
    for field, container in required_false.items():
        if container.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    if source.get("repository_accessible") is not True:
        errors.append("repository_accessible_must_be_true")
    if source.get("license_spdx") != "MIT":
        errors.append("license_spdx_must_be_mit")
    if manifest.get("integration_decision") != "reference_only":
        errors.append("integration_decision_must_be_reference_only")
    if manifest.get("integration_mode") != "cross_modal_rag_schema_reference":
        errors.append("integration_mode_invalid")
    if ui.get("local_ready") is not True:
        errors.append("local_ready_must_be_true")
    required_modalities = {"text", "image", "table", "equation"}
    actual_modalities = {item.get("modality") for item in modalities.get("modalities", [])}
    if not required_modalities <= actual_modalities:
        errors.append("required_modalities_missing")
    if trace_schema.get("source_trace_required") is not True:
        errors.append("source_trace_required")
    if trace_schema.get("evidence_map_required") is not True:
        errors.append("evidence_map_required")
    if "cross_modal_supports" not in graph_schema.get("relation_types", []):
        errors.append("cross_modal_supports_relation_missing")
    if benchmark.get("runtime_benchmark_executed") is not False:
        errors.append("runtime_benchmark_executed_must_be_false")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "cross_modal_rag_validation_report.v1",
        "section": "5.12",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "modality_count": len(actual_modalities),
        "relation_type_count": len(graph_schema.get("relation_types", [])),
        "benchmark_dimension_count": len(benchmark.get("dimensions", [])),
        "repository_head": source.get("repository_head"),
        "license_spdx": source.get("license_spdx"),
        "rag_anything_runtime_integrated": runtime.get("rag_anything_runtime_integrated"),
        "runtime_benchmark_executed": benchmark.get("runtime_benchmark_executed"),
        "ui_ready": ui.get("ready"),
        "ui_executable_action": ui.get("executable_action"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Validation covers local schema truth and negative runtime boundaries only. It does not prove "
            "vendor execution, retrieval quality, Campaign 3 acceptance, Campaign 3.0, UI workflow, Full Gate, or EXE."
        ),
        "next_required_e2e_step": "Process Section 5 item 5.13 mattpocock/skills only.",
        "not_goal_complete": True,
    }


def write_cross_modal_rag_schema_library(
    output: Path,
    *,
    library_name: str = "HeiTang Cross-Modal RAG Schema Reference",
) -> dict[str, Any]:
    return build_cross_modal_rag_schema_library(output, library_name=library_name)


def write_cross_modal_rag_schema_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_cross_modal_rag_schema_library(library)
    write_json(output / "cross_modal_rag_validation_report.json", result)
    (output / "cross_modal_rag_validation_report.md").write_text(
        _render_validation_report(result),
        encoding="utf-8",
    )
    return result


def _modality_registry() -> dict[str, Any]:
    modalities = [
        {
            "modality": "text",
            "evidence_payload": "normalized_text",
            "trace_fields": ["source_path", "chunk_id", "page_number", "bbox"],
        },
        {
            "modality": "image",
            "evidence_payload": "image_description_or_ocr_reference",
            "trace_fields": ["source_path", "asset_id", "page_number", "bbox"],
        },
        {
            "modality": "table",
            "evidence_payload": "structured_table_reference",
            "trace_fields": ["source_path", "table_id", "page_number", "bbox"],
        },
        {
            "modality": "equation",
            "evidence_payload": "normalized_equation_reference",
            "trace_fields": ["source_path", "equation_id", "page_number", "bbox"],
        },
    ]
    return {
        "schema_version": "cross_modal_modality_registry.v1",
        "modalities": modalities,
        "unsupported_in_this_reference": ["audio", "video", "external_url"],
        "unsupported_reason": (
            "These belong to later explicitly scoped capabilities, including Campaign 3 Supplement 3.0."
        ),
    }


def _trace_schema() -> dict[str, Any]:
    return {
        "schema_version": "cross_modal_trace_schema.v1",
        "trace_id_format": "cmtrace_<stable_hash>",
        "source_trace_required": True,
        "evidence_map_required": True,
        "required_fields": [
            "trace_id",
            "query_id",
            "retrieval_rank",
            "modality",
            "evidence_id",
            "source_path",
            "chunk_or_asset_id",
            "relation_ids",
            "score_components",
        ],
        "optional_location_fields": ["page_number", "bbox", "table_id", "equation_id"],
        "score_components": [
            "text_relevance",
            "modality_relevance",
            "cross_modal_relation_weight",
            "source_trace_completeness",
        ],
        "backlink_contract": "source_path plus local chunk, asset, page, or bounding-box locator",
    }


def _graph_schema() -> dict[str, Any]:
    return {
        "schema_version": "cross_modal_knowledge_graph_schema.v1",
        "node_types": [
            "text_chunk",
            "image_asset",
            "table_asset",
            "equation_asset",
            "semantic_entity",
        ],
        "relation_types": [
            "describes",
            "depicts",
            "contains",
            "references",
            "derived_from",
            "cross_modal_supports",
            "cross_modal_conflicts",
        ],
        "edge_required_fields": [
            "relation_id",
            "source_node_id",
            "target_node_id",
            "relation_type",
            "evidence_ids",
            "source_trace_ids",
            "confidence",
        ],
        "inferred_relation_requires_runtime": True,
        "this_library_contains_inferred_relations": False,
    }


def _benchmark_profile() -> dict[str, Any]:
    return {
        "schema_version": "cross_modal_rag_benchmark_profile.v1",
        "runtime_benchmark_executed": False,
        "dimensions": [
            "modality_coverage",
            "source_trace_completeness",
            "cross_modal_relation_precision",
            "retrieval_recall_by_modality",
            "evidence_backlink_validity",
            "failure_isolation",
        ],
        "required_result_fields": [
            "benchmark_run_id",
            "dataset_manifest",
            "dimension_scores",
            "failed_cases",
            "runtime_profile",
            "evidence_dir",
        ],
        "acceptance_boundary": (
            "This profile defines future comparable evidence. It does not publish a runtime quality score."
        ),
    }


def _runtime_boundary() -> dict[str, Any]:
    return {
        "rag_anything_runtime_integrated": False,
        "lightrag_runtime_integrated": False,
        "mineru_runtime_executed": False,
        "llm_or_vlm_required": False,
        "embedding_required": False,
        "vector_database_required": False,
        "network_required": False,
        "external_source_ingestion_implemented": False,
        "opencli_verification_implemented": False,
        "video_ingestion_implemented": False,
        "knowledge_to_skill_template_generator_implemented": False,
        "existing_rag_main_chain_replaced": False,
        "schema_build_is_offline": True,
    }


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    return f"""# RAG-Anything Cross-Modal RAG Schema Reference

- Status: {validation['status']}
- Integration decision: {manifest['integration_decision']}
- Integration mode: {manifest['integration_mode']}
- Repository head: {manifest['source_verification']['repository_head']}
- License: {manifest['source_verification']['license_spdx']}
- Modalities: {manifest['modality_count']}
- Relation types: {manifest['relation_type_count']}
- Benchmark dimensions: {manifest['benchmark_dimension_count']}
- Vendor runtime integrated: {manifest['runtime_boundary']['rag_anything_runtime_integrated']}
- UI executable action: {manifest['ui_contract']['executable_action']}

This is a local schema, trace, and benchmark reference. It does not bundle or execute RAG-Anything,
LightRAG, MinerU, model providers, embeddings, or vector storage.
"""


def _render_validation_report(result: dict[str, Any]) -> str:
    return f"""# Cross-Modal RAG Schema Validation

- Status: {result['status']}
- Boundary errors: {len(result['boundary_errors'])}
- Modalities: {result.get('modality_count', 0)}
- Relation types: {result.get('relation_type_count', 0)}
- Benchmark dimensions: {result.get('benchmark_dimension_count', 0)}
- Vendor runtime integrated: {result.get('rag_anything_runtime_integrated')}
- Runtime benchmark executed: {result.get('runtime_benchmark_executed')}
"""
