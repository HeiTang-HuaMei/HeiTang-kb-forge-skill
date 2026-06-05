from pathlib import Path
import hashlib
import json

from heitang_kb_forge.exporters.jsonl_exporter import write_json


def make_prompt_profile_versions(workspace: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    profile_files = sorted(workspace.rglob("*.yaml")) if workspace.exists() else []
    versions = []
    hashes = {}
    for path in profile_files:
        content = path.read_bytes()
        digest = hashlib.sha256(content).hexdigest()
        profile_id = path.stem
        versions.append({"profile_id": profile_id, "path": str(path).replace("\\", "/"), "hash": digest})
        hashes[profile_id] = digest
    if not versions:
        versions = [{"profile_id": "default_prompt_profile", "path": "", "hash": ""}]
        hashes = {"default_prompt_profile": ""}
    result = {"profiles": versions}
    write_json(output / "prompt_profile_versions.json", result)
    write_json(output / "prompt_profile_hashes.json", hashes)
    (output / "prompt_profile_usage_report.md").write_text(
        "# Prompt Profile Usage Report\n\n"
        f"- Profiles: {len(versions)}\n"
        "- Versioning is local and file-hash based.\n",
        encoding="utf-8",
    )
    return result
