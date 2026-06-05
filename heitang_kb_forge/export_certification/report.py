from heitang_kb_forge.schemas.export_certification_schema import ExportCertificationResult


def render_export_certification_report(result: ExportCertificationResult) -> str:
    rows = "\n".join(
        f"| {item.platform} | {item.status} | {item.certified} | {', '.join(item.errors) or '-'} |"
        for item in result.platforms
    )
    return f"""# Platform Export Certification Report

- Status: {result.status}
- Certified: {result.certified}

| Platform | Status | Certified | Errors |
| --- | --- | --- | --- |
{rows}
"""

