def render_curation_report(manifest: dict) -> str:
    return (
        "# Curated Package Report\n\n"
        f"- Source package: {manifest.get('source_package')}\n"
        f"- Curated chunks: {manifest.get('curated_chunk_count')}\n"
        f"- Decisions: {manifest.get('decision_count')}\n"
    )


def render_decision_audit(decisions: list[dict]) -> str:
    rows = "\n".join(f"- {item.get('item_id')}: {item.get('decision')} ({item.get('reason')})" for item in decisions)
    return "# Governance Decision Audit\n\n" + (rows or "- No decisions recorded.") + "\n"
