from __future__ import annotations


def make_manual_review_queue(high_risk_pages: list[dict], high_risk_chunks: list[dict]) -> list[dict]:
    rows = []
    for index, item in enumerate(high_risk_pages + high_risk_chunks, start=1):
        rows.append(
            {
                "review_id": f"parse_review_{index}",
                "source_path": item.get("source_path", ""),
                "item_type": item.get("item_type", "parse_output"),
                "reason": item.get("reason", "manual_review_required"),
                "status": "pending",
                "recommended_action": "Review extracted text, correct OCR/parser errors, then re-import corrected text.",
            }
        )
    return rows

