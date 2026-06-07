from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json


V38_EXTERNAL_ABSORPTION_OUTPUT_FILES = ["v38_external_absorption_map.json"]

_CAPABILITIES = [
    ("multi_query_recall", ["LangChain", "LlamaIndex", "Haystack"], "multi-query retrieval and RAG fusion"),
    ("candidate_merge_dedup", ["LangChain", "LlamaIndex"], "retrieval fan-out merge and dedup"),
    ("deterministic_rerank", ["Haystack", "LlamaIndex"], "local ranker and rerank stage"),
    ("evidence_selection", ["LlamaIndex", "Haystack", "RAGAS"], "context/evidence precision pattern"),
    ("retrieval_failure_diagnostics", ["Haystack", "TruLens"], "component trace and diagnostic reports"),
    ("explainable_refusal_support", ["RAGAS", "TruLens"], "grounding and context sufficiency evaluation"),
    ("golden_query_evaluation", ["RAGAS", "TruLens"], "metric-driven RAG eval fixtures"),
    ("claim_extraction", ["FActScore"], "atomic factual claim extraction pattern"),
    ("local_verification_retrieval", ["FEVER", "FActScore"], "claim-to-evidence verification retrieval"),
    ("source_cross_check", ["FEVER", "RAGAS"], "support/refute/not-enough-evidence labels"),
    ("contradiction_detection", ["FEVER"], "refutation and contradiction labeling"),
    ("freshness_verification", ["TruLens", "RAGAS"], "metadata-aware evaluation pattern"),
    ("knowledge_accuracy_scoring", ["RAGAS", "TruLens", "FActScore"], "grounding and factual support scoring"),
    ("verification_retrieval_trace", ["Haystack", "TruLens"], "traceable pipeline/evaluation records"),
]


def build_v38_external_absorption_map() -> dict:
    return {
        "v38_external_absorption_map_version": "3.8.0-alpha.1",
        "source_reports": [
            "external_project_benchmark_report.json",
            "capability_gap_map.json",
            "external_fusion_plan.json",
            "architecture_gap_audit_report.json",
        ],
        "no_copy_policy": {
            "external_code_copied": False,
            "external_prompts_copied": False,
            "external_datasets_copied": False,
            "network_required_for_tests": False,
            "real_llm_api_required_for_tests": False,
        },
        "capabilities": [_record(capability, references, pattern) for capability, references, pattern in _CAPABILITIES],
    }


def write_v38_external_absorption_map(output: Path) -> dict:
    payload = build_v38_external_absorption_map()
    write_json(output / "v38_external_absorption_map.json", payload)
    return payload


def _record(capability: str, references: list[str], pattern: str) -> dict:
    return {
        "capability": capability,
        "benchmark_references": references,
        "external_project_or_pattern": pattern,
        "decision": "inspire",
        "reason": "Use audited architecture patterns only; keep HeiTang implementation local, deterministic, dependency-light, and no-network.",
        "what_to_absorb": _what_to_absorb(capability),
        "what_not_to_copy": [
            "external code",
            "external prompts",
            "external datasets",
            "provider-specific runtime dependencies",
            "network-required evaluation behavior",
        ],
        "local_deterministic_implementation": _local_path(capability),
        "optional_llm_assist_path": "reserved_for_future_summary_or_review_only_not_called_in_v3_8",
        "offline_fallback": "Use local package records, checked-in fixtures, deterministic lexical scoring, and user-provided verification sources.",
        "tests_require_real_llm_api_network": False,
        "implementation_files": _implementation_files(capability),
        "tests": _tests(capability),
        "reports_or_traces": _reports(capability),
        "contract_impact": capability in {"deterministic_rerank", "evidence_selection", "claim_extraction", "knowledge_accuracy_scoring", "verification_retrieval_trace"},
        "ui_impact": False,
        "risk_level": _risk(capability),
        "completion_status": "implemented",
    }


def _what_to_absorb(capability: str) -> list[str]:
    return {
        "multi_query_recall": ["bounded query fan-out", "per-variant recall trace"],
        "candidate_merge_dedup": ["stable evidence identity", "merge trace"],
        "deterministic_rerank": ["separate rerank stage", "scored ranking explanation"],
        "evidence_selection": ["selected/rejected evidence reasons", "coverage scoring"],
        "retrieval_failure_diagnostics": ["failure taxonomy", "operator-readable diagnostics"],
        "explainable_refusal_support": ["context sufficiency signal", "downstream refusal recommendation"],
        "golden_query_evaluation": ["fixture-backed recall/refusal evaluation"],
        "claim_extraction": ["atomic/simple claim records", "claim IDs"],
        "local_verification_retrieval": ["claim-to-local-evidence matching"],
        "source_cross_check": ["agreement/partial/contradiction/missing evidence states"],
        "contradiction_detection": ["deterministic refutation labels"],
        "freshness_verification": ["metadata-aware freshness status"],
        "knowledge_accuracy_scoring": ["uncertainty-aware support score"],
        "verification_retrieval_trace": ["auditable verification pipeline trace"],
    }[capability]


