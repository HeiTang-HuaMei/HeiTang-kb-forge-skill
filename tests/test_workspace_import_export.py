from heitang_kb_forge.workspace.exporter import export_workspace
from heitang_kb_forge.workspace.importer import import_workspace_asset
from heitang_kb_forge.workspace.initializer import init_portable_workspace
from tests.v17_helpers import read_json, write_sample_package


def test_workspace_import_and_export(tmp_path):
    workspace = tmp_path / "workspace"
    package = write_sample_package(tmp_path / "package")
    export = tmp_path / "export"
    init_portable_workspace(workspace)

    record = import_workspace_asset(workspace, package, "knowledge")
    manifest = export_workspace(workspace, export)

    assert record["package_id"] == "package"
    assert read_json(export / "export_manifest.json")["export_version"] == "1.9"
    assert "registries" in manifest["exported_files"]
