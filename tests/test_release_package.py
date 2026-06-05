from heitang_kb_forge.release import make_release_package
from heitang_kb_forge.workspace.initializer import init_portable_workspace


def test_release_package_writes_release_manifest(tmp_path):
    workspace = tmp_path / "workspace"
    output = tmp_path / "release"
    init_portable_workspace(workspace)

    manifest = make_release_package(workspace, output)

    assert manifest["release_package_version"] == "2.0"
    assert (output / "release_manifest.json").exists()
