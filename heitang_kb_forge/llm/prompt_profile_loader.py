from pathlib import Path
import json


def load_workspace_prompt_profiles(workspace: Path) -> dict:
    path = workspace / "registries" / "prompt_profile_registry.json"
    if not path.exists():
        return {"profiles": []}
    return json.loads(path.read_text(encoding="utf-8"))
