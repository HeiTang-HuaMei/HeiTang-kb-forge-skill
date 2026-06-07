from __future__ import annotations

from heitang_kb_forge.document_generation.planner import DocumentPlan


def render_markdown(plan: DocumentPlan) -> str:
    sections = [
        f"# {plan.title}",
        "",
        "## Generation Boundary",
        "",
        f"- Template: `{plan.template}`",
        f"- Grounding policy: `{plan.grounding_policy}`",
        f"- Source package: `{plan.package}`",
        f"- Trust status: `{plan.trust_status}`",
        f"- Review required: `{str(plan.review_required).lower()}`",
        "",
        "## Summary",
        "",
    ]
    sections.extend(_summary_bullets(plan))
    sections.extend(["", "## Grounded Sections", ""])
    for evidence in plan.evidence:
        sections.extend(
            [
                f"### {evidence.title} [{evidence.evidence_id}]",
                "",
                f"{_excerpt(evidence.text, 520)} [{evidence.evidence_id}]",
                "",
                f"Source: `{evidence.citation}`",
                "",
            ]
        )
    if plan.warnings:
        sections.extend(["## Warnings", ""])
        sections.extend(f"- {warning}" for warning in plan.warnings)
        sections.append("")
    sections.extend(["## Source Evidence Appendix", ""])
    for evidence in plan.evidence:
        sections.extend(
            [
                f"### [{evidence.evidence_id}] {evidence.title}",
                "",
                f"- Source: `{evidence.source_path}`",
                f"- Chunk: `{evidence.chunk_id}`",
                f"- Citation: `{evidence.citation}`",
                "",
                _excerpt(evidence.text, 900),
                "",
            ]
        )
    return "\n".join(sections).rstrip() + "\n"


def _summary_bullets(plan: DocumentPlan) -> list[str]:
    if plan.cards:
        bullets = []
        for card in plan.cards[:5]:
            title = str(card.get("title") or "Untitled")
            summary = str(card.get("summary") or "")
            citation = str(card.get("citation") or "")
            suffix = f" `{citation}`" if citation else ""
            bullets.append(f"- {title}: {_excerpt(summary, 180)}{suffix}")
        return bullets
    return [f"- {evidence.title}: {_excerpt(evidence.text, 180)} [{evidence.evidence_id}]" for evidence in plan.evidence[:5]]


def _excerpt(text: str, limit: int) -> str:
    compact = " ".join(text.split())
    if len(compact) <= limit:
        return compact
    return compact[: limit - 3].rstrip() + "..."
