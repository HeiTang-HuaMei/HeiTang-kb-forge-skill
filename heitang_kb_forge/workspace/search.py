from pathlib import Path
import json


def search_workspace(workspace: Path, query: str) -> list[dict]:
    query_l = query.lower()
    results = []
    for name in ["package_registry.jsonl", "skill_registry.jsonl", "agent_registry.jsonl"]:
        path = workspace / "registries" / name
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            if line.strip() and query_l in line.lower():
                item = json.loads(line)
                item["registry"] = name
                results.append(item)
    return results
