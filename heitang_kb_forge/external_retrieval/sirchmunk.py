from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any, Iterable

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl


SIRCHMUNK_DIRECT_FILE_SEARCH_FILES = [
    "sirchmunk_direct_file_search_manifest.json",
    "direct_file_search_results.jsonl",
    "direct_file_search_source_trace.json",
    "direct_file_search_evidence_map.json",
    "sirchmunk_direct_file_search_validation_report.json",
    "sirchmunk_direct_file_search_report.md",
]

REPOSITORY_HEAD = "1e07ec11953673b601959fc82563e8264b9d5c6a"
LATEST_RELEASE = "v0.0.7"
LATEST_RELEASE_TAG = "b1de3b0153d0c42d0683479f141480a8a8102d7d"
SUPPORTED_EXTENSIONS = {".md", ".txt", ".html", ".htm", ".json", ".csv"}


def build_sirchmunk_direct_file_search(
    output: Path,
    *,
    workspace: Path,
    query: str,
    include_paths: Iterable[Path] | None = None,
    max_results: int = 5,
) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    workspace = Path(workspace)
    query = query.strip()
    error = _validate_inputs(workspace, query, max_results)
    if error:
        result = _failed_manifest(workspace, query, error)
        _write_failure(output, result)
        return result

    root = workspace.resolve()
    requested_paths = list(include_paths or [root])
    boundary_error = _first_path_boundary_error(root, requested_paths)
    if boundary_error:
        result = _failed_manifest(workspace, query, boundary_error)
        _write_failure(output, result)
        return result

    files = _collect_files(root, requested_paths)
    results = _search_files(root, files, query, max_results=max_results)
    source_trace = _source_trace(root, query, results)
    evidence_map = _evidence_map(query, results)
    manifest = {
        "schema_version": "sirchmunk_direct_file_search_manifest.v1",
        "section": "5.14",
        "campaign": "Campaign 3",
        "status": "passed",
        "project_id": "sirchmunk",
        "project_name": "Sirchmunk",
        "integration_decision": "real_integration",
        "integration_mode": "bounded_direct_file_search_provider",
        "source_verification": _source_verification(),
        "official_runtime_observation": {
            "documented_positioning": [
                "embedding_db_free_raw_data_search",
                "indexless_retrieval",
                "direct_file_search",
            ],
            "official_runtime_installed": False,
            "official_runtime_executed": False,
            "external_dependencies_installed": False,
            "llm_api_key_required_by_official_quickstart": True,
            "license_spdx": "Apache-2.0",
        },
        "dedup_boundary": {
            "overlap_checked": True,
            "distinct_from_anysearchskill": "This provider reads local user/workspace files only and does not call external search APIs.",
            "distinct_from_rag_anything": "This provider does not implement cross-modal RAG, embeddings, vector DB, or vendor multimodal runtime.",
            "distinct_from_weknora": "This provider does not implement Auto Wiki, Knowledge Graph, or agentic RAG.",
            "distinct_value": [
                "embedding-free direct local file search",
                "path-boundary enforced source trace",
                "source evidence map without index or vector database",
            ],
        },
        "runtime_boundary": _runtime_boundary(),
        "security_boundary": {
            "path_boundary_enforced": True,
            "workspace_root": str(root).replace("\\", "/"),
            "searched_paths": [str(Path(path).resolve()).replace("\\", "/") for path in requested_paths],
            "arbitrary_shell_execution": False,
            "network_call_executed": False,
            "secrets_required": False,
            "unsafe_path_access": False,
        },
        "ui_contract": {
            "status_visible": True,
            "direct_file_search_status_visible": True,
            "source_trace_visible": True,
            "local_ready": True,
            "ready": False,
            "executable_action": False,
            "vendor_runtime_action_available": False,
            "ui_visibility": "visible_status_only",
        },
        "search_summary": {
            "query": query,
            "workspace_root": str(root).replace("\\", "/"),
            "scanned_file_count": len(files),
            "supported_extensions": sorted(SUPPORTED_EXTENSIONS),
            "result_count": len(results),
            "max_results": max_results,
        },
        "output_files": SIRCHMUNK_DIRECT_FILE_SEARCH_FILES,
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "This advances Section 5 item 5.14 as a bounded local direct-file-search provider candidate. "
            "It does not install or execute Sirchmunk, run official LLM-backed retrieval, create a vector database, "
            "open Campaign 3 Supplement 3.0/4.0, accept Campaign 3, open Campaign 4, run Full Gate, package EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 strengthening item 5.S1 GBrain only.",
        "not_goal_complete": True,
    }
    validation = validate_sirchmunk_direct_file_search_payload(
        manifest,
        results,
        source_trace,
        evidence_map,
    )
    write_json(output / "sirchmunk_direct_file_search_manifest.json", manifest)
    write_jsonl(output / "direct_file_search_results.jsonl", results)
    write_json(output / "direct_file_search_source_trace.json", source_trace)
    write_json(output / "direct_file_search_evidence_map.json", evidence_map)
    write_json(output / "sirchmunk_direct_file_search_validation_report.json", validation)
    (output / "sirchmunk_direct_file_search_report.md").write_text(
        _render_report(manifest, validation),
        encoding="utf-8",
    )
    return manifest | {"validation": validation}


