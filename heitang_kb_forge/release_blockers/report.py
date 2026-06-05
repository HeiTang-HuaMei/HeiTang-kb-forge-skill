from heitang_kb_forge.schemas.release_blocker_schema import ReleaseBlockerResult


def render_release_blockers_report(result: ReleaseBlockerResult) -> str:
    rows = "\n".join(
        f"| {item.blocker_type} | {item.severity} | {item.message} | {item.path or '-'} |"
        for item in result.blockers
    ) or "| - | - | None | - |"
    return f"""# Release Blockers Report

- Status: {result.status}
- Release ready: {result.release_ready}
- Blockers: {result.blocker_count}
- Critical blockers: {result.critical_count}

| Type | Severity | Message | Path |
| --- | --- | --- | --- |
{rows}
"""

