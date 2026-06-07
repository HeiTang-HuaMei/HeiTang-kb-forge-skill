from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json


V39_EXTERNAL_ABSORPTION_OUTPUT_FILES = ["v39_external_absorption_map.json"]

_CAPABILITIES = [
    ("local_workspace_registry", ["LiteDoc local-first pattern", "Docling structured conversion"], "absorb", "workspace asset manifest and local-only boundary"),
    ("package_registry", ["Docling", "HeiTang v3.6 storage audit"], "absorb", "typed package asset registry"),
    ("skill_registry", ["andrej-karpathy-skills", "last30days-skill"], "inspire", "skill package index pattern"),
    ("agent_registry", ["rtk", "agentmemory"], "inspire", "agent asset registry and runtime-reserved state separation"),
    ("memory_registry", ["rohitg00/agentmemory"], "inspire", "memory class registry and indexing concepts"),
    ("document_registry", ["LiteDoc", "Docling", "Marker"], "absorb", "document conversion outputs as tracked assets"),
    ("index_registry", ["Haystack", "LlamaIndex"], "inspire", "index metadata and rebuildable cache contract"),
    ("storage_usage_report", ["LiteDoc token/privacy positioning", "HeiTang v3.6 audit"], "absorb", "local storage and size visibility"),
    ("content_hash_dedup", ["local-first package registry pattern"], "absorb", "content hash identity and duplicate recommendation"),
    ("cleanup_plan", ["local workspace lifecycle pattern"], "absorb", "recommendation-only cleanup plan"),
    ("retention_policy", ["agentmemory", "local lifecycle governance pattern"], "inspire", "retention classes without SaaS policy"),
    ("archive_plan", ["local workspace lifecycle pattern"], "absorb", "non-destructive archive recommendations"),
    ("memory_lifecycle", ["rohitg00/agentmemory"], "inspire", "session/short/summary/long/candidate/index classes"),
    ("memory_compaction_plan", ["rohitg00/agentmemory", "context compression pattern"], "inspire", "deterministic compaction plan and future summary route"),
    ("token_budget_policy", ["agentmemory", "context compression pattern"], "absorb", "bounded memory injection rules"),
    ("local_pdf_to_markdown_preprocessing", ["LiteDoc"], "inspire", "local PDF-to-Markdown privacy and token reduction path"),
    ("parser_backend_selection", ["PaddleOCR", "MinerU", "Marker", "Docling"], "inspire", "deterministic backend routing policy"),
    ("parser_backend_benchmark", ["PaddleOCR", "MinerU", "Marker", "Docling"], "inspire", "fixture-based parser backend comparison"),
    ("pdf_token_reduction_report", ["LiteDoc"], "absorb", "estimate raw PDF vs markdown token waste"),
    ("no_cloud_upload_guarantee", ["LiteDoc"], "absorb", "explicit local-only no-upload guarantee"),
]


def build_v39_external_absorption_map() -> dict:
    return {
        "v39_external_absorption_map_version": "3.9.0-alpha.1",
        "source_reports": [
            "external_project_benchmark_report.json",
            "capability_gap_map.json",
            "external_fusion_plan.json",
            "architecture_gap_audit_report.json",
            "v38_external_absorption_map.json",
        ],
        "no_copy_policy": {
            "external_code_copied": False,
            "external_prompts_copied": False,
            "heavy_dependencies_required": False,
            "network_required_for_tests": False,
            "real_llm_api_required_for_tests": False,
        },
        "capabilities": [_record(*item) for item in _CAPABILITIES],
    }