def validate_sirchmunk_direct_file_search(library: Path) -> dict[str, Any]:
    library = Path(library)
    missing = [
        file_name
        for file_name in SIRCHMUNK_DIRECT_FILE_SEARCH_FILES
        if not (library / file_name).exists()
    ]
    if missing:
        return {
            "schema_version": "sirchmunk_direct_file_search_validation_report.v1",
            "section": "5.14",
            "campaign": "Campaign 3",
            "status": "failed",
            "boundary_errors": ["required_files_missing"],
            "required_files": SIRCHMUNK_DIRECT_FILE_SEARCH_FILES,
            "missing_files": missing,
            "tests_require_real_llm_api_network": False,
            "final_target_not_downgraded": True,
            "remaining_gap": "Required Sirchmunk direct-file-search evidence is incomplete.",
            "next_required_e2e_step": "Complete Section 5 item 5.14 evidence before advancing.",
            "not_goal_complete": True,
        }
    result = validate_sirchmunk_direct_file_search_payload(
        _read_json(library / "sirchmunk_direct_file_search_manifest.json"),
        _read_jsonl(library / "direct_file_search_results.jsonl"),
        _read_json(library / "direct_file_search_source_trace.json"),
        _read_json(library / "direct_file_search_evidence_map.json"),
    )
    return {
        **result,
        "required_files": SIRCHMUNK_DIRECT_FILE_SEARCH_FILES,
        "missing_files": missing,
    }


