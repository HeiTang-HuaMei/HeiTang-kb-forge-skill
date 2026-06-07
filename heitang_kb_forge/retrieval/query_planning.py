from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.retrieval.query_router import route_query


QUERY_PLANNING_VERSION = "3.7.0-alpha.1"
QUERY_PLANNING_OUTPUT_FILES = [
    "query_rewrite_report.json",
    "query_rewrite_trace.json",
    "retrieval_plan.json",
    "retrieval_plan_report.md",
]
QUERY_REWRITE_EVAL_OUTPUT_FILES = ["query_rewrite_eval_report.json"]
VALID_RETRIEVAL_PURPOSES = {"answering", "validation"}
DEFAULT_QUERY = "Summarize this knowledge package."

_VAGUE_QUERIES = {"summary", "summarize", "overview", "explain", "help", "what", "tell me", "介绍", "总结", "概述", "说明"}
_STOPWORDS = {
    "and",
    "or",
    "the",
    "a",
    "an",
    "of",
    "to",
    "in",
    "for",
    "about",
    "what",
    "how",
    "is",
    "are",
    "this",
    "that",
    "from",
    "with",
}
_DOMAIN_TERMS = {
    "finance": ["revenue", "pricing", "cost", "margin", "forecast"],
    "product": ["feature", "benefit", "user", "workflow", "comparison"],
    "legal": ["policy", "risk", "requirement", "compliance", "evidence"],
    "general": ["evidence", "source", "summary", "definition", "process"],
}


def normalize_query(query: str) -> str:
    text = str(query or "").strip()
    text = re.sub(r"\s+", " ", text)
    text = re.sub(r"\s+([,.;:!?，。！？；：])", r"\1", text)
    text = re.sub(r"([,.;:!?])(?=[^\s,.;:!?])", r"\1 ", text)
    return text.strip()


def rewrite_query(query: str, conversation_context: str | None = None) -> dict:
    normalized = normalize_query(query)
    context = normalize_query(conversation_context or "")
    if not normalized:
        rewritten = DEFAULT_QUERY
        reason = "empty_query_default"
    elif _is_follow_up(normalized) and context:
        rewritten = f"{context}; follow-up question: {normalized}"
        reason = "explicit_context_follow_up_resolution"
    elif _is_follow_up(normalized):
        rewritten = normalized
        reason = "no_explicit_context_follow_up"
    elif _is_vague(normalized):
        rewritten = f"Summarize relevant evidence about {normalized} from the knowledge package."
        reason = "vague_query_grounded_summary"
    else:
        rewritten = normalized
        reason = "query_already_specific"
    return {
        "query_rewrite_version": QUERY_PLANNING_VERSION,
        "original_query": str(query or ""),
        "normalized_query": normalized,
        "rewritten_query": rewritten,
        "rewrite_reason": reason,
        "conversation_context_used": bool(context and reason == "explicit_context_follow_up_resolution"),
        "deterministic": True,
        "llm_used": False,
        "tests_require_real_llm_api_network": False,
    }


def expand_query(query: str, domain: str = "general") -> list[str]:
    normalized = normalize_query(query)
    terms = _keywords(normalized)
    expanded: list[str] = []
    for term in terms:
        expanded.append(term)
        expanded.extend(_term_expansions(term))
    expanded.extend(_DOMAIN_TERMS.get(domain, []))
    if domain != "general":
        expanded.extend(_DOMAIN_TERMS["general"][:2])
    return _dedupe(expanded)[:24]


def decompose_query(query: str) -> list[dict]:
    normalized = normalize_query(query)
    if not normalized:
        return []
    normalized = re.sub(r"^(?:compare|difference between)\s+", "", normalized, flags=re.IGNORECASE)
    pattern = r"\s+(?:and|vs|versus|compare|difference between)\s+|[;；]|(?:并且|以及|对比|比较)"
    parts = [part.strip(" ,，。.!?？") for part in re.split(pattern, normalized, flags=re.IGNORECASE) if part.strip(" ,，。.!?？")]
    if len(parts) <= 1:
        return []
    return [
        {
            "subquery_id": f"subquery_{index}",
            "query": part,
            "route": route_query(part),
            "reason": "compound_query_decomposition",
        }
        for index, part in enumerate(_dedupe(parts), start=1)
    ]


def generate_query_variants(
    query: str,
    *,
    domain: str = "general",
    conversation_context: str | None = None,
    max_rewrites: int = 5,
    generate_multi_queries: bool = True,
) -> list[str]:
    limit = max(1, int(max_rewrites or 1))
    rewrite = rewrite_query(query, conversation_context)
    candidates = [rewrite["rewritten_query"], rewrite["normalized_query"]]
    if generate_multi_queries:
        subqueries = [item["query"] for item in decompose_query(rewrite["rewritten_query"])]
        candidates.extend(subqueries)
        terms = expand_query(rewrite["rewritten_query"], domain)[:4]
        if terms:
            candidates.append(" ".join(terms[:3]))
        route = route_query(rewrite["rewritten_query"])
        candidates.append(f"{rewrite['rewritten_query']} evidence")
        if route == "comparison":
            candidates.append(f"compare {rewrite['rewritten_query']}")
        elif route == "process":
            candidates.append(f"steps for {rewrite['rewritten_query']}")
    return _dedupe([item for item in candidates if item])[:limit]


