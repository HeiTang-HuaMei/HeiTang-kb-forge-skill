from __future__ import annotations

from datetime import datetime, timezone
import re


def check_freshness(claims: list[dict], sources: list[dict], *, stale_after_days: int = 365) -> dict:
    rows = []
    now = datetime.now(timezone.utc)
    for claim in claims:
        date_text = _date_from_claim_or_source(claim, sources)
        status = "unknown"
        age_days = None
        if date_text:
            parsed = _parse_date(date_text)
            if parsed:
                age_days = (now - parsed).days
                status = "stale" if age_days > stale_after_days else "fresh"
            else:
                status = "needs_review"
        rows.append(
            {
                "claim_id": claim["claim_id"],
                "claim_text": claim["claim_text"],
                "freshness_status": status,
                "source_date": date_text or "",
                "age_days": age_days,
            }
        )
    return {
        "freshness_check_version": "3.8.0-alpha.1",
        "status": "warning" if any(row["freshness_status"] in {"stale", "unknown", "needs_review"} for row in rows) else "pass",
        "items": rows,
        "summary": {
            "fresh": len([row for row in rows if row["freshness_status"] == "fresh"]),
            "stale": len([row for row in rows if row["freshness_status"] == "stale"]),
            "unknown": len([row for row in rows if row["freshness_status"] == "unknown"]),
            "needs_review": len([row for row in rows if row["freshness_status"] == "needs_review"]),
        },
        "tests_require_real_llm_api_network": False,
    }


def _date_from_claim_or_source(claim: dict, sources: list[dict]) -> str:
    metadata = claim.get("metadata", {}) if isinstance(claim.get("metadata"), dict) else {}
    if metadata.get("date"):
        return str(metadata["date"])
    match = re.search(r"\b20\d{2}(?:-\d{2}-\d{2})?\b", claim.get("claim_text", ""))
    if match:
        return match.group(0)
    source_path = claim.get("source_path", "")
    for source in sources:
        if source_path and source.get("source_path") == source_path and source.get("date"):
            return str(source["date"])
    return ""


def _parse_date(value: str) -> datetime | None:
    for fmt in ["%Y-%m-%d", "%Y"]:
        try:
            parsed = datetime.strptime(value, fmt)
            return parsed.replace(tzinfo=timezone.utc)
        except ValueError:
            continue
    return None
