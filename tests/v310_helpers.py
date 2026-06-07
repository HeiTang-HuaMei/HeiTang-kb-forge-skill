import json
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json


def read_json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def make_package(tmp_path: Path, package_id: str = "alpha", text: str = "Pricing policy evidence.") -> Path:
    package = tmp_path / package_id
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": package_id, "domain": "general"})
    (package / "chunks.jsonl").write_text(json.dumps({"chunk_id": "c1", "text": text}) + "\n", encoding="utf-8")
    return package


def make_agent(tmp_path: Path, agent_id: str, mode: str, source_package_id: str | None = None) -> Path:
    agent = tmp_path / agent_id
    agent.mkdir()
    write_json(agent / "agent_manifest.json", {"agent_id": agent_id, "name": agent_id, "mode": mode})
    profile = f"agent_id: {agent_id}\nmode: {mode}\n"
    if source_package_id:
        profile += f"source_package_id: {source_package_id}\n"
    (agent / "agent_profile.yaml").write_text(profile, encoding="utf-8")
    return agent
