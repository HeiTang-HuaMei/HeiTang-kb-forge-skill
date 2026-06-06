from __future__ import annotations

from heitang_kb_forge.parser_backends.base import ParserBackendRun


def render_backend_output_md(run: ParserBackendRun) -> str:
    sections = [
        "# Parser Backend Output",
        "",
        f"- Backend: {run.backend_name}",
        f"- Status: {run.status}",
        f"- Source count: {run.source_count}",
        f"- Trust status: {run.kb_trust_status}",
        "",
    ]
    for index, record in enumerate(run.records, start=1):
        sections.extend(
            [
                f"## Source {index}: {record.source_path}",
                "",
                f"- Status: {record.status}",
                f"- Confidence: {record.confidence}",
                "",
                record.text or "_No text extracted._",
                "",
            ]
        )
    return "\n".join(sections).rstrip() + "\n"


def render_parse_compare_report(result: dict) -> str:
    lines = [
        "# Parse Compare Report",
        "",
        f"- Status: {result['status']}",
        f"- Backends: {', '.join(result['backends'])}",
        f"- Compared sources: {result['source_count']}",
        "",
        "## Differences",
        "",
    ]
    if not result["differences"]:
        lines.append("- No backend text differences detected.")
    for item in result["differences"]:
        lines.append(f"- {item['source_path']}: {item['summary']}")
    lines.append("")
    return "\n".join(lines)


def render_parse_quality_report(report: dict) -> str:
    lines = [
        "# Parse Quality Gate",
        "",
        f"- Status: {report['status']}",
        f"- Trust status: {report['kb_trust_status']}",
        f"- Manual review required: {str(report['manual_review_required']).lower()}",
        f"- High risk chunks: {report['high_risk_chunk_count']}",
        f"- High risk pages: {report['high_risk_page_count']}",
        "",
    ]
    for warning in report.get("warnings", []):
        lines.append(f"- Warning: {warning}")
    return "\n".join(lines).rstrip() + "\n"