def _local_path(capability: str) -> str:
    return {
        "multi_query_recall": "Consume v3.7 retrieval_plan query_variants/subqueries and recall over local retrieval index.",
        "candidate_merge_dedup": "Deduplicate candidates by source_path, chunk_id, and retrieval_id.",
        "deterministic_rerank": "Score lexical overlap, query coverage, source diversity, trust boost, risk/freshness penalty, and stable tie-breaks.",
        "evidence_selection": "Select top evidence with citation readiness, source diversity, coverage, and rejection reasons.",
        "retrieval_failure_diagnostics": "Classify local retrieval failures without answer generation.",
        "explainable_refusal_support": "Emit should_refuse, refusal_reason, missing_evidence, suggested_user_action, and supporting_trace.",
        "golden_query_evaluation": "Evaluate checked-in local golden query fixtures.",
        "claim_extraction": "Extract simple claims from chunks/cards with local sentence rules.",
        "local_verification_retrieval": "Match claims against package records or user-provided local verification files.",
        "source_cross_check": "Compare claim tokens/numbers/negation against local verification evidence.",
        "contradiction_detection": "Detect negation, numeric, date, status, and mutually exclusive fact mismatches.",
        "freshness_verification": "Use date metadata or explicit dates; report unknown when missing.",
        "knowledge_accuracy_scoring": "Combine evidence coverage, agreement, contradiction risk, freshness, and uncertainty penalty.",
        "verification_retrieval_trace": "Record claim extraction, source loading, cross-check, contradiction, freshness, and scoring steps.",
    }[capability]


def _implementation_files(capability: str) -> list[str]:
    mapping = {
        "multi_query_recall": ["heitang_kb_forge/retrieval/quality.py"],
        "candidate_merge_dedup": ["heitang_kb_forge/retrieval/quality.py"],
        "deterministic_rerank": ["heitang_kb_forge/retrieval/rerank.py"],
        "evidence_selection": ["heitang_kb_forge/retrieval/evidence_selection.py"],
        "retrieval_failure_diagnostics": ["heitang_kb_forge/retrieval/diagnostics.py"],
        "explainable_refusal_support": ["heitang_kb_forge/retrieval/diagnostics.py", "heitang_kb_forge/retrieval/evidence_selection.py"],
        "golden_query_evaluation": ["heitang_kb_forge/retrieval/eval.py", "examples/golden_queries"],
        "claim_extraction": ["heitang_kb_forge/verification/claim_extractor.py"],
        "local_verification_retrieval": ["heitang_kb_forge/verification/source_cross_check.py"],
        "source_cross_check": ["heitang_kb_forge/verification/source_cross_check.py"],
        "contradiction_detection": ["heitang_kb_forge/verification/contradiction.py"],
        "freshness_verification": ["heitang_kb_forge/verification/freshness.py"],
        "knowledge_accuracy_scoring": ["heitang_kb_forge/verification/scoring.py"],
        "verification_retrieval_trace": ["heitang_kb_forge/verification/reporter.py"],
    }
    return mapping[capability]


def _tests(capability: str) -> list[str]:
    mapping = {
        "multi_query_recall": ["tests/test_v38_multi_query_recall.py"],
        "candidate_merge_dedup": ["tests/test_v38_multi_query_recall.py"],
        "deterministic_rerank": ["tests/test_v38_rerank.py"],
        "evidence_selection": ["tests/test_v38_evidence_selection.py"],
        "retrieval_failure_diagnostics": ["tests/test_v38_retrieval_diagnostics.py"],
        "explainable_refusal_support": ["tests/test_v38_retrieval_diagnostics.py"],
        "golden_query_evaluation": ["tests/test_v38_golden_query_eval.py"],
        "claim_extraction": ["tests/test_v38_claim_verification.py"],
        "local_verification_retrieval": ["tests/test_v38_claim_verification.py"],
        "source_cross_check": ["tests/test_v38_source_cross_check.py"],
        "contradiction_detection": ["tests/test_v38_contradiction_detection.py"],
        "freshness_verification": ["tests/test_v38_knowledge_accuracy.py"],
        "knowledge_accuracy_scoring": ["tests/test_v38_knowledge_accuracy.py"],
        "verification_retrieval_trace": ["tests/test_v38_claim_verification.py"],
    }
    return mapping[capability]


def _reports(capability: str) -> list[str]:
    mapping = {
        "multi_query_recall": ["multi_query_recall_trace.json"],
        "candidate_merge_dedup": ["multi_query_recall_trace.json"],
        "deterministic_rerank": ["rerank_report.json"],
        "evidence_selection": ["evidence_selection_trace.json"],
        "retrieval_failure_diagnostics": ["retrieval_failure_report.json"],
        "explainable_refusal_support": ["retrieval_failure_report.json", "retrieval_quality_report.json"],
        "golden_query_evaluation": ["golden_query_eval_report.json"],
        "claim_extraction": ["claim_verification_report.json"],
        "local_verification_retrieval": ["verification_retrieval_trace.json"],
        "source_cross_check": ["source_cross_check_report.json"],
        "contradiction_detection": ["contradiction_map.json"],
        "freshness_verification": ["freshness_check_report.json"],
        "knowledge_accuracy_scoring": ["knowledge_accuracy_report.json"],
        "verification_retrieval_trace": ["verification_retrieval_trace.json"],
    }
    return mapping[capability]


def _risk(capability: str) -> str:
    p0 = {
        "multi_query_recall",
        "deterministic_rerank",
        "claim_extraction",
        "local_verification_retrieval",
        "source_cross_check",
        "contradiction_detection",
        "knowledge_accuracy_scoring",
        "verification_retrieval_trace",
    }
    return "P0" if capability in p0 else "P1"