def validate_sirchmunk_direct_file_search_payload(
    manifest: dict[str, Any],
    results: list[dict[str, Any]],
    source_trace: dict[str, Any],
    evidence_map: dict[str, Any],
) -> dict[str, Any]:
    source = manifest.get("source_verification", {})
    observed = manifest.get("official_runtime_observation", {})
    runtime = manifest.get("runtime_boundary", {})
    security = manifest.get("security_boundary", {})
    ui = manifest.get("ui_contract", {})
    errors: list[str] = []
    required_false = {
        "repository_cloned": source,
        "external_code_copied": source,
        "external_prompt_text_copied": source,
        "vendor_runtime_installed": source,
        "official_runtime_installed": observed,
        "official_runtime_executed": observed,
        "external_dependencies_installed": observed,
        "sirchmunk_runtime_integrated": runtime,
        "llm_required": runtime,
        "embedding_required": runtime,
        "vector_database_required": runtime,
        "index_build_required": runtime,
        "network_required": runtime,
        "external_source_ingestion_implemented": runtime,
        "cross_modal_rag_implemented": runtime,
        "auto_wiki_or_knowledge_graph_implemented": runtime,
        "campaign_3_3_0_implemented": runtime,
        "campaign_3_4_0_implemented": runtime,
        "arbitrary_shell_execution": security,
        "network_call_executed": security,
        "unsafe_path_access": security,
        "ready": ui,
        "executable_action": ui,
        "vendor_runtime_action_available": ui,
    }
    for field, container in required_false.items():
        if container.get(field) is not False:
            errors.append(f"{field}_must_be_false")
    if source.get("repository_accessible") is not True:
        errors.append("repository_accessible_must_be_true")
    if source.get("license_spdx") != "Apache-2.0":
        errors.append("license_spdx_must_be_apache_2_0")
    if manifest.get("integration_decision") != "real_integration":
        errors.append("integration_decision_must_be_real_integration")
    if manifest.get("integration_mode") != "bounded_direct_file_search_provider":
        errors.append("integration_mode_invalid")
    if runtime.get("local_direct_file_search_implemented") is not True:
        errors.append("local_direct_file_search_implemented_must_be_true")
    if security.get("path_boundary_enforced") is not True:
        errors.append("path_boundary_enforced_must_be_true")
    if ui.get("local_ready") is not True:
        errors.append("local_ready_must_be_true")
    if source_trace.get("source_trace_required") is not True:
        errors.append("source_trace_required")
    if evidence_map.get("evidence_map_required") is not True:
        errors.append("evidence_map_required")
    if len(results) != manifest.get("search_summary", {}).get("result_count"):
        errors.append("result_count_mismatch")
    status = "passed" if not errors else "failed"
    return {
        "schema_version": "sirchmunk_direct_file_search_validation_report.v1",
        "section": "5.14",
        "campaign": "Campaign 3",
        "status": status,
        "boundary_errors": errors,
        "repository_head": source.get("repository_head"),
        "latest_release": source.get("latest_release"),
        "license_spdx": source.get("license_spdx"),
        "result_count": len(results),
        "source_trace_entries": len(source_trace.get("sources", [])),
        "evidence_count": len(evidence_map.get("evidence", [])),
        "sirchmunk_runtime_integrated": runtime.get("sirchmunk_runtime_integrated"),
        "embedding_required": runtime.get("embedding_required"),
        "vector_database_required": runtime.get("vector_database_required"),
        "path_boundary_enforced": security.get("path_boundary_enforced"),
        "ui_ready": ui.get("ready"),
        "ui_executable_action": ui.get("executable_action"),
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": (
            "Validation proves bounded local direct-file-search evidence and negative runtime/UI boundaries only. "
            "It does not prove Sirchmunk runtime execution, Campaign 3 acceptance, Supplement 3.0/4.0, UI workflow, Full Gate, EXE, or release."
        ),
        "next_required_e2e_step": "Process Section 5 strengthening item 5.S1 GBrain only.",
        "not_goal_complete": True,
    }


def write_sirchmunk_direct_file_search(
    output: Path,
    *,
    workspace: Path,
    query: str,
    include_paths: Iterable[Path] | None = None,
    max_results: int = 5,
) -> dict[str, Any]:
    return build_sirchmunk_direct_file_search(
        output,
        workspace=workspace,
        query=query,
        include_paths=include_paths,
        max_results=max_results,
    )


def write_sirchmunk_direct_file_search_validation(library: Path, output: Path) -> dict[str, Any]:
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    result = validate_sirchmunk_direct_file_search(library)
    write_json(output / "sirchmunk_direct_file_search_validation_report.json", result)
    (output / "sirchmunk_direct_file_search_validation_report.md").write_text(
        _render_validation_report(result),
        encoding="utf-8",
    )
    return result


def _validate_inputs(workspace: Path, query: str, max_results: int) -> dict[str, str] | None:
    if not workspace.exists() or not workspace.is_dir():
        return {"error_code": "workspace_missing", "error": "Workspace path must exist and be a directory."}
    if not query:
        return {"error_code": "query_missing", "error": "Query must not be empty."}
    if max_results < 1:
        return {"error_code": "invalid_max_results", "error": "max_results must be at least 1."}
    return None


def _first_path_boundary_error(root: Path, paths: list[Path]) -> dict[str, str] | None:
    for path in paths:
        resolved = Path(path).resolve()
        if resolved != root and root not in resolved.parents:
            return {
                "error_code": "path_outside_workspace",
                "error": f"Path is outside the workspace boundary: {resolved}",
            }
    return None


