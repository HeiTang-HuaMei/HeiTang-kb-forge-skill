import json
from pathlib import Path


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def make_workspace(tmp_path: Path) -> Path:
    workspace = tmp_path / "workspace"
    workspace.mkdir()
    (workspace / "manifest.json").write_text(json.dumps({"package_id": "pkg_v39"}), encoding="utf-8")
    (workspace / "chunks.jsonl").write_text('{"chunk_id":"c1","text":"Pricing evidence."}\n', encoding="utf-8")
    skill = workspace / "skill_package"
    skill.mkdir()
    (skill / "SKILL.md").write_text("# Skill\n", encoding="utf-8")
    agent = workspace / "agent_package"
    agent.mkdir()
    (agent / "agent_profile.yaml").write_text("name: Demo Agent\n", encoding="utf-8")
    (workspace / "duplicate_a.md").write_text("same content", encoding="utf-8")
    (workspace / "duplicate_b.md").write_text("same content", encoding="utf-8")
    return workspace
