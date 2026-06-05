from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json


DANGEROUS_PATTERNS = ["rm -rf", "Remove-Item -Recurse", "api_key", "secret", "password", "curl http"]


def run_skill_safety_check(skill: Path, output: Path) -> tuple[dict, str]:
    output.mkdir(parents=True, exist_ok=True)
    text = _read_all(skill)
    warnings = [pattern for pattern in DANGEROUS_PATTERNS if pattern.lower() in text.lower()]
    result = {"status": "warning" if warnings else "pass", "warnings": warnings, "errors": []}
    write_json(output / "skill_safety_check_result.json", result)
    report = "# Skill Safety Check Report\n\n" + ("\n".join(f"- {item}" for item in warnings) or "- No high-risk pattern found")
    (output / "skill_safety_check_report.md").write_text(report, encoding="utf-8")
    return result, report


def _read_all(path: Path) -> str:
    if path.is_file():
        return path.read_text(encoding="utf-8", errors="ignore")
    return "\n".join(item.read_text(encoding="utf-8", errors="ignore") for item in path.rglob("*") if item.is_file())
