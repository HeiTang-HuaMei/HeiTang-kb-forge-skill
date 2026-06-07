from __future__ import annotations

import json
import re
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.retrieval.diagnostics import diagnose_retrieval_failure
from heitang_kb_forge.retrieval.eval import run_golden_query_eval
from heitang_kb_forge.retrieval.evidence_selection import select_evidence
from heitang_kb_forge.retrieval.external_absorption import write_v38_external_absorption_map
from heitang_kb_forge.retrieval.index_builder import build_retrieval_index
from heitang_kb_forge.retrieval.query_planning import build_retrieval_plan
from heitang_kb_forge.retrieval.rerank import build_rerank_report, rerank_candidates
from heitang_kb_forge.verification import VERIFICATION_OUTPUT_FILES, run_claim_verification


RETRIEVAL_QUALITY_VERSION = "3.8.0-alpha.1"
RETRIEVAL_QUALITY_OUTPUT_FILES = [
    "multi_query_recall_trace.json",
    "rerank_report.json",
    "evidence_selection_trace.json",
    "retrieval_failure_report.json",
    "retrieval_quality_report.json",
    "retrieval_quality_report.md",
    "golden_query_eval_report.json",
    "v38_external_absorption_map.json",
] + VERIFICATION_OUTPUT_FILES


def run_retrieval_quality(
    package: Path,
    output: Path,
    *,
    query: str = "Summarize this knowledge package.",
    retrieval_plan: dict | None = None,
    use_query_planning: bool = True,
    top_k: int = 5,
    max_candidates: int = 50,
    enable_rerank: bool = True,
    enable_evidence_selection: bool = True,
    enable_failure_diagnostics: bool = True,
    enable_claim_verification: bool = True,
    verification_sources: list[Path] | None = None,
    allow_external_network: bool = False,
    allow_llm_judge: bool = False,
) -> dict:
    if allow_external_network:
        raise ValueError("retrieval_quality.allow_external_network must remain false in v3.8")
    if allow_llm_judge:
        raise ValueError("retrieval_quality.allow_llm_judge must remain false in v3.8")
    output.mkdir(parents=True, exist_ok=True)
    plan = retrieval_plan or _load_plan(output) or _load_plan(package)
    if not plan or not use_query_planning:
        plan = build_retrieval_plan(query, package=package, top_k=top_k)
    query_text = plan.get("rewritten_query") or query
    purpose = plan.get("retrieval_purpose", "answering")
    records = [record.model_dump(mode="json") for record in build_retrieval_index(package)]
    recall_trace = multi_query_recall(records, plan, max_candidates=max_candidates)
    merged = recall_trace["merged_candidates"]
    ranked = rerank_candidates(merged, query_text, purpose=purpose) if enable_rerank else merged
    rerank_report = build_rerank_report(ranked, query=query_text, purpose=purpose)
    evidence = select_evidence(ranked, query_text, top_k=top_k) if enable_evidence_selection else _empty_evidence(query_text, top_k)
    failure = (
        diagnose_retrieval_failure(query=query_text, candidates=merged, ranked=ranked, evidence_selection=evidence, purpose=purpose)
        if enable_failure_diagnostics
        else _empty_failure(query_text, purpose)
    )
    golden = run_golden_query_eval(output, recall_trace, failure)
    verification_result = (
        run_claim_verification(package, output, verification_sources)
        if enable_claim_verification
        else {"status": "skipped", "output_files": []}
    )
    absorption_map = write_v38_external_absorption_map(output)
    quality = _quality_report(
        package=package,
        plan=plan,
        records=records,
        recall_trace=recall_trace,
        rerank_report=rerank_report,
        evidence=evidence,
        failure=failure,
        golden=golden,
        verification_result=verification_result,
        absorption_map=absorption_map,
    )
    write_json(output / "multi_query_recall_trace.json", recall_trace)
    write_json(output / "rerank_report.json", rerank_report)
    write_json(output / "evidence_selection_trace.json", evidence)
    write_json(output / "retrieval_failure_report.json", failure)
    write_json(output / "golden_query_eval_report.json", golden)
    write_json(output / "retrieval_quality_report.json", quality)
    (output / "retrieval_quality_report.md").write_text(render_retrieval_quality_report(quality), encoding="utf-8")
    return quality


