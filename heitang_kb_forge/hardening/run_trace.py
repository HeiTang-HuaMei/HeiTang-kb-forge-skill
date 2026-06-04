from datetime import datetime, timezone
import time
import traceback
from uuid import uuid4


def new_run_id() -> str:
    return f"run_{uuid4().hex[:12]}"


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def make_run_manifest(run_id: str, command: str, input_path: str, output_path: str, status: str, warnings: list[str] | None = None) -> dict:
    return {
        "run_manifest_version": "1.2.1",
        "run_id": run_id,
        "command": command,
        "input": input_path,
        "output": output_path,
        "status": status,
        "generated_at": now_iso(),
        "warnings": warnings or [],
    }


def stage_record(run_id: str, stage: str, status: str, started_at: str, finished_at: str, input_files: list[str] | None = None, output_files: list[str] | None = None, warnings: list[str] | None = None, error: str | None = None) -> dict:
    return {
        "run_id": run_id,
        "stage": stage,
        "status": status,
        "started_at": started_at,
        "finished_at": finished_at,
        "duration_ms": _duration_ms(started_at, finished_at),
        "input_files": input_files or [],
        "output_files": output_files or [],
        "warnings": warnings or [],
        "error": error,
    }


def make_error_report(run_id: str, stage: str, exc: Exception, source_path: str | None = None, include_traceback: bool = False) -> dict:
    return {
        "error_report_version": "1.2.1",
        "run_id": run_id,
        "stage": stage,
        "source_path": source_path,
        "error_type": type(exc).__name__,
        "error_message": _redact(str(exc)),
        "traceback": _redact(traceback.format_exc()) if include_traceback else None,
    }


def monotonic_ms() -> int:
    return int(time.monotonic() * 1000)


def _duration_ms(started_at: str, finished_at: str) -> int:
    try:
        start = datetime.fromisoformat(started_at)
        finish = datetime.fromisoformat(finished_at)
    except ValueError:
        return 0
    return max(0, int((finish - start).total_seconds() * 1000))


def _redact(value: str) -> str:
    redacted = value
    for marker in ["api_key", "API_KEY", "token", "TOKEN", "secret", "SECRET"]:
        redacted = redacted.replace(marker, "[redacted]")
    return redacted
