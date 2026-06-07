from heitang_kb_forge.workspace_storage import write_workspace_storage_outputs
from tests.v39_helpers import make_workspace, read_json


def test_workspace_registry_initializes_and_scans_assets(tmp_path):
    workspace = make_workspace(tmp_path)

    write_workspace_storage_outputs(workspace)

    registry = read_json(workspace / "workspace_registry.json")
    assert registry["storage_backend"] == "local_workspace"
    assert registry["asset_counts"]["package"] >= 2
    assert registry["asset_counts"]["skill"] >= 1
    assert registry["asset_counts"]["agent"] >= 1
    assert read_json(workspace / "package_registry.json")["entries"]
    assert read_json(workspace / "skill_registry.json")["entries"]
    assert read_json(workspace / "agent_registry.json")["entries"]
    assert read_json(workspace / "document_registry.json")["entries"]
    assert read_json(workspace / "index_registry.json")["asset_type"] == "index"
