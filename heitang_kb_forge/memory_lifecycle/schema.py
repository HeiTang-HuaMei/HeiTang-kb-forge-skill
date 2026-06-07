from __future__ import annotations


MEMORY_CLASSES = [
    "session_log",
    "short_term_memory",
    "summary_memory",
    "long_term_memory",
    "memory_candidates",
    "memory_index",
    "retention_policy",
    "compaction_policy",
    "token_budget_policy",
]


def build_memory_lifecycle_schema() -> dict:
    return {
        "memory_lifecycle_version": "3.9.0-alpha.1",
        "status": "contract_ready",
        "agent_runtime_memory_implemented": False,
        "memory_classes": [
            {"name": "session_log", "injectable_by_default": False, "purpose": "raw local session transcript reference"},
            {"name": "short_term_memory", "injectable_by_default": True, "purpose": "recent bounded working notes"},
            {"name": "summary_memory", "injectable_by_default": True, "purpose": "compacted summaries"},
            {"name": "long_term_memory", "injectable_by_default": True, "purpose": "reviewed persistent facts or preferences"},
            {"name": "memory_candidates", "injectable_by_default": False, "purpose": "promotion queue records"},
            {"name": "memory_index", "injectable_by_default": False, "purpose": "lookup references, not raw context"},
            {"name": "retention_policy", "injectable_by_default": False, "purpose": "lifecycle rules"},
            {"name": "compaction_policy", "injectable_by_default": False, "purpose": "summary and pruning rules"},
            {"name": "token_budget_policy", "injectable_by_default": False, "purpose": "future context injection limits"},
        ],
        "private_memory_default": True,
        "workflow_shared_memory": "explicit_only",
        "selective_parent_writeback": "candidate_queue_only",
        "tests_require_real_llm_api_network": False,
    }
