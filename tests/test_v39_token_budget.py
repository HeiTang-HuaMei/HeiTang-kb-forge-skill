from heitang_kb_forge.memory_lifecycle.token_budget import build_token_budget_policy, estimate_memory_token_budget


def test_token_budget_policy_prevents_all_history_injection():
    policy = build_token_budget_policy(max_items=3, max_estimated_tokens=20)
    assert policy["prevent_all_history_injection"] is True
    assert policy["class_limits"]["session_log"]["max_items"] == 0

    estimate = estimate_memory_token_budget(["a" * 20, "b" * 20, "c" * 20, "d" * 20], max_items=3, max_estimated_tokens=12)
    assert estimate["selected_count"] <= 3
    assert estimate["estimated_tokens"] <= 12
    assert estimate["all_history_injected"] is False