def build_retrieval_plan(
    query: str,
    *,
    package: Path | None = None,
    domain: str = "general",
    conversation_context: str | None = None,
    purpose: str = "answering",
    top_k: int = 5,
    citation_required: bool = True,
    max_rewrites: int = 5,
    generate_multi_queries: bool = True,
    allow_llm_rewrite: bool = False,
    filters: dict[str, Any] | None = None,
) -> dict:
    retrieval_purpose = _validate_purpose(purpose)
    rewrite = rewrite_query(query, conversation_context)
    rewritten_query = rewrite["rewritten_query"]
    expanded_terms = expand_query(rewritten_query, domain)
    subqueries = decompose_query(rewritten_query)
    query_variants = generate_query_variants(
        rewritten_query,
        domain=domain,
        max_rewrites=max_rewrites,
        generate_multi_queries=generate_multi_queries,
    )
    route = route_query(rewritten_query)
    target_kbs = [str(package).replace("\\", "/")] if package is not None else []
    confidence_threshold = 2 if retrieval_purpose == "answering" else 1
    return {
        "retrieval_plan_version": QUERY_PLANNING_VERSION,
        "original_query": rewrite["original_query"],
        "normalized_query": rewrite["normalized_query"],
        "rewritten_query": rewritten_query,
        "rewrite_reason": rewrite["rewrite_reason"],
        "expanded_terms": expanded_terms,
        "subqueries": subqueries,
        "query_variants": query_variants,
        "fanout_policy": {
            "enabled": bool(generate_multi_queries),
            "max_query_variants": max(1, int(max_rewrites or 1)),
            "duplicate_removal": True,
            "strategy": "deterministic_local_hybrid",
        },
        "retrieval_purpose": retrieval_purpose,
        "target_kbs": target_kbs,
        "retrieval_mode": _retrieval_mode(retrieval_purpose, route),
        "top_k": int(top_k),
        "filters": filters or {},
        "citation_required": bool(citation_required),
        "refusal_policy": _refusal_policy(retrieval_purpose, citation_required),
        "confidence_threshold": confidence_threshold,
        "route_reason": f"{route}_route_for_{retrieval_purpose}",
        "deterministic_local_path": "normalize -> rewrite -> expand -> decompose -> generate_variants -> plan",
        "optional_llm_assist_path": "reserved_only" if allow_llm_rewrite else "disabled_by_config",
        "offline_fallback": "rule_based_query_planning_without_network_or_provider",
        "tests_require_real_llm_api_network": False,
        "llm_used": False,
    }


def write_query_planning_outputs(output: Path, plan: dict, eval_report: dict | None = None) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    report = _query_rewrite_report(plan)
    trace = _query_rewrite_trace(plan)
    write_json(output / "query_rewrite_report.json", report)
    write_json(output / "query_rewrite_trace.json", trace)
    write_json(output / "retrieval_plan.json", plan)
    (output / "retrieval_plan_report.md").write_text(render_retrieval_plan_report(plan), encoding="utf-8")
    files = list(QUERY_PLANNING_OUTPUT_FILES)
    if eval_report is not None:
        write_json(output / "query_rewrite_eval_report.json", eval_report)
        files.extend(QUERY_REWRITE_EVAL_OUTPUT_FILES)
    return {
        "query_planning_version": QUERY_PLANNING_VERSION,
        "status": "pass",
        "retrieval_purpose": plan["retrieval_purpose"],
        "query_variant_count": len(plan["query_variants"]),
        "subquery_count": len(plan["subqueries"]),
        "output_files": files,
    }


def evaluate_query_rewrite_cases(cases: list[dict], *, domain: str = "general", max_rewrites: int = 5) -> dict:
    rows = []
    for index, item in enumerate(cases, start=1):
        query = str(item.get("query", "")).strip()
        context = item.get("conversation_context")
        plan = build_retrieval_plan(query, domain=domain, conversation_context=context, max_rewrites=max_rewrites)
        expected_contains = str(item.get("expected_rewrite_contains", "")).strip()
        status = "pass" if not expected_contains or expected_contains.lower() in plan["rewritten_query"].lower() else "fail"
        rows.append(
            {
                "case_id": item.get("case_id") or f"case_{index}",
                "status": status,
                "query": query,
                "rewritten_query": plan["rewritten_query"],
                "rewrite_reason": plan["rewrite_reason"],
                "query_variant_count": len(plan["query_variants"]),
            }
        )
    return {
        "query_rewrite_eval_version": QUERY_PLANNING_VERSION,
        "status": "fail" if any(row["status"] == "fail" for row in rows) else "pass",
        "case_count": len(rows),
        "cases": rows,
        "tests_require_real_llm_api_network": False,
    }


