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
    "provider_capability_status.json",
    "provider_capability_status.md",
]

BLOCKED_REASON_TAXONOMY = [
    ("external_project_registry_only", "Registry and roadmap entry only; no runtime integration is claimed."),
    ("benchmark_only_not_runtime", "Benchmark pattern only; it must not be treated as bundled runtime."),
    ("planned_adapter_not_implemented", "Adapter is planned but not implemented or ready."),
    ("optional_runtime_dependency_missing", "Optional local runtime adapter exists but the dependency is not bundled or required."),
    ("future_adapter_after_v4", "Adapter or capability is explicitly post-v4."),
    ("provider_required", "Requires a user-configured provider boundary before runtime use."),
    ("secret_required", "Requires explicit user-provided secret material; no fixture may include it."),
    ("network_required", "Requires network access and cannot be counted as local-ready."),
    ("ui_configuration_pending", "Desktop UI provider configuration and execution workflow are not accepted yet."),
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
    "llm_wiki_v2": ["capability_fusion", "real_integration", "runtime_not_bundled"],
    "weknora": ["capability_fusion", "real_integration", "runtime_not_bundled"],
    "n8n": ["workflow_export_adapter", "export_validation_passed", "runtime_not_bundled"],
    "anysearchskill": ["provider_adapter", "real_smoke_passed", "needs_strengthening"],
    "andrej_karpathy_skills": ["benchmark_only", "capability_anchor"],
    "last30days_skill": ["provider_required", "future_adapter"],
    "skill_prompt_generator": [
        "prompt_asset_library_enhancer",
        "real_integration",
        "runtime_not_bundled",
        "license_gate_pending",
    ],
    "mmskills": ["schema_package_reference", "reference_only", "runtime_not_bundled"],
    "jellyfish": ["content_asset_schema_reference", "reference_only", "runtime_not_bundled"],
    "story_flicks": ["aigc_video_pipeline_schema_reference", "reference_only", "runtime_not_bundled"],
    "seedance2_skill": [
        "verified_video_skill_template_metadata",
        "reference_only",
        "template_reference",
        "provider_not_integrated",
        "runtime_not_bundled",
    ],
    "rag_anything": [
        "cross_modal_rag_schema_reference",
        "reference_only",
        "runtime_not_bundled",
    ],
    "mattpocock_skills": [
        "engineering_governance_rule_pack",
        "real_integration",
        "runtime_not_bundled",
    ],
    "sirchmunk": [
        "bounded_direct_file_search_provider",
        "real_integration",
        "runtime_not_bundled",
        "embedding_free",
        "vector_db_not_required",
    ],
    "ai_marketing_skills": ["marketing_skill_pattern_library", "real_integration", "runtime_not_bundled"],
    "rtk": ["benchmark_only"],
    "opendataloader": ["planned_adapter"],
    "paddleocr": ["planned_adapter", "optional_runtime_adapter"],
    "mineru": ["planned_adapter"],
    "docling": ["planned_adapter", "optional_runtime_adapter"],
    "marker": ["planned_adapter"],
    "surya": ["planned_adapter"],
    "unstructured": ["planned_adapter", "optional_runtime_adapter"],
    "llamaindex": ["benchmark_only"],
    "ragas": ["benchmark_only", "future_adapter"],
    "deepeval": ["benchmark_only", "future_adapter"],
}