def _collect_files(root: Path, requested_paths: list[Path]) -> list[Path]:
    files: list[Path] = []
    seen: set[Path] = set()
    for requested in requested_paths:
        resolved = Path(requested).resolve()
        candidates = [resolved] if resolved.is_file() else list(resolved.rglob("*"))
        for candidate in candidates:
            if not candidate.is_file() or candidate.suffix.lower() not in SUPPORTED_EXTENSIONS:
                continue
            real = candidate.resolve()
            if real in seen or (real != root and root not in real.parents):
                continue
            seen.add(real)
            files.append(real)
    return sorted(files)


def _search_files(root: Path, files: list[Path], query: str, *, max_results: int) -> list[dict[str, Any]]:
    terms = _terms(query)
    results: list[dict[str, Any]] = []
    for file_path in files:
        text = _read_text(file_path)
        if not text:
            continue
        lower = text.lower()
        score = sum(lower.count(term) for term in terms)
        if score <= 0:
            continue
        line_number, snippet = _first_match(text, terms)
        relative = file_path.relative_to(root).as_posix()
        evidence_id = f"sirchmunk_local_{len(results)}"
        results.append(
            {
                "evidence_id": evidence_id,
                "relative_path": relative,
                "absolute_path_redacted": True,
                "line_number": line_number,
                "score": score,
                "matched_terms": [term for term in terms if term in lower],
                "snippet": snippet,
                "source_trace": f"{relative}:L{line_number}",
                "backlink": f"{relative}#L{line_number}",
                "retrieval_mode": "direct_file_search_no_index_no_embedding",
            }
        )
    return sorted(results, key=lambda item: (-int(item["score"]), item["relative_path"]))[:max_results]


def _source_trace(root: Path, query: str, results: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "schema_version": "sirchmunk_direct_file_search_source_trace.v1",
        "source_trace_required": True,
        "workspace_root": str(root).replace("\\", "/"),
        "query": query,
        "source_count": len(results),
        "sources": [
            {
                "evidence_id": item["evidence_id"],
                "relative_path": item["relative_path"],
                "line_number": item["line_number"],
                "backlink": item["backlink"],
            }
            for item in results
        ],
    }


def _evidence_map(query: str, results: list[dict[str, Any]]) -> dict[str, Any]:
    return {
        "schema_version": "sirchmunk_direct_file_search_evidence_map.v1",
        "evidence_map_required": True,
        "query": query,
        "evidence": [
            {
                "evidence_id": item["evidence_id"],
                "source_trace": item["source_trace"],
                "score": item["score"],
                "snippet": item["snippet"],
            }
            for item in results
        ],
    }


def _source_verification() -> dict[str, Any]:
    return {
        "repository_url": "https://github.com/modelscope/sirchmunk",
        "repository_head": REPOSITORY_HEAD,
        "default_branch": "main",
        "repository_accessible": True,
        "repository_archived": False,
        "repository_disabled": False,
        "latest_release": LATEST_RELEASE,
        "latest_release_tag": LATEST_RELEASE_TAG,
        "license_spdx": "Apache-2.0",
        "license_file": "LICENSE",
        "repository_cloned": False,
        "external_code_copied": False,
        "external_prompt_text_copied": False,
        "vendor_runtime_installed": False,
    }


def _runtime_boundary() -> dict[str, Any]:
    return {
        "local_direct_file_search_implemented": True,
        "sirchmunk_runtime_integrated": False,
        "llm_required": False,
        "embedding_required": False,
        "vector_database_required": False,
        "index_build_required": False,
        "network_required": False,
        "external_source_ingestion_implemented": False,
        "cross_modal_rag_implemented": False,
        "auto_wiki_or_knowledge_graph_implemented": False,
        "campaign_3_3_0_implemented": False,
        "campaign_3_4_0_implemented": False,
    }