def write_v39_external_absorption_map(output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    payload = build_v39_external_absorption_map()
    write_json(output / "v39_external_absorption_map.json", payload)
    return payload


def _record(capability: str, references: list[str], decision: str, pattern: str) -> dict:
    return {
        "capability": capability,
        "benchmark_references": references,
        "decision": decision,
        "reason": "Absorb audited local-first patterns only; keep implementation deterministic, dependency-light, and no-network.",
        "what_to_absorb": [pattern],
        "what_not_to_copy": [
            "external code",
            "external prompts",
            "mandatory heavy parser dependencies",
            "cloud upload behavior",
            "platform-hosted user data",
        ],
        "local_deterministic_implementation": _local_path(capability),
        "optional_llm_assist_path": "reserved_for_future_summary_or_review_only_not_called_in_v3_9",
        "offline_fallback": "Use local file scans, deterministic hash/size/token heuristics, and review_required states.",
        "tests_require_real_llm_api_network": False,
        "implementation_files": _implementation_files(capability),
        "tests": _tests(capability),
        "reports_or_traces": _reports(capability),
        "contract_impact": capability in {"local_workspace_registry", "storage_usage_report", "memory_lifecycle", "token_budget_policy", "parser_backend_benchmark", "pdf_token_reduction_report", "no_cloud_upload_guarantee"},
        "ui_impact": False,
        "risk_level": "P0" if capability in {"local_workspace_registry", "memory_lifecycle", "token_budget_policy", "no_cloud_upload_guarantee"} else "P1",
        "completion_status": "implemented",
    }


def _local_path(capability: str) -> str:
    return {
        "local_workspace_registry": "Scan local workspace root and write typed JSON registries without moving assets.",
        "package_registry": "Register package artifacts with size, hash, status, and source refs.",
        "skill_registry": "Register skill package artifacts when present.",
        "agent_registry": "Register agent package artifacts when present.",
        "memory_registry": "Register memory lifecycle and candidate/index artifacts.",
        "document_registry": "Register generated documents and parser reports.",
        "index_registry": "Register local index artifacts as rebuildable local assets.",
        "storage_usage_report": "Compute file counts and bytes by asset type.",
        "content_hash_dedup": "Group duplicate assets by SHA-256 and recommend review only.",
        "cleanup_plan": "Generate non-destructive cleanup recommendations.",
        "retention_policy": "Emit retention policy report for local asset classes.",
        "archive_plan": "Emit recommendation-only archive targets.",
        "memory_lifecycle": "Define memory classes and local lifecycle reports without runtime DB.",
        "memory_compaction_plan": "Emit deterministic compaction plan and future summary path.",
        "token_budget_policy": "Bound future memory context injection and block all-history injection.",
        "local_pdf_to_markdown_preprocessing": "Run lightweight local PDF text scan or mark review_required.",
        "parser_backend_selection": "Route text/scanned/complex/unknown documents by deterministic policy.",
        "parser_backend_benchmark": "Benchmark local fixtures without mandatory parser dependencies.",
        "pdf_token_reduction_report": "Estimate raw PDF token waste versus Markdown text.",
        "no_cloud_upload_guarantee": "Emit explicit no-upload/no-LLM/no-network report.",
    }[capability]


def _implementation_files(capability: str) -> list[str]:
    if capability.startswith("memory_") or capability == "token_budget_policy":
        return ["heitang_kb_forge/memory_lifecycle/"]
    if capability.startswith("parser_") or capability.startswith("pdf_") or capability.startswith("local_pdf") or capability == "no_cloud_upload_guarantee":
        return ["heitang_kb_forge/document_parsing/"]
    return ["heitang_kb_forge/workspace_storage/"]


def _tests(capability: str) -> list[str]:
    if capability.startswith("memory_") or capability == "token_budget_policy":
        return ["tests/test_v39_memory_lifecycle.py", "tests/test_v39_token_budget.py"]
    if capability.startswith("parser_") or capability.startswith("pdf_") or capability.startswith("local_pdf") or capability == "no_cloud_upload_guarantee":
        return ["tests/test_v39_local_pdf_markdown.py", "tests/test_v39_parser_backend_benchmark.py", "tests/test_v39_pdf_token_reduction.py", "tests/test_v39_no_cloud_upload.py"]
    return ["tests/test_v39_workspace_registry.py", "tests/test_v39_storage_report.py", "tests/test_v39_dedup_cleanup.py"]


def _reports(capability: str) -> list[str]:
    if capability.startswith("memory_"):
        return ["memory_lifecycle_report.json", "memory_compaction_plan.json", "memory_index_contract.json"]
    if capability == "token_budget_policy":
        return ["token_budget_policy.json"]
    if capability.startswith("parser_"):
        return ["parser_backend_selection_report.json", "parser_backend_benchmark_report.json"]
    if capability.startswith("pdf_"):
        return ["pdf_token_reduction_report.json"]
    if capability.startswith("local_pdf"):
        return ["local_pdf_markdown_report.json"]
    if capability == "no_cloud_upload_guarantee":
        return ["no_cloud_upload_report.json"]
    return ["workspace_registry.json", "storage_usage_report.json", "cleanup_plan.json", "dedup_report.json"]
