from __future__ import annotations


def build_storage_usage_report(registries: dict[str, list[dict]]) -> dict:
    by_type = {}
    total_files = 0
    total_size = 0
    for asset_type, entries in sorted(registries.items()):
        size = sum(int(entry.get("size_bytes", 0)) for entry in entries)
        by_type[asset_type] = {"file_count": len(entries), "size_bytes": size}
        total_files += len(entries)
        total_size += size
    return {
        "storage_usage_report_version": "3.9.0-alpha.1",
        "storage_backend": "local_workspace",
        "total_file_count": total_files,
        "total_size_bytes": total_size,
        "by_asset_type": by_type,
        "package_size_bytes": by_type.get("package", {}).get("size_bytes", 0),
        "memory_size_bytes": by_type.get("memory", {}).get("size_bytes", 0),
        "index_size_bytes": by_type.get("index", {}).get("size_bytes", 0),
        "generated_document_size_bytes": by_type.get("document", {}).get("size_bytes", 0),
    }


def render_storage_report_md(report: dict) -> str:
    rows = "\n".join(
        f"| {asset_type} | {stats['file_count']} | {stats['size_bytes']} |"
        for asset_type, stats in report["by_asset_type"].items()
    )
    return f"""# Storage Report

- Backend: {report['storage_backend']}
- Total files: {report['total_file_count']}
- Total size bytes: {report['total_size_bytes']}

| Asset type | Files | Size bytes |
| --- | ---: | ---: |
{rows}
"""
