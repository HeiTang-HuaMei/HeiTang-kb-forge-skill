from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json, write_jsonl
from heitang_kb_forge.export_certification.matrix import CERTIFICATION_PLATFORMS
from heitang_kb_forge.export_certification.report import render_export_certification_report
from heitang_kb_forge.platform_distribution.platforms import required_files
from heitang_kb_forge.platform_distribution.upload_check import _scan_risks
from heitang_kb_forge.schemas.export_certification_schema import ExportCertificationResult, PlatformCertification


def certify_platform_export(export: Path, output: Path, platform: str = "all") -> ExportCertificationResult:
    output.mkdir(parents=True, exist_ok=True)
    platforms = [item for item in CERTIFICATION_PLATFORMS if item != "all"] if platform == "all" else [platform]
    results = [_certify_one(export / item if platform == "all" else export, item) for item in platforms]
    status = "fail" if any(item.status == "fail" for item in results) else "warning" if any(item.status == "warning" for item in results) else "pass"
    result = ExportCertificationResult(status=status, certified=status == "pass", platforms=results)
    write_json(output / "platform_export_certification.json", result)
    write_jsonl(output / "platform_certification_findings.jsonl", [item.model_dump(mode="json") for item in results if item.status != "pass"])
    (output / "platform_export_certification_report.md").write_text(render_export_certification_report(result), encoding="utf-8")
    return result


def _certify_one(export: Path, platform: str) -> PlatformCertification:
    missing = [name for name in required_files(platform) if not (export / name).exists()]
    risk_files, api_key_risk, dangerous_command = _scan_risks(export) if export.exists() else ([], False, False)
    errors = [f"missing:{name}" for name in missing]
    warnings = list(risk_files)
    policy_pass = _policy_pass(export, platform)
    boundary_pass = _boundary_pass(export, platform)
    if not policy_pass:
        errors.append("policy_check_failed")
    if not boundary_pass:
        errors.append("boundary_check_failed")
    if api_key_risk:
        errors.append("secret_leak_risk")
    if dangerous_command:
        errors.append("dangerous_command_risk")
    status = "fail" if errors else "pass"
    return PlatformCertification(
        platform=platform,
        status=status,
        certified=status == "pass",
        required_files_pass=not missing,
        policy_pass=policy_pass,
        security_pass=not api_key_risk and not dangerous_command,
        boundary_pass=boundary_pass,
        warnings=warnings,
        errors=errors,
    )


def _policy_pass(export: Path, platform: str) -> bool:
    if platform != "xhs":
        return True
    policy = export / "platform_policy.md"
    if not policy.exists():
        return False
    text = policy.read_text(encoding="utf-8")
    return "not an official XHS upload API" in text or "不是小红书官方上传 API" in text


def _boundary_pass(export: Path, platform: str) -> bool:
    combined = "\n".join(path.read_text(encoding="utf-8", errors="ignore") for path in export.glob("*.md"))
    if platform in {"openclaw", "codex", "claude_code", "mcp"}:
        return "stub" in combined.lower() or "No real platform runtime" in combined or "不真实运行" in combined
    if platform == "xhs":
        return "does not publish notes automatically" in combined or "不会自动发布笔记" in combined
    return True

