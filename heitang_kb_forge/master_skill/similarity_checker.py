from pathlib import Path


def run_skill_similarity_check(master_skill: Path, derived_skill: Path, output: Path) -> tuple[dict, str]:
    output.mkdir(parents=True, exist_ok=True)
    master_tokens = set(_read_all(master_skill).lower().split())
    derived_tokens = set(_read_all(derived_skill).lower().split())
    score = round(len(master_tokens & derived_tokens) / max(len(master_tokens | derived_tokens), 1), 3)
    result = {"status": "warning" if score > 0.6 else "pass", "similarity_score": score}
    report = f"# Skill Similarity Report\n\n- Similarity score: {score}\n- Status: {result['status']}\n"
    (output / "skill_similarity_report.md").write_text(report, encoding="utf-8")
    return result, report


def _read_all(path: Path) -> str:
    if path.is_file():
        return path.read_text(encoding="utf-8", errors="ignore")
    return "\n".join(item.read_text(encoding="utf-8", errors="ignore") for item in path.rglob("*") if item.is_file())