def load_eval_cases(path: Path) -> list[dict]:
    if not path.exists():
        raise FileNotFoundError(f"Query rewrite eval cases not found: {path}")
    text = path.read_text(encoding="utf-8")
    if path.suffix.lower() == ".json":
        payload = json.loads(text)
        if isinstance(payload, list):
            return payload
        if isinstance(payload, dict) and isinstance(payload.get("cases"), list):
            return payload["cases"]
        raise ValueError("Query rewrite eval JSON must be a list or an object with cases")
    rows = [json.loads(line) for line in text.splitlines() if line.strip()]
    return rows


def render_retrieval_plan_report(plan: dict) -> str:
    variants = "\n".join(f"- {item}" for item in plan["query_variants"]) or "- None"
    subqueries = "\n".join(f"- {item['subquery_id']}: {item['query']}" for item in plan["subqueries"]) or "- None"
    return "\n".join(
        [
            "# Retrieval Plan Report",
            "",
            f"- Purpose: {plan['retrieval_purpose']}",
            f"- Original query: {plan['original_query']}",
            f"- Rewritten query: {plan['rewritten_query']}",
            f"- Rewrite reason: {plan['rewrite_reason']}",
            f"- Retrieval mode: {plan['retrieval_mode']}",
            f"- Top K: {plan['top_k']}",
            f"- Citation required: {str(plan['citation_required']).lower()}",
            f"- Tests require real LLM/API/network: {str(plan['tests_require_real_llm_api_network']).lower()}",
            "",
            "## Query Variants",
            "",
            variants,
            "",
            "## Subqueries",
            "",
            subqueries,
            "",
        ]
    )


def _query_rewrite_report(plan: dict) -> dict:
    return {
        "query_rewrite_report_version": QUERY_PLANNING_VERSION,
        "status": "pass",
        "original_query": plan["original_query"],
        "normalized_query": plan["normalized_query"],
        "rewritten_query": plan["rewritten_query"],
        "rewrite_reason": plan["rewrite_reason"],
        "expanded_term_count": len(plan["expanded_terms"]),
        "subquery_count": len(plan["subqueries"]),
        "query_variant_count": len(plan["query_variants"]),
        "retrieval_purpose": plan["retrieval_purpose"],
        "llm_used": plan["llm_used"],
        "tests_require_real_llm_api_network": False,
    }


def _query_rewrite_trace(plan: dict) -> dict:
    return {
        "query_rewrite_trace_version": QUERY_PLANNING_VERSION,
        "steps": [
            {"name": "normalize_query", "status": "pass", "value": plan["normalized_query"]},
            {"name": "rewrite_query", "status": "pass", "reason": plan["rewrite_reason"]},
            {"name": "expand_query", "status": "pass", "count": len(plan["expanded_terms"])},
            {"name": "decompose_query", "status": "pass", "count": len(plan["subqueries"])},
            {"name": "generate_query_variants", "status": "pass", "count": len(plan["query_variants"])},
            {"name": "build_retrieval_plan", "status": "pass", "purpose": plan["retrieval_purpose"]},
        ],
        "tests_require_real_llm_api_network": False,
    }


def _validate_purpose(purpose: str) -> str:
    normalized = normalize_query(purpose).lower()
    if normalized not in VALID_RETRIEVAL_PURPOSES:
        raise ValueError("retrieval purpose must be one of: answering, validation")
    return normalized


def _retrieval_mode(purpose: str, route: str) -> str:
    prefix = "validation" if purpose == "validation" else "answering"
    return f"{prefix}_{route}_local_retrieval"


def _refusal_policy(purpose: str, citation_required: bool) -> dict:
    if purpose == "validation":
        return {
            "mode": "validation_only",
            "external_retrieval": "not_implemented_in_v3_7",
            "claim_verification": "deferred_to_v3_8",
            "refuse_when": ["unsupported_validation_purpose", "insufficient_local_context"],
        }
    return {
        "mode": "answering",
        "citation_required": bool(citation_required),
        "refuse_when": ["no_retrieval_records", "low_confidence_retrieval", "missing_required_citation"],
    }


def _is_vague(query: str) -> bool:
    lowered = query.lower()
    tokens = _keywords(lowered)
    return lowered in _VAGUE_QUERIES or len(tokens) <= 1


def _is_follow_up(query: str) -> bool:
    lowered = query.lower()
    return lowered in {"what about this", "what about it", "and this", "follow up", "继续", "那这个呢"} or lowered.startswith(("what about ", "and "))


def _term_expansions(term: str) -> list[str]:
    expansions = {
        "price": ["pricing", "cost"],
        "pricing": ["price", "cost"],
        "revenue": ["income", "sales"],
        "risk": ["issue", "warning"],
        "compare": ["difference", "contrast"],
        "流程": ["步骤", "过程"],
        "价格": ["定价", "成本"],
    }
    return expansions.get(term.lower(), [])


def _keywords(value: str) -> list[str]:
    words = [word.lower() for word in re.findall(r"[\w\u4e00-\u9fff]+", value) if len(word) > 1]
    return [word for word in words if word not in _STOPWORDS]


def _dedupe(values: list[str]) -> list[str]:
    seen = set()
    result = []
    for value in values:
        normalized = normalize_query(value)
        key = normalized.lower()
        if normalized and key not in seen:
            seen.add(key)
            result.append(normalized)
    return result