INTEGRATED_PROJECT_STATE = {
    "llm_wiki_v2": {
        "local_ready": True,
        "blocked_reasons": ["ui_visibility_only"],
        "ui_visibility": "visible_status_only",
        "boundary": "Local Knowledge Lifecycle capability fusion is implemented. No LLM Wiki vendor runtime or external code is bundled.",
    },
    "weknora": {
        "local_ready": True,
        "blocked_reasons": ["ui_visibility_only"],
        "ui_visibility": "visible_status_only",
        "boundary": "Local Auto Wiki, Knowledge Graph, RAG trace, and visual trace capability fusion is implemented. No WeKnora runtime is bundled.",
    },
    "n8n": {
        "local_ready": True,
        "blocked_reasons": [
            "external_runtime_required",
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local, offline n8n workflow export adapter is implemented and validated. Import and execution require a user-owned n8n runtime; no runtime or credentials are bundled.",
    },
    "anysearchskill": {
        "local_ready": False,
        "can_execute_after_provider_config": True,
        "blocked_reasons": [
            "ui_configuration_pending",
            "network_required",
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A controlled network provider adapter, anonymous real smoke, and real retrieval run are implemented. UI/Core Bridge and real proxy-path acceptance remain incomplete.",
    },
    "skill_prompt_generator": {
        "local_ready": True,
        "blocked_reasons": [
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local Prompt Asset Library / Skill Factory enhancer is implemented and validated from existing Skill Suite evidence. No skill-prompt-generator repository code, external prompts, or runtime is bundled; P2.2 Skill Factory is not replaced.",
    },
    "mmskills": {
        "local_ready": True,
        "blocked_reasons": [
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local multimodal Skill package schema/reference, visual state card contract, keyframe index, and preview validator are implemented. No MMSkills repository code, OSWorld runtime, raw trajectories, or branch-loaded runtime is bundled or executed.",
    },
    "jellyfish": {
        "local_ready": True,
        "blocked_reasons": [
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local original Content Asset Schema reference, storyboard metadata schema, continuity notes, and production checkpoint contract are implemented and validated. No Jellyfish repository code, short-drama workbench runtime, video generation runtime, asset rendering runtime, or network media operation is bundled or executed.",
    },
    "story_flicks": {
        "local_ready": True,
        "blocked_reasons": [
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local original AIGC video pipeline schema reference with stage, asset handoff, timeline metadata, and delivery checkpoint contracts is implemented and validated. No story-flicks repository code, story-to-video runtime, image/audio/video generation runtime, voice cloning, media rendering, provider execution, or network media operation is bundled or executed.",
    },
    "seedance2_skill": {
        "local_ready": True,
        "blocked_reasons": [
            "provider_required",
            "secret_required",
            "network_required",
            "license_review_required",
            "security_review_required",
            "template_reference_only",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "The public seedance2-skill repository identity and MIT license are verified and represented as local non-executable video Skill template metadata. No external SKILL.md or prompt text is copied, no provider adapter or credential flow is integrated, and no Seedance API request, video generation, media transfer, rendering, or account operation is available.",
    },
    "rag_anything": {
        "local_ready": True,
        "blocked_reasons": [
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local original cross-modal RAG schema, modality-aware evidence trace contract, cross-modal knowledge graph schema, and benchmark profile are implemented and validated. No RAG-Anything, LightRAG, MinerU, LLM/VLM, embedding, vector database, external-source ingestion, or multimodal query runtime is bundled or executed.",
    },
    "mattpocock_skills": {
        "local_ready": True,
        "blocked_reasons": [
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local engineering governance rule-pack is implemented and validated for Pre-Code Gate, Test Gate, Review Gate, and AI collaboration discipline. No mattpocock/skills code, prompts, SKILL.md files, scripts, runtime, Agent creation, Agent binding, or executable workflow is bundled or executed.",
    },
    "sirchmunk": {
        "local_ready": True,
        "blocked_reasons": [
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local bounded direct-file-search provider candidate is implemented and validated with workspace path-boundary enforcement, source trace, and evidence map. No Sirchmunk vendor runtime, LLM/API key, network call, embedding, vector DB, index build requirement, or arbitrary shell execution is bundled or executed.",
    },
    "ai_marketing_skills": {
        "local_ready": True,
        "blocked_reasons": [
            "license_review_required",
            "security_review_required",
            "ui_visibility_only",
        ],
        "ui_visibility": "visible_status_only",
        "boundary": "A local original Marketing Skill Pattern Library is implemented and validated for Template Library / Skill Factory preview. No ai-marketing-skills repository code, prompts, SKILL.md files, scripts, crawler, paid media execution, account operation, or runtime is bundled or executed.",
    },
}

INTERNAL_ANCHOR_STATUS = {
    "book_to_skill": ["internal_capability", "implemented"],
    "package_to_skill": ["internal_capability", "implemented"],
    "software_to_manual_to_skill": ["internal_capability", "future_adapter"],
    "aigc_book_content_pipeline": ["internal_capability", "template_reference"],
    "retrieval_and_verification": ["internal_capability", "implemented"],
    "memory_lifecycle": ["internal_capability", "implemented_baseline", "future_adapter"],
    "auto_wiki_knowledge_graph": ["internal_capability", "implemented_baseline", "future_adapter"],
    "workflow_automation_export": ["internal_capability", "implemented_baseline", "future_runtime_adapter"],
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
    "rag_anything": ["retrieval_verification", "reports_audit"],
    "mattpocock_skills": ["governance", "reports_audit"],
    "sirchmunk": ["retrieval_verification", "reports_audit"],
    "ai_marketing_skills": ["template_library", "skill_factory"],
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
    "bounded_direct_file_search_provider": ["tool_call_failed"],
}

PROVIDER_CAPABILITY_AREAS = [
    {
        "capability_id": "document_parser_ocr",
        "capability_area": "document_library",
        "user_visible_name": "Parser / OCR",
        "zh_user_visible_name": "解析 / OCR",
        "provider_type": "parser_ocr",
        "project_ids": ["docling", "paddleocr", "unstructured", "opendataloader", "mineru", "marker", "surya"],
        "fallback": "local_parser",
    },
    {
        "capability_id": "knowledge_embedding_vector",
        "capability_area": "knowledge_index",
        "user_visible_name": "Embedding / Vector DB",
        "zh_user_visible_name": "Embedding / 向量库",
        "provider_type": "embedding_vector",
        "project_ids": ["rag_anything", "llamaindex", "weknora"],
        "fallback": "local_keyword_index",
    },
    {
        "capability_id": "retrieval_provider",
        "capability_area": "retrieval_rag",
        "user_visible_name": "Search / Retrieval",
        "zh_user_visible_name": "检索 / 召回",
        "provider_type": "search_retrieval",
        "project_ids": ["anysearchskill", "last30days_skill", "sirchmunk", "ragas", "deepeval"],
        "fallback": "local_rag_retrieval",
    },
    {
        "capability_id": "document_exporter",
        "capability_area": "document_generation",
        "user_visible_name": "Document Exporter",
        "zh_user_visible_name": "文档导出器",
        "provider_type": "exporter",
        "project_ids": ["n8n", "jellyfish", "story_flicks"],
        "fallback": "local_markdown_json_csv_export",
    },
    {
        "capability_id": "skill_template_provider",
        "capability_area": "skill_factory",
        "user_visible_name": "Skill Template / Governance",
        "zh_user_visible_name": "Skill 模板 / 治理",
        "provider_type": "skill_template",
        "project_ids": [
            "andrej_karpathy_skills",
            "skill_prompt_generator",
            "mmskills",
            "mattpocock_skills",
            "ai_marketing_skills",
            "seedance2_skill",
        ],
        "fallback": "local_skill_factory",
    },
    {
        "capability_id": "agent_model_tools_memory",
        "capability_area": "agent_workbench",
        "user_visible_name": "Agent Model / Tools / Memory",
        "zh_user_visible_name": "Agent 模型 / 工具 / 记忆",
        "provider_type": "agent_capability",
        "project_ids": ["llm_wiki_v2", "rtk"],
        "fallback": "local_agent_workspace",
    },
    {
        "capability_id": "workflow_collaboration_export",
        "capability_area": "orchestration_a2a",
        "user_visible_name": "Workflow / Collaboration Export",
        "zh_user_visible_name": "工作流 / 协作导出",
        "provider_type": "workflow_collaboration",
        "project_ids": ["n8n"],
        "fallback": "local_orchestration_audit",
    },
    {
        "capability_id": "governance_audit_provider",
        "capability_area": "governance_audit",
        "user_visible_name": "Governance / Audit",
        "zh_user_visible_name": "治理 / 审计",
        "provider_type": "governance_audit",
        "project_ids": ["mattpocock_skills", "ragas", "deepeval"],
        "fallback": "local_audit_history",
    },
]

ARCHITECTURE_REFERENCE_ABSORB_TARGETS = [
    "contract",
    "schema",
    "runtime_boundary",
    "ui_information_architecture",
    "test_gate",
    "audit_model",
    "fallback_strategy",
    "provider_loading_rule",
]


def load_external_project_registry(repo_root: Path | None = None) -> dict[str, Any]:
    root = repo_root or Path.cwd()
    registry_path = root / SOURCE_REGISTRY_RELATIVE_PATH
    if registry_path.exists():
        return _normalize_stage3_future_reference_queue(
            json.loads(registry_path.read_text(encoding="utf-8"))
        )
    return _normalize_stage3_future_reference_queue(
        _default_external_project_registry()
    )


STAGE3_FUTURE_REFERENCE_DECISIONS = {
    "andrej_karpathy_skills": {
        "entry_class": "template_asset",
        "architecture_status": "absorbed_into_architecture",
        "blocker": "",
        "rejection_reason": "",
    },
    "presenton": {
        "entry_class": "architecture_reference",
        "architecture_status": "deferred_with_blocker",
        "blocker": (
            "Requires an Exporter Provider contract, local PPTX export proof, "
            "health/readiness evidence, and rollback audit before absorption."
        ),
        "rejection_reason": "",
    },
    "codegraph": {
        "entry_class": "architecture_reference",
        "architecture_status": "rejected_no_architecture_gain",
        "blocker": "",
        "rejection_reason": (
            "Developer code graph tooling does not improve the ordinary v3 "
            "document-to-KB-to-Agent user chain beyond existing audit/governance boundaries."
        ),
    },
    "understand_anything": {
        "entry_class": "architecture_reference",
        "architecture_status": "rejected_no_architecture_gain",
        "blocker": "",
        "rejection_reason": (
            "Interactive code/navigation visualization is outside the ordinary "
            "knowledge workbench main chain and overlaps existing UI architecture work."
        ),
    },
    "nvlabs_longlive": {
        "entry_class": "architecture_reference",
        "architecture_status": "rejected_no_architecture_gain",
        "blocker": "",
        "rejection_reason": (
            "Long-video model engineering requires GPU/vendor runtime scope that "
            "conflicts with the current Provider boundary and offers no near-term v3 main-chain gain."
        ),
    },
    "claude_plugins_official": {
        "entry_class": "architecture_reference",
        "architecture_status": "rejected_no_architecture_gain",
        "blocker": "",
        "rejection_reason": (
            "Plugin marketplace compatibility is not an authorized product surface "
            "and is covered by the existing Provider loading rule boundary."
        ),
    },
    "pi_mono": {
        "entry_class": "architecture_reference",
        "architecture_status": "deferred_with_blocker",
        "blocker": (
            "Requires Agent runtime contract, permission allow/deny evidence, "
            "memory/tool sandbox proof, and rollback audit before absorption."
        ),
        "rejection_reason": "",
    },
}


def _normalize_stage3_future_reference_queue(
    registry: dict[str, Any],
) -> dict[str, Any]:
    normalized = dict(registry)
    queue = []
    for item in registry.get("future_reference_queue", []):
        project_id = item.get("project_id", "")
        decision = STAGE3_FUTURE_REFERENCE_DECISIONS.get(project_id)
        if not decision:
            queue.append(dict(item))
            continue
        legacy_status = item.get("legacy_status", item.get("status", "needs_verification"))
        entry_class = decision["entry_class"]
        architecture_status = decision["architecture_status"]
        current = {
            **item,
            "status": architecture_status,
            "legacy_status": legacy_status,
            "stage3_current_classification": entry_class,
            "registry_entry_class": entry_class,
            "architecture_reference_status": architecture_status,
            "architecture_absorption": _future_reference_architecture_absorption(
                project_id,
                legacy_status,
                entry_class,
                architecture_status,
                decision["blocker"],
                decision["rejection_reason"],
            ),
            "runtime_load_class": _stage3_runtime_load_class(entry_class),
        }
        queue.append(current)
    normalized["future_reference_queue"] = queue
    return normalized


def _default_external_project_registry() -> dict[str, Any]:
    """Built-in registry fallback for clean v4.2 public main.

    Historical registry files are no longer tracked in public main, but the Core
    still needs to regenerate external capability matrices in a fresh clone.
    """
    project_rows = [
        ("llm_wiki_v2", "LLM Wiki v2", "https://github.com/karpathy/llm-wiki", "S", "real_workflow_evidence", "capability_fusion", False, False, False, "P2.4"),
        ("weknora", "WeKnora", "https://github.com/tencent/weknora", "S", "real_workflow_evidence", "capability_fusion", False, False, False, "P2.5"),
        ("n8n", "n8n", "https://github.com/n8n-io/n8n", "S", "real_workflow_evidence", "workflow_export", False, False, True, "P2.2 / P3"),
        ("andrej_karpathy_skills", "andrej-karpathy-skills", "https://github.com/multica-ai/andrej-karpathy-skills", "S", "benchmark_mapped", "capability_fusion", False, False, False, "P2.9"),
        ("paddleocr", "PaddleOCR", "https://github.com/PaddlePaddle/PaddleOCR", "S", "planned_adapter", "optional_runtime_adapter", False, False, False, "P2.1"),
        ("mineru", "MinerU", "https://github.com/opendatalab/MinerU", "S", "planned_adapter", "planned_adapter", False, False, False, "P2.6"),
        ("docling", "Docling", "https://github.com/docling-project/docling", "S", "planned_adapter", "optional_runtime_adapter", False, False, False, "P2.1"),
        ("unstructured", "Unstructured", "https://github.com/Unstructured-IO/unstructured", "S", "planned_adapter", "optional_runtime_adapter", False, False, False, "P2.1"),
        ("anysearchskill", "AnySearchSkill", "https://github.com/anysearch-ai/anysearch-skill", "A", "real_workflow_evidence", "provider_adapter", False, True, False, "P2.3"),
        ("last30days_skill", "last30days-skill", "https://github.com/mvanhorn/last30days-skill", "A", "benchmark_mapped", "provider_adapter", False, True, False, "P2.3 / P3"),
        ("skill_prompt_generator", "skill-prompt-generator", "https://github.com/huangserva/skill-prompt-generator", "A", "real_workflow_evidence", "prompt_asset_library_enhancer", False, False, False, "P2.9"),
        ("mmskills", "MMSkills", "https://github.com/DeepExperience/MMSkills", "A", "reference_schema_evidence", "schema_package_reference", False, False, False, "P2.8 / P3"),
        ("jellyfish", "Jellyfish", "https://github.com/Forget-C/Jellyfish", "A", "reference_schema_evidence", "content_asset_schema_reference", False, False, False, "P2.8 / P3"),
        ("story_flicks", "story-flicks", "https://github.com/alecm20/story-flicks", "A", "reference_schema_evidence", "aigc_video_pipeline_schema_reference", False, False, False, "P2.8 / P3"),
        ("seedance2_skill", "seedance2-skill", "https://github.com/dexhunter/seedance2-skill", "A", "reference_schema_evidence", "verified_video_skill_template_metadata", True, True, False, "P2.8 / P3"),
        ("rag_anything", "RAG-Anything", "https://github.com/HKUDS/RAG-Anything", "A", "reference_schema_evidence", "cross_modal_rag_schema_reference", False, False, False, "P2.5 / P2.6"),
        ("mattpocock_skills", "mattpocock/skills", "https://github.com/mattpocock/skills", "A", "real_workflow_evidence", "engineering_governance_rule_pack", False, False, False, "P2.2 / governance"),
        ("sirchmunk", "Sirchmunk", "https://github.com/modelscope/sirchmunk", "A", "real_workflow_evidence", "bounded_direct_file_search_provider", False, False, False, "P2.8 / local retrieval"),
        ("ai_marketing_skills", "ai-marketing-skills", "https://github.com/ericosiu/ai-marketing-skills", "A", "real_workflow_evidence", "marketing_skill_pattern_library", False, False, False, "P2.7"),
        ("rtk", "rtk", "https://github.com/rtk-ai/rtk", "A", "benchmark_mapped", "token_compression_cli_benchmark", False, False, True, "P3"),
        ("opendataloader", "OpenDataLoader", "https://github.com/opendataloader-project/opendataloader-pdf", "A", "planned_adapter", "planned_adapter", False, False, False, "P2.6"),
        ("marker", "Marker", "https://github.com/datalab-to/marker", "A", "planned_adapter", "planned_adapter", False, False, False, "P2.6"),
        ("surya", "Surya", "https://github.com/datalab-to/surya", "A", "planned_adapter", "ocr_layout_backend", False, False, False, "P2.6"),
        ("llamaindex", "LlamaIndex", "https://github.com/run-llama/llama_index", "A", "benchmark_mapped", "benchmark_only", False, False, False, "P2.5"),
        ("ragas", "RAGAS", "https://github.com/explodinggradients/ragas", "A", "benchmark_mapped", "benchmark_only", False, False, False, "P2.5"),
        ("deepeval", "DeepEval", "https://github.com/confident-ai/deepeval", "A", "docs_only", "benchmark_only", False, False, False, "P2.5"),
    ]
    anchors = [
        ("book_to_skill", "Book-to-Skill", "implemented", "P2.6", ["andrej_karpathy_skills", "skill_prompt_generator"]),
        ("package_to_skill", "Package-to-Skill", "implemented", "P2.6 / P2.9", ["andrej_karpathy_skills", "skill_prompt_generator"]),
        ("software_to_manual_to_skill", "Software-to-Manual-to-Skill", "contract_only / planned_capability", "P2.6", ["andrej_karpathy_skills", "skill_prompt_generator"]),
        ("aigc_book_content_pipeline", "AIGC Book Content Pipeline", "docs_only", "P2.7 / P2.8", ["jellyfish", "story_flicks", "ai_marketing_skills"]),
        ("retrieval_and_verification", "Retrieval & Verification", "implemented", "P2.3 / P2.5", ["anysearchskill", "llamaindex", "ragas", "deepeval"]),
        ("memory_lifecycle", "Memory Lifecycle", "implemented baseline", "P2.4", ["llm_wiki_v2"]),
        ("auto_wiki_knowledge_graph", "Auto Wiki / Knowledge Graph", "implemented baseline", "P2.5", ["weknora"]),
        ("workflow_automation_export", "Workflow Automation / Export", "implemented export baseline", "P2.2 / P3", ["n8n"]),
    ]
    future_queue = [
        (
            "andrej_karpathy_skills",
            "andrej-karpathy-skills",
            "reference_only",
            "template_asset",
            "absorbed_into_architecture",
            "",
            "",
            True,
        ),
        (
            "presenton",
            "Presenton",
            "needs_verification",
            "architecture_reference",
            "deferred_with_blocker",
            "Requires an Exporter Provider contract, local PPTX export proof, health/readiness evidence, and rollback audit before absorption.",
            "",
            False,
        ),
        (
            "codegraph",
            "CodeGraph",
            "needs_verification",
            "architecture_reference",
            "rejected_no_architecture_gain",
            "",
            "Developer code graph tooling does not improve the ordinary v3 document-to-KB-to-Agent user chain beyond existing audit/governance boundaries.",
            False,
        ),
        (
            "understand_anything",
            "Understand Anything",
            "needs_verification",
            "architecture_reference",
            "rejected_no_architecture_gain",
            "",
            "Interactive code/navigation visualization is outside the ordinary knowledge workbench main chain and overlaps existing UI architecture work.",
            False,
        ),
        (
            "nvlabs_longlive",
            "NVlabs/LongLive",
            "needs_verification",
            "architecture_reference",
            "rejected_no_architecture_gain",
            "",
            "Long-video model engineering requires GPU/vendor runtime scope that conflicts with the current Provider boundary and offers no near-term v3 main-chain gain.",
            False,
        ),
        (
            "claude_plugins_official",
            "claude-plugins-official",
            "needs_verification",
            "architecture_reference",
            "rejected_no_architecture_gain",
            "",
            "Plugin marketplace compatibility is not an authorized product surface and is covered by the existing Provider loading rule boundary.",
            False,
        ),
        (
            "pi_mono",
            "pi-mono",
            "needs_verification",
            "architecture_reference",
            "deferred_with_blocker",
            "Requires Agent runtime contract, permission allow/deny evidence, memory/tool sandbox proof, and rollback audit before absorption.",
            "",
            False,
        ),
    ]
    roadmap = [
        ("P2.1", "External Project Verification Baseline + Parser/OCR Multi-Backend Integration", ["registry and contract inclusion", "parser/OCR backend adapter"]),
        ("P2.2", "Skill Governance + Book-to-Skill Deepening", ["skill governance", "Book-to-Skill / Software-to-Manual-to-Skill"]),
        ("P2.3", "External Retrieval Provider Boundary", ["provider boundary", "freshness verification"]),
        ("P2.4", "Memory Lifecycle Deepening", ["memory lifecycle", "confidence and decay"]),
        ("P2.5", "Retrieval / Verification / Knowledge Graph", ["retrieval evaluation", "knowledge graph"]),
        ("P2.6", "Parser and Document Understanding", ["document parser", "layout/OCR"]),
        ("P2.7", "Operation and Growth Templates", ["business templates", "marketing patterns"]),
        ("P2.8", "Visual / Multimodal References", ["visual schemas", "multimodal evidence"]),
        ("P2.9", "Skill Methodology and Governance", ["skill methodology", "governance"]),
        ("P3", "Ecosystem Expansion", ["future adapters", "user-owned runtimes"]),
        ("P4", "Release Planning", ["release hardening"]),
    ]
    evidence_files_by_project = {
        "seedance2_skill": [
            "heitang_kb_forge/video_skill_template_metadata/builder.py",
            "tests/test_video_skill_template_metadata.py",
        ],
        "rag_anything": [
            "heitang_kb_forge/cross_modal_rag_schema/builder.py",
            "tests/test_cross_modal_rag_schema.py",
        ],
        "mattpocock_skills": [
            "heitang_kb_forge/engineering_governance_rules/builder.py",
            "tests/test_engineering_governance_rules.py",
        ],
        "sirchmunk": [
            "heitang_kb_forge/external_retrieval/sirchmunk.py",
            "tests/test_sirchmunk_direct_file_search.py",
        ],
    }
    projects = [
        {
            "project_id": project_id,
            "project_name": project_name,
            "github_url": github_url,
            "rating": rating,
            "current_repo_status": current_repo_status,
            "current_evidence_files": evidence_files_by_project.get(project_id, []),
            "mapped_capabilities": [project_id],
            "suitable_for_heitang": [],
            "not_suitable_parts": [],
            "pre_v4_scope": "registry_fallback",
            "post_v4_target": post_v4_target,
            "ui_impact": "medium",
            "implementation_mode": implementation_mode,
            "requires_api_key": requires_api_key,
            "requires_network": requires_network,
            "requires_external_runtime": requires_external_runtime,
            "license_or_security_review_required": True,
            "can_be_ready_before_v4": False,
            "reason_not_ready_before_v4": "v4.2 public main keeps registry fallback only; no external runtime is bundled.",
            "recommended_next_action": "Keep as future/reference boundary unless an ordered campaign activates it.",
        }
        for (
            project_id,
            project_name,
            github_url,
            rating,
            current_repo_status,
            implementation_mode,
            requires_api_key,
            requires_network,
            requires_external_runtime,
            post_v4_target,
        ) in project_rows
    ]
    internal_anchors = [
        {
            "anchor_id": anchor_id,
            "anchor_name": anchor_name,
            "rating": "S",
            "current_status": current_status,
            "pre_v4_scope": "already_core_capability" if "implemented" in current_status else "contract_mapping_only",
            "post_v4_target": post_v4_target,
            "related_external_benchmarks": related,
        }
        for anchor_id, anchor_name, current_status, post_v4_target, related in anchors
    ]
    return {
        "registry_id": "v4_2_builtin_external_project_registry",
        "scope": "Built-in v4.2 clean-main fallback. No external project runtime is integrated by this registry.",
        "core_repo": "kb-forge-skill",
        "core_branch": "main",
        "v4_0_started": False,
        "tag_created": False,
        "release_written": False,
        "external_features_implemented": True,
        "planned_adapters_marked_ready": False,
        "rating_counts": {"S": 8, "A": 18, "B": 0, "needs_verification_status": 0},
        "future_reference_queue": [
            {
                "project_id": project_id,
                "project_name": project_name,
                "reference_role": "future/reference queue",
                "status": architecture_status,
                "legacy_status": legacy_status,
                "stage3_current_classification": entry_class,
                "registry_entry_class": entry_class,
                "architecture_reference_status": architecture_status,
                "architecture_absorption": _future_reference_architecture_absorption(
                    project_id,
                    legacy_status,
                    entry_class,
                    architecture_status,
                    blocker,
                    rejection_reason,
                ),
                "runtime_load_class": _stage3_runtime_load_class(entry_class),
                "implementation_mode": "not_integrated",
                "current_version_required": current_version_required,
                "runtime_dependency_added": False,
                "npm_install_required": False,
                "gpu_runtime_integration": False,
                "mcp_or_plugin_execution": False,
                "no_runtime_dependency_added": True,
                "no_npm_install": True,
                "no_gpu_runtime_integration": True,
                "no_mcp_plugin_execution": True,
                "boundary": "Reference queue only; no runtime dependency or plugin execution is active.",
            }
            for (
                project_id,
                project_name,
                legacy_status,
                entry_class,
                architecture_status,
                blocker,
                rejection_reason,
                current_version_required,
            ) in future_queue
        ],
        "projects": projects,
        "internal_capability_anchors": internal_anchors,
        "post_v4_roadmap": [
            {"phase": phase, "title": title, "primary_s_a_directions": directions, "scope": directions}
            for phase, title, directions in roadmap
        ],
    }


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
    provider_status = _provider_capability_status(projects)

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
        "provider_capability_status.json": provider_status,
        "provider_capability_status.md": _render_provider_capability_status_md(provider_status),
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
        "external_features_implemented": registry["release_boundary"]["external_features_implemented"],
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
        "scope": "S/A external project contract inclusion plus optional parser/OCR runtime adapter visibility. External runtimes are opt-in and not bundled.",
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
            "external_features_implemented": any(project["implemented"] for project in projects),
            "planned_adapters_marked_ready": False,
            "provider_network_api_ready": False,
        },
    }


def _project_entry(project: dict[str, Any], page_titles: dict[str, str], page_actions: dict[str, list[str]]) -> dict[str, Any]:
    statuses = CONTRACT_STATUS_BY_PROJECT[project["project_id"]]
    page_ids = PROJECT_PAGE_MAPPING[project["project_id"]]
    integrated = INTEGRATED_PROJECT_STATE.get(project["project_id"])
    entry_class = _stage3_registry_entry_class(project["project_id"], statuses)
    architecture_status = _stage3_architecture_reference_status(
        project["project_id"],
        statuses,
        entry_class,
    )
    blocked_reasons = (
        list(integrated["blocked_reasons"])
        if integrated
        else _blocked_reasons(project, statuses)
    )
    related_error_codes = _related_error_codes(project, statuses)
    related_actions = sorted({action_id for page_id in page_ids for action_id in page_actions.get(page_id, [])})
    return {
        "project_id": project["project_id"],
        "project_name": project["project_name"],
        "rating": project["rating"],
        "github_url": project["github_url"],
        "contract_status": statuses,
        "stage3_current_classification": entry_class,
        "registry_entry_class": entry_class,
        "architecture_reference_status": architecture_status,
        "architecture_absorption": _stage3_architecture_absorption(
            project["project_id"],
            statuses,
            entry_class,
            architecture_status,
        ),
        "runtime_load_class": _stage3_runtime_load_class(entry_class),
        "implemented": integrated is not None,
        "ready": False,
        "local_ready": bool(integrated and integrated["local_ready"]),
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
        "can_execute_after_provider_config": bool(
            integrated and integrated.get("can_execute_after_provider_config")
        ),
        "p1_gate_impact": "none_not_p1_blocker",
        "post_v4_target": project["post_v4_target"],
        "ui_visibility": (
            integrated["ui_visibility"]
            if integrated
            else "visible_boundary_only"
        ),
        "implementation_boundary": (
            integrated["boundary"]
            if integrated
            else _implementation_boundary(project, statuses)
        ),
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
    if "planned_adapter" in statuses and "optional_runtime_adapter" not in statuses:
        reasons.append("planned_adapter_not_implemented")
    if "optional_runtime_adapter" in statuses:
        reasons.append("optional_runtime_dependency_missing")
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


def _stage3_registry_entry_class(project_id: str, statuses: list[str]) -> str:
    status_set = set(statuses)
    if project_id in {
        "andrej_karpathy_skills",
        "skill_prompt_generator",
        "mmskills",
        "mattpocock_skills",
        "ai_marketing_skills",
        "seedance2_skill",
    }:
        return "template_asset"
    if project_id == "llamaindex":
        return "architecture_reference"
    if "benchmark_only" in status_set and project_id not in {"ragas", "deepeval", "rtk"}:
        return "architecture_reference"
    return "capability_provider"


def _stage3_architecture_reference_status(
    project_id: str,
    statuses: list[str],
    entry_class: str,
) -> str:
    if entry_class in {"capability_provider", "template_asset"}:
        return "absorbed_into_architecture"
    if project_id == "llamaindex":
        return "absorbed_into_architecture"
    if "future_adapter" in statuses:
        return "deferred_with_blocker"
    return "rejected_no_architecture_gain"


def _stage3_architecture_absorption(
    project_id: str,
    statuses: list[str],
    entry_class: str,
    architecture_status: str,
) -> dict[str, Any]:
    worth_absorbing = architecture_status in {
        "absorbed_into_architecture",
        "deferred_with_blocker",
    }
    return {
        "decision_source": "stage3_provider_registry_classification_gate",
        "legacy_contract_status": statuses,
        "worth_absorbing": worth_absorbing,
        "absorption_required_now": architecture_status == "absorbed_into_architecture",
        "learning_note_only": False,
        "indefinite_reference_allowed": False,
        "absorbed_targets": (
            ARCHITECTURE_REFERENCE_ABSORB_TARGETS
            if architecture_status == "absorbed_into_architecture"
            else []
        ),
        "parallel_architecture_delivery": (
            {
                "provider_ref": project_id,
                "provider_classification": entry_class,
                "contract": True,
                "schema": True,
                "runtime_boundary": True,
                "ui_information_architecture": True,
                "test_gate": True,
                "audit_model": True,
                "fallback_strategy": True,
                "provider_loading_rule": True,
            }
            if architecture_status == "absorbed_into_architecture"
            else {}
        ),
        "blocker": (
            "requires verified runtime proof before architecture absorption"
            if architecture_status == "deferred_with_blocker"
            else ""
        ),
        "rejection_reason": (
            "no additional v3 architecture gain over existing Provider abstractions"
            if architecture_status == "rejected_no_architecture_gain"
            else ""
        ),
        "architecture_delivery_required": architecture_status == "absorbed_into_architecture",
    }


def _stage3_runtime_load_class(entry_class: str) -> str:
    return {
        "capability_provider": "provider_capability_config_gated",
        "template_asset": "template_asset_manifest_only",
        "architecture_reference": "architecture_reference_no_runtime",
    }[entry_class]


def _future_reference_architecture_absorption(
    project_id: str,
    legacy_status: str,
    entry_class: str,
    architecture_status: str,
    blocker: str,
    rejection_reason: str,
) -> dict[str, Any]:
    absorption = _stage3_architecture_absorption(
        project_id,
        [legacy_status],
        entry_class,
        architecture_status,
    )
    if blocker:
        absorption["blocker"] = blocker
    if rejection_reason:
        absorption["rejection_reason"] = rejection_reason
    return absorption


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
        "This pass does not copy external code, bundle runtimes, call network APIs, or expose a UI Run action. "
        "Optional runtime adapters require explicit local dependency installation and backend selection."
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
                "stage3_current_classification": project["stage3_current_classification"],
                "architecture_reference_status": project["architecture_reference_status"],
                "runtime_load_class": project["runtime_load_class"],
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
            "external_features_implemented": registry_payload["release_boundary"]["external_features_implemented"],
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
        "anysearchskill_api_callable": True,
        "anysearchskill_real_smoke_passed": True,
        "n8n_workflow_export_ready": True,
        "weknora_embedded": False,
        "llm_wiki_memory_engine_implemented": False,
        "entries": provider_rows,
    }


def _provider_capability_status(projects: list[dict[str, Any]]) -> dict[str, Any]:
    project_by_id = {project["project_id"]: project for project in projects}
    capabilities = []
    for spec in PROVIDER_CAPABILITY_AREAS:
        related = [
            project_by_id[project_id]
            for project_id in spec["project_ids"]
            if project_id in project_by_id
        ]
        blocked_reasons = _unique(
            [reason for project in related for reason in project["blocked_reasons"]]
        )
        related_states = [_provider_project_state(project) for project in related]
        status = _provider_capability_state(related, blocked_reasons)
        ready_for_user_selection = status == "available"
        capabilities.append(
            {
                "capability_id": spec["capability_id"],
                "capability_area": spec["capability_area"],
                "user_visible_name": spec["user_visible_name"],
                "zh_user_visible_name": spec["zh_user_visible_name"],
                "provider_type": spec["provider_type"],
                "registry_entry_class_counts": _stage3_registry_counts(related),
                "architecture_reference_status_counts": _stage3_architecture_counts(related),
                "status": status,
                "ready_for_user_selection": ready_for_user_selection,
                "default_fallback": spec["fallback"],
                "requires_network": any(project["requires_network"] for project in related),
                "requires_secret": any(project["requires_api_key"] for project in related),
                "requires_external_runtime": any(project["requires_external_runtime"] for project in related),
                "requires_dependency_install": any(
                    "optional_runtime_dependency_missing" in project["blocked_reasons"]
                    or "planned_adapter_not_implemented" in project["blocked_reasons"]
                    for project in related
                ),
                "needs_verification": any(
                    "needs_verification" in project["blocked_reasons"]
                    or "needs_verification" in project["contract_status"]
                    for project in related
                ),
                "audit_event_required": True,
                "rollback_supported": True,
                "user_visible_behavior": _provider_user_behavior(status),
                "zh_user_visible_behavior": _provider_user_behavior(status, zh=True),
                "boundary": (
                    "User-facing capability status only. Registered project names and "
                    "external runtimes are not exposed as normal product modules."
                ),
                "related_provider_states": related_states,
            }
        )
    ready_count = sum(1 for entry in capabilities if entry["ready_for_user_selection"])
    registry_class_counts = _stage3_registry_counts(projects)
    architecture_status_counts = _stage3_architecture_counts(projects)
    return {
        "status_id": "provider_capability_status",
        "version": S_A_CONTRACT_INCLUSION_VERSION,
        "schema_version": "prd_v3_provider_capability_status.v2",
        "product_baseline_chain": "文档库 -> 知识库 -> 索引层 -> RAG -> 编排层 -> 文档/Skill/Agent/A2A",
        "scope": (
            "Maps registered capability evidence to product-facing Provider statuses. "
            "This does not load external projects, bundle external runtimes, or add top-level pages."
        ),
        "user_concept_boundary": {
            "external_project_names_visible_in_normal_ui": False,
            "hot_swap_project_concept_visible": False,
            "unverified_entries_marked_ready": False,
            "planned_adapters_marked_ready": False,
            "okf_runtime_added": False,
        },
        "capability_count": len(capabilities),
        "ready_for_user_selection_count": ready_count,
        "provider_network_api_ready": False,
        "stage3_classification_model": {
            "capability_provider": "Configurable/testable/auditable/rollbackable capability enhancement.",
            "template_asset": "Manifest-backed Skill/Agent/document template asset without runtime load.",
            "architecture_reference": "Reference that must be absorbed, rejected, or deferred with a blocker.",
        },
        "registry_entry_class_counts": registry_class_counts,
        "architecture_reference_status_counts": architecture_status_counts,
        "indefinite_reference_state_allowed": False,
        "legacy_reference_only_contracts_are_trace_only": True,
        "capabilities": capabilities,
    }


def _provider_project_state(project: dict[str, Any]) -> dict[str, Any]:
    return {
        "provider_ref": project["project_id"],
        "status": _provider_capability_state([project], project["blocked_reasons"]),
        "contract_status": project["contract_status"],
        "stage3_current_classification": project["stage3_current_classification"],
        "registry_entry_class": project["registry_entry_class"],
        "architecture_reference_status": project["architecture_reference_status"],
        "architecture_absorption": project["architecture_absorption"],
        "runtime_load_class": project["runtime_load_class"],
        "requires_network": project["requires_network"],
        "requires_secret": project["requires_api_key"],
        "requires_external_runtime": project["requires_external_runtime"],
        "ready_for_user_selection": False,
        "audit_event_required": True,
        "rollback_supported": True,
    }


def _stage3_registry_counts(projects: list[dict[str, Any]]) -> dict[str, int]:
    counts = {
        "capability_provider": 0,
        "template_asset": 0,
        "architecture_reference": 0,
    }
    for project in projects:
        entry_class = project["registry_entry_class"]
        counts[entry_class] = counts.get(entry_class, 0) + 1
    return counts


def _stage3_architecture_counts(projects: list[dict[str, Any]]) -> dict[str, int]:
    counts = {
        "candidate_reference": 0,
        "absorbed_into_architecture": 0,
        "rejected_no_architecture_gain": 0,
        "deferred_with_blocker": 0,
    }
    for project in projects:
        status = project["architecture_reference_status"]
        counts[status] = counts.get(status, 0) + 1
    return counts


def _provider_capability_state(projects: list[dict[str, Any]], blocked_reasons: list[str]) -> str:
    if not projects:
        return "needs_provider_config"
    if "needs_verification" in blocked_reasons:
        return "needs_verification"
    if any(
        "planned_adapter" in project["contract_status"]
        or "future_adapter" in project["contract_status"]
        for project in projects
    ):
        return "dependency_gated"
    if any(project["requires_external_runtime"] for project in projects):
        return "external_runtime_required"
    if any(project["requires_api_key"] for project in projects):
        return "needs_secret_config"
    if any(project["requires_network"] for project in projects):
        return "needs_network_authorization"
    if any(project["local_ready"] for project in projects):
        return "configured_not_tested"
    return "needs_provider_config"


def _provider_user_behavior(status: str, *, zh: bool = False) -> str:
    zh_labels = {
        "available": "可选择并可审计",
        "configured_not_tested": "已有本地能力参考，启用前需测试",
        "dependency_gated": "需要安装或完成适配后启用",
        "external_runtime_required": "需要用户自有运行时",
        "needs_secret_config": "需要安全配置密钥",
        "needs_network_authorization": "需要网络授权与验证",
        "needs_verification": "需要完成登记核验",
        "needs_provider_config": "需要 Provider 配置",
    }
    en_labels = {
        "available": "Selectable with audit trail",
        "configured_not_tested": "Local capability reference exists; test before enabling",
        "dependency_gated": "Requires dependency install or adapter completion",
        "external_runtime_required": "Requires a user-owned runtime",
        "needs_secret_config": "Requires secure secret configuration",
        "needs_network_authorization": "Requires network authorization and validation",
        "needs_verification": "Requires registry verification",
        "needs_provider_config": "Requires Provider configuration",
    }
    return (zh_labels if zh else en_labels).get(status, status)


def _compact_project(project: dict[str, Any]) -> dict[str, Any]:
    return {
        "project_id": project["project_id"],
        "project_name": project["project_name"],
        "rating": project["rating"],
        "github_url": project["github_url"],
        "contract_status": project["contract_status"],
        "stage3_current_classification": project["stage3_current_classification"],
        "architecture_reference_status": project["architecture_reference_status"],
        "runtime_load_class": project["runtime_load_class"],
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
        "This registry preserves contract boundaries while recording completed local capability-fusion, provider-adapter, and workflow-export work. It does not bundle external runtimes or expose UI execution.",
        "",
        "## Summary",
        "",
        f"- S projects: {payload['rating_counts']['S']}",
        f"- A projects: {payload['rating_counts']['A']}",
        f"- Internal capability anchors: {payload['internal_capability_anchor_count']}",
        "- Optional local parser/OCR runtime adapters: Docling, PaddleOCR, Unstructured",
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
    optional_runtime_adapter_count = sum(
        1
        for entry in payload["entries"]
        if entry["project_id"] in {"docling", "paddleocr", "unstructured"}
    )
    lines = [
        "# Planned Adapter Status Report",
        "",
        "- Ready count: 0",
        "- Implemented count: 0",
        "- Can execute locally before v4 count: 0",
        f"- Optional local runtime adapter count: {optional_runtime_adapter_count}",
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
        "- AnySearchSkill API callable: true",
        "- AnySearchSkill real smoke passed: true",
        "- n8n workflow export ready: true",
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


def _render_provider_capability_status_md(payload: dict[str, Any]) -> str:
    lines = [
        "# Provider Capability Status",
        "",
        "Product-facing Provider capability status. This report does not expose registered external projects as product modules and does not load external runtimes.",
        "",
        f"- Capability count: {payload['capability_count']}",
        f"- Ready for user selection: {payload['ready_for_user_selection_count']}",
        f"- Provider network API ready: {str(payload['provider_network_api_ready']).lower()}",
        f"- Indefinite reference state allowed: {str(payload['indefinite_reference_state_allowed']).lower()}",
        f"- Registry classes: {payload['registry_entry_class_counts']}",
        f"- Architecture reference statuses: {payload['architecture_reference_status_counts']}",
        "",
        "| Capability | Area | Status | User behavior | Ready |",
        "| --- | --- | --- | --- | --- |",
    ]
    lines.extend(
        "| {name} | {area} | {status} | {behavior} | {ready} |".format(
            name=entry["user_visible_name"],
            area=entry["capability_area"],
            status=entry["status"],
            behavior=entry["user_visible_behavior"],
            ready=str(entry["ready_for_user_selection"]).lower(),
        )
        for entry in payload["capabilities"]
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
