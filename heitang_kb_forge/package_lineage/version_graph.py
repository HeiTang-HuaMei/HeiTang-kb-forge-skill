from pathlib import Path
from datetime import datetime, timezone
import json


def discover_package_nodes(workspace: Path) -> list[dict]:
    nodes = []
    for manifest_path in sorted(workspace.rglob("manifest.json")) if workspace.exists() else []:
        try:
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            manifest = {}
        package_path = manifest_path.parent
        nodes.append(
            {
                "package_id": manifest.get("package_id") or package_path.name,
                "package_version": manifest.get("package_version") or "unknown",
                "package_path": str(package_path).replace("\\", "/"),
                "created_at": manifest.get("generated_at") or datetime.now(timezone.utc).isoformat(),
                "status": "active",
            }
        )
    return nodes


def make_version_graph(workspace: Path) -> dict:
    nodes = discover_package_nodes(workspace)
    edges = [
        {
            "from": nodes[index - 1]["package_id"],
            "to": nodes[index]["package_id"],
            "relationship": "updated_from",
        }
        for index in range(1, len(nodes))
    ]
    return {"nodes": nodes, "edges": edges}
