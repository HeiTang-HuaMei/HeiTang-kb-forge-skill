from datetime import datetime, timezone
from pathlib import Path
import json


def detect_staleness(package: Path, max_age_days: int = 180) -> dict:
    manifest_path = package / "manifest.json"
    generated_at = None
    if manifest_path.exists():
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        generated_at = manifest.get("generated_at") or manifest.get("created_at")
    age_days = _age_days(generated_at, package)
    stale = age_days is not None and age_days > max_age_days
    return {
        "staleness_report_version": "1.7.0",
        "package": str(package).replace("\\", "/"),
        "max_age_days": max_age_days,
        "age_days": age_days,
        "status": "warning" if stale else "pass",
        "stale_chunk_ids": _chunk_ids(package) if stale else [],
    }


def _age_days(generated_at: str | None, package: Path) -> int | None:
    try:
        if generated_at:
            created = datetime.fromisoformat(generated_at.replace("Z", "+00:00"))
        else:
            created = datetime.fromtimestamp(package.stat().st_mtime, tz=timezone.utc)
        return (datetime.now(timezone.utc) - created).days
    except Exception:
        return None


def _chunk_ids(package: Path) -> list[str]:
    path = package / "chunks.jsonl"
    if not path.exists():
        return []
    return [json.loads(line).get("chunk_id", "") for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
