from pathlib import Path


def boundary_score(skill: Path) -> tuple[int, list[str]]:
    warnings = []
    for file_name in ["boundary_rules.md", "refusal_rules.md"]:
        text = (skill / file_name).read_text(encoding="utf-8") if (skill / file_name).exists() else ""
        if "refuse" not in text.lower() and "拒" not in text:
            warnings.append(f"{file_name}_missing_refusal")
    return (100 if not warnings else 70), warnings
