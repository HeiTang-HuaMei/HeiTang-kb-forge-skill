from heitang_kb_forge.workspace.initializer import init_portable_workspace


def test_workspace_init_creates_standard_directories(tmp_path):
    workspace = tmp_path / "workspace"

    manifest = init_portable_workspace(workspace)

    assert manifest.workspace_version == "1.9"
    assert (workspace / "workspace_manifest.json").exists()
    assert (workspace / "registries" / "package_registry.jsonl").exists()
    assert (workspace / "reports").exists()
