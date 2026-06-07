from __future__ import annotations


def build_memory_compaction_plan(strategy: str = "deterministic_summary_placeholder") -> dict:
    return {
        "memory_compaction_plan_version": "3.9.0-alpha.1",
        "strategy": strategy,
        "agent_runtime_memory_implemented": False,
        "steps": [
            {"step": "collect_session_log", "source": "session_log", "output": "short_term_memory", "llm_required": False},
            {"step": "summarize_bounded_recent_memory", "source": "short_term_memory", "output": "summary_memory", "llm_required": False},
            {"step": "queue_promotion_candidates", "source": "summary_memory", "output": "memory_candidates", "llm_required": False},
            {"step": "index_approved_memory", "source": "long_term_memory", "output": "memory_index", "llm_required": False},
        ],
        "raw_session_log_injection_allowed": False,
        "destructive_action_taken": False,
        "offline_fallback": "Use deterministic truncation and summary placeholders until runtime memory is implemented.",
    }