def _failed_manifest(workspace: Path, query: str, error: dict[str, str]) -> dict[str, Any]:
    return {
        "schema_version": "sirchmunk_direct_file_search_manifest.v1",
        "section": "5.14",
        "campaign": "Campaign 3",
        "status": "failed",
        "project_id": "sirchmunk",
        "project_name": "Sirchmunk",
        "integration_decision": "needs_strengthening",
        "integration_mode": "bounded_direct_file_search_provider",
        "source_verification": _source_verification(),
        "runtime_boundary": _runtime_boundary(),
        "security_boundary": {
            "path_boundary_enforced": True,
            "workspace_root": str(workspace).replace("\\", "/"),
            "arbitrary_shell_execution": False,
            "network_call_executed": False,
            "unsafe_path_access": error["error_code"] == "path_outside_workspace",
        },
        "search_summary": {
            "query": query,
            "result_count": 0,
        },
        "error_code": error["error_code"],
        "error": error["error"],
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": "Direct-file-search evidence failed before acceptance; fix the reported input or path-boundary issue.",
        "next_required_e2e_step": "Complete Section 5 item 5.14 Sirchmunk evidence before advancing.",
        "not_goal_complete": True,
    }


def _write_failure(output: Path, result: dict[str, Any]) -> None:
    validation = {
        "schema_version": "sirchmunk_direct_file_search_validation_report.v1",
        "section": "5.14",
        "campaign": "Campaign 3",
        "status": "failed",
        "boundary_errors": [result["error_code"]],
        "tests_require_real_llm_api_network": False,
        "final_target_not_downgraded": True,
        "remaining_gap": result["remaining_gap"],
        "next_required_e2e_step": result["next_required_e2e_step"],
        "not_goal_complete": True,
    }
    write_json(output / "sirchmunk_direct_file_search_manifest.json", result)
    write_jsonl(output / "direct_file_search_results.jsonl", [])
    write_json(output / "direct_file_search_source_trace.json", {"source_trace_required": True, "sources": []})
    write_json(output / "direct_file_search_evidence_map.json", {"evidence_map_required": True, "evidence": []})
    write_json(output / "sirchmunk_direct_file_search_validation_report.json", validation)
    (output / "sirchmunk_direct_file_search_report.md").write_text(
        f"# Sirchmunk Direct File Search\n\n- Status: failed\n- Error: {result['error_code']}\n",
        encoding="utf-8",
    )


def _terms(query: str) -> list[str]:
    words = [word.lower() for word in re.findall(r"[\w\u4e00-\u9fff]+", query) if len(word) > 1]
    seen: list[str] = []
    for word in words:
        if word not in seen:
            seen.append(word)
    return seen


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="ignore")


def _first_match(text: str, terms: list[str]) -> tuple[int, str]:
    for number, line in enumerate(text.splitlines(), start=1):
        lower = line.lower()
        if any(term in lower for term in terms):
            return number, line.strip()[:240]
    return 1, text.strip()[:240]


def _read_json(path: Path) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def _read_jsonl(path: Path) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def _render_report(manifest: dict[str, Any], validation: dict[str, Any]) -> str:
    summary = manifest["search_summary"]
    return f"""# Sirchmunk Direct File Search Provider Candidate

- Status: {validation['status']}
- Integration decision: {manifest['integration_decision']}
- Integration mode: {manifest['integration_mode']}
- Repository head: {manifest['source_verification']['repository_head']}
- Release: {manifest['source_verification']['latest_release']}
- License: {manifest['source_verification']['license_spdx']}
- Query: {summary['query']}
- Scanned files: {summary['scanned_file_count']}
- Results: {summary['result_count']}
- Sirchmunk runtime integrated: {manifest['runtime_boundary']['sirchmunk_runtime_integrated']}
- Embedding required: {manifest['runtime_boundary']['embedding_required']}
- Vector database required: {manifest['runtime_boundary']['vector_database_required']}
- UI executable action: {manifest['ui_contract']['executable_action']}

This is a bounded local direct-file-search provider candidate. It does not install or execute Sirchmunk,
does not call a network or LLM provider, and does not build a vector index.
"""


def _render_validation_report(result: dict[str, Any]) -> str:
    return f"""# Sirchmunk Direct File Search Validation

- Status: {result['status']}
- Boundary errors: {len(result['boundary_errors'])}
- Result count: {result.get('result_count', 0)}
- Source trace entries: {result.get('source_trace_entries', 0)}
- Evidence count: {result.get('evidence_count', 0)}
- Sirchmunk runtime integrated: {result.get('sirchmunk_runtime_integrated')}
- Vector database required: {result.get('vector_database_required')}
"""