def multi_query_recall(records: list[dict], plan: dict, *, max_candidates: int = 50) -> dict:
    variants = _plan_variants(plan)
    seen: set[str] = set()
    merged: list[dict] = []
    variant_traces = []
    for variant in variants:
        variant_results = _recall_variant(records, variant, max_candidates=max_candidates)
        trace_results = []
        for item in variant_results:
            identity = _identity(item)
            trace_results.append({"retrieval_id": item.get("retrieval_id", ""), "identity": identity, "score": item.get("recall_score", 0)})
            if identity in seen:
                continue
            seen.add(identity)
            merged.append(item)
            if len(merged) >= max_candidates:
                break
        variant_traces.append({"query_variant": variant, "result_count": len(variant_results), "results": trace_results})
        if len(merged) >= max_candidates:
            break
    return {
        "multi_query_recall_trace_version": RETRIEVAL_QUALITY_VERSION,
        "original_query": plan.get("original_query", ""),
        "rewritten_query": plan.get("rewritten_query", ""),
        "retrieval_purpose": plan.get("retrieval_purpose", "answering"),
        "variant_count": len(variants),
        "candidate_count": len(merged),
        "dedupe_key": "source_path|chunk_id|retrieval_id",
        "variant_traces": variant_traces,
        "merged_candidates": merged,
        "tests_require_real_llm_api_network": False,
    }


def render_retrieval_quality_report(report: dict) -> str:
    refusal = report["explainable_refusal"]
    return "\n".join(
        [
            "# Retrieval Quality Report",
            "",
            f"- Status: {report['status']}",
            f"- Retrieval purpose: {report['retrieval_purpose']}",
            f"- Planner consumed: {str(report['v37_retrieval_plan_consumed']).lower()}",
            f"- Candidate count: {report['candidate_count']}",
            f"- Selected evidence count: {report['selected_evidence_count']}",
            f"- Evidence coverage score: {report['evidence_coverage_score']}",
            f"- Should refuse: {str(refusal['should_refuse']).lower()}",
            f"- Refusal reason: {refusal['refusal_reason'] or '-'}",
            f"- Claim verification status: {report['claim_verification_status']}",
            f"- External Benchmark Absorption Map: {report['external_absorption_map_file']}",
            f"- No network: {str(not report['allow_external_network']).lower()}",
            f"- No real LLM/API required: {str(not report['tests_require_real_llm_api_network']).lower()}",
            "",
        ]
    )


def _plan_variants(plan: dict) -> list[str]:
    values = [
        plan.get("original_query", ""),
        plan.get("normalized_query", ""),
        plan.get("rewritten_query", ""),
    ]
    values.extend(plan.get("expanded_terms", [])[:6])
    values.extend(item.get("query", "") for item in plan.get("subqueries", []))
    values.extend(plan.get("query_variants", []))
    if plan.get("retrieval_purpose") == "validation":
        values.append(f"validate {plan.get('rewritten_query', '')}")
    return _dedupe([str(value) for value in values if str(value).strip()])


def _recall_variant(records: list[dict], variant: str, *, max_candidates: int) -> list[dict]:
    query_tokens = set(_tokens(variant))
    rows = []
    for index, record in enumerate(records):
        record_tokens = set(record.get("keywords") or _tokens(record.get("text", "")))
        overlap = len(query_tokens & record_tokens)
        if not overlap and query_tokens:
            continue
        item = dict(record)
        item["recall_query_variant"] = variant
        item["recall_score"] = overlap
        item["trusted_source"] = bool(record.get("citation"))
        item["metadata"] = record.get("metadata", {})
        rows.append((overlap, -index, item))
    rows.sort(key=lambda row: (-row[0], row[1], row[2].get("retrieval_id", "")))
    return [item for *_prefix, item in rows[:max_candidates]]


