from datetime import datetime, timezone
from pathlib import Path


def make_prompt_profile_record(profile_id: str, profile_type: str, rules: Path) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    return {
        "profile_id": profile_id,
        "profile_name": profile_id,
        "profile_type": profile_type,
        "description": f"{profile_type} prompt profile",
        "rules_path": str(rules).replace("\\", "/"),
        "template_path": None,
        "created_at": now,
        "updated_at": now,
        "enabled": True,
    }
