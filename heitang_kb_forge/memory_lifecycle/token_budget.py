from __future__ import annotations


def build_token_budget_policy(max_items: int = 20, max_estimated_tokens: int = 4000) -> dict:
    return {
        "token_budget_policy_version": "3.9.0-alpha.1",
        "max_context_memory_items": max_items,
        "max_estimated_context_tokens": max_estimated_tokens,
        "prevent_all_history_injection": True,
        "default_injection_order": ["summary_memory", "long_term_memory", "memory_index_references", "short_term_memory"],
        "excluded_by_default": ["session_log", "memory_candidates", "retention_policy", "compaction_policy"],
        "class_limits": {
            "summary_memory": {"max_items": min(8, max_items), "max_estimated_tokens": max_estimated_tokens // 2},
            "long_term_memory": {"max_items": min(8, max_items), "max_estimated_tokens": max_estimated_tokens // 3},
            "short_term_memory": {"max_items": min(4, max_items), "max_estimated_tokens": max_estimated_tokens // 4},
            "session_log": {"max_items": 0, "max_estimated_tokens": 0},
        },
        "optional_llm_assist_path": "reserved_for_future_memory_summary_review_only",
        "tests_require_real_llm_api_network": False,
    }


def estimate_memory_token_budget(memory_items: list[str], max_items: int = 20, max_estimated_tokens: int = 4000) -> dict:
    selected = []
    estimated_tokens = 0
    for item in memory_items[:max_items]:
        tokens = max(1, len(item) // 4)
        if estimated_tokens + tokens > max_estimated_tokens:
            break
        selected.append({"text": item, "estimated_tokens": tokens})
        estimated_tokens += tokens
    return {
        "selected_count": len(selected),
        "estimated_tokens": estimated_tokens,
        "max_items": max_items,
        "max_estimated_tokens": max_estimated_tokens,
        "all_history_injected": False,
        "selected": selected,
    }
