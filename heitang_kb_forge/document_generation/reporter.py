from __future__ import annotations

from pathlib import Path

from heitang_kb_forge.document_generation.planner import DocumentPlan


def generated_file_report(files: dict[str, Path]) -> dict:
    return {
        "generated_file_report_version": "3.0.0-alpha.1",
        "files": [
            {"format": fmt, "path": str(path), "bytes": path.stat().st_size if path.exists() else 0}
            for fmt, path in sorted(files.items())
        ],
    }


def render_generated_file_report(report: dict) -> str:
    rows = "\n".join(
        f"- {item['format']}: `{item['path']}` ({item['bytes']} bytes)"
        for item in report["files"]
    ) or "- None"
    return f"""# Generated File Report

## Files

{rows}
"""


def generation_trace(plan: DocumentPlan, files: dict[str, Path], validation: dict) -> dict:
    return {
        "document_generation_trace_version": "3.0.0-alpha.1",
        "source_package": str(plan.package),
        "selected_chunks": [
            {"chunk_id": evidence.chunk_id, "source_path": evidence.source_path, "citation": evidence.citation}
            for evidence in plan.evidence
        ],
        "selected_assets": [
            {"card_id": card.get("card_id"), "chunk_id": card.get("chunk_id"), "title": card.get("title")}
            for card in plan.cards[:8]
        ],
        "template": plan.template,
        "grounding_policy": plan.grounding_policy,
        "generated_files": {fmt: str(path) for fmt, path in sorted(files.items())},
        "validation_status": validation["status"],
        "trust_status": plan.trust_status,
        "review_required": plan.review_required,
        "warnings": plan.warnings,
    }


def quality_report(plan: DocumentPlan, markdown: str, validation: dict) -> dict:
    return {
        "document_quality_report_version": "3.0.0-alpha.1",
        "status": "pass" if validation["status"] == "pass" and plan.evidence else "fail",
        "template": plan.template,
        "grounding_policy": plan.grounding_policy,
        "citation_count": markdown.count("[E"),
        "evidence_count": len(plan.evidence),
        "source_appendix": "present" if "## Source Evidence Appendix" in markdown else "missing",
        "review_required": plan.review_required,
        "warnings": plan.warnings,
    }


def render_export_validation_report(report: dict) -> str:
    rows = "\n".join(
        f"- {fmt}: {item['status']} (`{item['path']}`)"
        for fmt, item in sorted(report["files"].items())
    ) or "- None"
    warnings = "\n".join(f"- {warning}" for warning in report.get("warnings", [])) or "- None"
    return f"""# Export Validation Report

## Summary

- Status: {report['status']}

## Files

{rows}

## Warnings

{warnings}
"""
