from pathlib import Path
import json
import re

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.platform_distribution.platforms import SUPPORTED_PLATFORMS, required_files
from heitang_kb_forge.schemas.platform_distribution_schema import PlatformUploadCheckResult

TEXT_SUFFIXES = {".json", ".jsonl", ".md", ".txt", ".yaml", ".yml"}
API_KEY_PATTERNS = [
    re.compile(r"\bapi[_-]?key\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{10,}", re.IGNORECASE),
    re.compile(r"\b(access[_-]?token|secret[_-]?key|client[_-]?secret)\s*[:=]\s*['\"]?[A-Za-z0-9_\-]{10,}", re.IGNORECASE),
    re.compile(r"\bsk-[A-Za-z0-9]{10,}"),
]
DANGEROUS_COMMAND_PATTERNS = [
    re.compile(r"\brm\s+-rf\b", re.IGNORECASE),
    re.compile(r"\bRemove-Item\b.*\b-Recurse\b.*\b-Force\b", re.IGNORECASE),
    re.compile(r"\bcurl\b.*\bhttps?://", re.IGNORECASE),
    re.compile(r"\bInvoke-WebRequest\b", re.IGNORECASE),
    re.compile(r"\bStart-Process\b", re.IGNORECASE),
]


def check_platform_upload(export: Path, output: Path | None = None, platform: str | None = None) -> PlatformUploadCheckResult:
    target = output or export
    target.mkdir(parents=True, exist_ok=True)
    inferred_platform = _infer_platform(export, platform)
    self_generated = {"platform_upload_check_result.json", "platform_upload_check_report.md"}
    missing = [name for name in required_files(inferred_platform) if name not in self_generated and not (export / name).exists()]
    risk_files, api_key_risk, dangerous_command = _scan_risks(export)
    passed = not missing and not api_key_risk and not dangerous_command
    result = PlatformUploadCheckResult(
        platform=inferred_platform,
        status="passed" if passed else "failed",
        required_files_present=not missing,
        missing_files=missing,
        api_key_risk_detected=api_key_risk,
        dangerous_command_detected=dangerous_command,
        risk_files=risk_files,
        checks={
            "required_files_present": not missing,
            "api_key_risk_detected": api_key_risk,
            "dangerous_command_detected": dangerous_command,
            "real_upload_allowed": False,
        },
        real_upload_allowed=False,
    )
    write_json(target / "platform_upload_check_result.json", result)
    (target / "platform_upload_check_report.md").write_text(render_upload_check_report(result), encoding="utf-8")
    return result


def _infer_platform(export: Path, platform: str | None) -> str:
    if platform:
        return platform
    manifest = export / "platform_manifest.json"
    if manifest.exists():
        try:
            payload = json.loads(manifest.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            payload = {}
        candidate = payload.get("platform")
        if candidate in SUPPORTED_PLATFORMS:
            return candidate
    return export.name if export.name in SUPPORTED_PLATFORMS else "generic"


def _scan_risks(export: Path) -> tuple[list[str], bool, bool]:
    risk_files: set[str] = set()
    api_key_risk = False
    dangerous_command = False
    for path in export.rglob("*"):
        if not path.is_file() or path.suffix.lower() not in TEXT_SUFFIXES:
            continue
        relative = path.relative_to(export).as_posix()
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        if any(pattern.search(text) for pattern in API_KEY_PATTERNS):
            api_key_risk = True
            risk_files.add(relative)
        if any(pattern.search(text) for pattern in DANGEROUS_COMMAND_PATTERNS):
            dangerous_command = True
            risk_files.add(relative)
    return sorted(risk_files), api_key_risk, dangerous_command


def render_upload_check_report(result: PlatformUploadCheckResult) -> str:
    return (
        "# Platform Upload Check Report\n\n"
        f"- Platform: {result.platform}\n"
        f"- Status: {result.status}\n"
        f"- Missing files: {', '.join(result.missing_files) or 'None'}\n"
        f"- API key risk detected: {result.api_key_risk_detected}\n"
        f"- Dangerous command detected: {result.dangerous_command_detected}\n"
        f"- Risk files: {', '.join(result.risk_files) or 'None'}\n"
        "- Real upload allowed: False\n"
    )
