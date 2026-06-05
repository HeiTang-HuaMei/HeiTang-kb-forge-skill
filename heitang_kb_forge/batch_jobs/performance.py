from heitang_kb_forge.schemas.batch_job_schema import BatchJobManifest


def summarize_performance(manifest: BatchJobManifest) -> dict:
    return {
        "total_items": manifest.total_items,
        "success_count": manifest.success_count,
        "failed_count": manifest.failed_count,
        "profile": manifest.profile,
        "status": manifest.status,
    }
