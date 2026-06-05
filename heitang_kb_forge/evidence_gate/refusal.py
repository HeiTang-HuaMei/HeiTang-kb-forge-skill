def refusal_reason(boundary: str, evidence: list[dict]) -> str:
    if boundary == "outside":
        return "The query is outside the package evidence boundary."
    if not evidence:
        return "No supporting evidence was found in the package."
    if all(item.get("review_required") for item in evidence):
        return "Only review-required evidence was found."
    return "Evidence is insufficient."