def _quality_report(
    *,
    package: Path,
    plan: dict,
    records: list[dict],
    recall_trace: dict,
    rerank_report: dict,
    evidence: dict,
    failure: dict,
    golden: dict,
    verification_result: dict,
    absorption_map: dict,
) -> dict:
    status = "warning" if failure.get("should_refuse") or evidence.get("insufficient_evidence") else "pass"
    accuracy = verification_result.get("accuracy", {}) if isinstance(verification_result, dict) else {}
    return {
        "retrieval_quality_report_version": RETRIEVAL_QUALITY_VERSION,
        "status": status,
        "package": str(package).replace("\\", "/"),
        "retrieval_purpose": plan.get("retrieval_purpose", "answering"),
        "v37_retrieval_plan_consumed": bool(plan.get("retrieval_plan_version")),
        "total_records": len(records),
        "candidate_count": recall_trace.get("candidate_count", 0),
        "query_variant_count": recall_trace.get("variant_count", 0),
        "selected_evidence_count": evidence.get("selected_count", 0),
        "evidence_coverage_score": evidence.get("evidence_coverage_score", 0),
        "source_diversity_count": evidence.get("source_diversity_count", 0),
        "rerank_status": rerank_report.get("status", "pass"),
        "retrieval_failure_status": failure.get("status", "pass"),
        "explainable_refusal": {
            "should_refuse": failure.get("should_refuse", False),
            "refusal_reason": failure.get("refusal_reason", ""),
            "missing_evidence": failure.get("missing_evidence", []),
            "suggested_user_action": failure.get("suggested_user_action", ""),
            "supporting_trace": failure.get("supporting_trace", {}),
        },
        "golden_query_eval_status": golden.get("status", "pass"),
        "claim_verification_status": verification_result.get("status", "skipped"),
        "knowledge_accuracy": accuracy,
        "external_absorption_map_file": "v38_external_absorption_map.json",
        "external_absorption_capability_count": len(absorption_map.get("capabilities", [])),
        "allow_external_network": False,
        "allow_llm_judge": False,
        "optional_llm_assist_path": "disabled_by_config",
        "offline_fallback": "local_index_recall_rerank_evidence_selection_and_local_claim_verification",
        "output_files": RETRIEVAL_QUALITY_OUTPUT_FILES,
        "tests_require_real_llm_api_network": False,
    }


def _load_plan(root: Path) -> dict | None:
    path = root / "retrieval_plan.json"
    if not path.exists():
        return None
    return json.loads(path.read_text(encoding="utf-8"))


def _empty_evidence(query: str, top_k: int) -> dict:
    return {
        "evidence_selection_version": RETRIEVAL_QUALITY_VERSION,
        "status": "skipped",
        "query": query,
        "top_k": top_k,
        "selected": [],
        "rejected": [],
        "selected_count": 0,
        "rejected_count": 0,
        "source_diversity_count": 0,
        "citation_ready": False,
        "evidence_coverage_score": 0.0,
        "insufficient_evidence": True,
        "refusal_recommendation": {"should_refuse": True, "refusal_reason": "evidence_selection_disabled", "missing_evidence": [], "suggested_user_action": "", "supporting_trace": []},
        "tests_require_real_llm_api_network": False,
    }


def _empty_failure(query: str, purpose: str) -> dict:
    return {
        "retrieval_failure_report_version": RETRIEVAL_QUALITY_VERSION,
        "status": "skipped",
        "query": query,
        "retrieval_purpose": purpose,
        "issues": [],
        "should_refuse": False,
        "refusal_reason": "",
        "missing_evidence": [],
        "suggested_user_action": "",
        "supporting_trace": {},
        "tests_require_real_llm_api_network": False,
    }


def _identity(item: dict) -> str:
    return "|".join([str(item.get("source_path", "")), str(item.get("chunk_id", "")), str(item.get("retrieval_id", ""))])


def _dedupe(values: list[str]) -> list[str]:
    seen = set()
    result = []
    for value in values:
        normalized = " ".join(value.split())
        key = normalized.lower()
        if normalized and key not in seen:
            seen.add(key)
            result.append(normalized)
    return result


def _tokens(value: str) -> list[str]:
    return [token.lower() for token in re.findall(r"[\w\u4e00-\u9fff]+", str(value)) if len(token) > 1]
