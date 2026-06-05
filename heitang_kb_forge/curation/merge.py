def accepted_decision(decision: dict) -> bool:
    return decision.get("decision", "accept") in {"accept", "fix", "active"}
