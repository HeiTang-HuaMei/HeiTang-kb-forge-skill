from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.governance.conflict_detector import detect_conflicts
from heitang_kb_forge.governance.lifecycle import make_lifecycle_manifest
from heitang_kb_forge.governance.package_diff import make_package_diff
from heitang_kb_forge.governance.review_queue import make_governance_review_queue
from heitang_kb_forge.governance.staleness import detect_staleness
from heitang_kb_forge.schemas.governance_schema import GovernanceReport


GOVERNANCE_OUTPUT_FILES = [
    "package_diff.json",
    "package_diff_report.md",
    "lifecycle_manifest.json",
    "lifecycle_report.md",
    "conflict_report.json",
    "conflict_report.md",
    "staleness_report.json",
    "staleness_report.md",
    "review_queue.jsonl",
    "review_queue_report.md",
    "governance_report.md",
]


def run_governance(package: Path, output: Path, old_package: Path | None = None, max_age_days: int = 180) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    diff = make_package_diff(package, old_package)
    staleness = detect_staleness(package, max_age_days)
    lifecycle = make_lifecycle_manifest(package, set(staleness.get("stale_chunk_ids", [])))
    conflicts = detect_conflicts(package)
    queue = make_governance_review_queue(package, conflicts, staleness)
    warnings = []
    if conflicts["status"] != "pass":
        warnings.append("conflict_detected")
    if staleness["status"] != "pass":
        warnings.append("stale_content")
    if queue:
        warnings.append("review_queue_not_empty")
    report = GovernanceReport(
        package=str(package).replace("\\", "/"),
        status="warning" if warnings else "pass",
        warnings=warnings,
        output_files=GOVERNANCE_OUTPUT_FILES,
    )
    write_json(output / "package_diff.json", diff.model_dump(mode="json"))
    (output / "package_diff_report.md").write_text(_diff_report(diff), encoding="utf-8")
    write_json(output / "lifecycle_manifest.json", lifecycle.model_dump(mode="json"))
    (output / "lifecycle_report.md").write_text(_lifecycle_report(lifecycle), encoding="utf-8")
    write_json(output / "conflict_report.json", conflicts)
    (output / "conflict_report.md").write_text(_simple_report("Conflict Report", conflicts), encoding="utf-8")
    write_json(output / "staleness_report.json", staleness)
    (output / "staleness_report.md").write_text(_simple_report("Staleness Report", staleness), encoding="utf-8")
    write_jsonl(output / "review_queue.jsonl", queue)
    (output / "review_queue_report.md").write_text(_queue_report(queue), encoding="utf-8")
    (output / "governance_report.md").write_text(_governance_report(report), encoding="utf-8")
    return report.model_dump(mode="json")


def _diff_report(diff) -> str:
    return f"""# Package Diff Report

- Added: {len(diff.added)}
- Removed: {len(diff.removed)}
- Changed: {len(diff.changed)}
- Unchanged: {len(diff.unchanged)}
"""


def _lifecycle_report(manifest) -> str:
    return f"""# Lifecycle Report

- Active chunks: {manifest.active_count}
- Review required: {manifest.review_required_count}
- Stale chunks: {manifest.stale_count}
"""


def _queue_report(queue: list[dict]) -> str:
    rows = "\n".join(f"| {item['review_id']} | {item['reason']} | {item['status']} |" for item in queue)
    if not rows:
        rows = "| - | - | - |"
    return f"""# Review Queue Report

| Review ID | Reason | Status |
| --- | --- | --- |
{rows}
"""


def _simple_report(title: str, payload: dict) -> str:
    status = payload.get("status", "pass")
    count = payload.get("conflict_count", len(payload.get("stale_chunk_ids", [])))
    return f"# {title}\n\n- Status: {status}\n- Count: {count}\n"


def _governance_report(report: GovernanceReport) -> str:
    warnings = "\n".join(f"- {warning}" for warning in report.warnings) or "- None"
    return f"""# Knowledge Governance Report

- Status: {report.status}
- Package: {report.package}

## Warnings

{warnings}
"""
