from pathlib import Path


def run_skill_license_check(skill: Path, output: Path) -> tuple[dict, str]:
    output.mkdir(parents=True, exist_ok=True)
    has_license = any(item.name.lower().startswith("license") for item in (skill.rglob("*") if skill.is_dir() else [skill]))
    result = {"status": "pass" if has_license else "warning", "license_found": has_license}
    report = f"# Skill License Report\n\n- License found: {has_license}\n- Status: {result['status']}\n"
    (output / "skill_license_report.md").write_text(report, encoding="utf-8")
    return result, report
