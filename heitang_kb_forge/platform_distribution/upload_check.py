from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.platform_distribution.platforms import required_files
from heitang_kb_forge.schemas.platform_distribution_schema import PlatformUploadCheckResult


def check_platform_upload(export: Path, output: Path | None = None, platform: str | None = None) -> PlatformUploadCheckResult:
    target = output or export
    target.mkdir(parents=True, exist_ok=True)
    inferred_platform = platform or export.name
    missing = [name for name in required_files(inferred_platform) if not (export / name).exists()]
    result = PlatformUploadCheckResult(
        platform=inferred_platform,
        status="passed" if not missing else "failed",
        required_files_present=not missing,
        missing_files=missing,
        real_upload_allowed=False,
    )
    write_json(target / "platform_upload_check_result.json", result)
    (target / "platform_upload_check_report.md").write_text(render_upload_check_report(result), encoding="utf-8")
    return result


def render_upload_check_report(result: PlatformUploadCheckResult) -> str:
    return (
        "# Platform Upload Check Report\n\n"
        f"- Platform: {result.platform}\n"
        f"- Status: {result.status}\n"
        f"- Missing files: {', '.join(result.missing_files) or 'None'}\n"
        "- Real upload allowed: False\n"
    )
