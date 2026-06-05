def score_gates(gates: dict[str, str]) -> int:
    score = 100
    score -= sum(20 for status in gates.values() if status == "fail")
    score -= sum(8 for status in gates.values() if status == "warning")
    score -= sum(3 for status in gates.values() if status in {"not_found", "not_enabled"})
    return max(0, min(100, score))

