from pathlib import Path


def scan_workspace_sources(workspace: Path) -> list[dict]:
    if not workspace.exists():
        return []
    return [
        {"path": str(path).replace("\\", "/"), "status": "present"}
        for path in sorted(workspace.rglob("*"))
        if path.is_file() and path.suffix.lower() in {".md", ".txt", ".pdf", ".docx", ".json", ".jsonl", ".yaml"}
    ]
