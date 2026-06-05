from pathlib import Path
import json


def make_benchmark_cases(skill: Path) -> list[dict]:
    path = skill / "eval_cases.jsonl"
    if not path.exists():
        return []
    cases = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    for case in cases:
        case["benchmark_type"] = "v1.8_skill_validation"
    return cases
