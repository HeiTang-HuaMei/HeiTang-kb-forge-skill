from heitang_kb_forge.workspace_storage import write_workspace_storage_outputs
from tests.v39_helpers import make_workspace, read_json


def test_storage_report_counts_size_by_type(tmp_path):
    workspace = make_workspace(tmp_path)

    write_workspace_storage_outputs(workspace)

    report = read_json(workspace / "storage_usage_report.json")
    assert report["total_file_count"] >= 5
    assert report["total_size_bytes"] > 0
    assert "package" in report["by_asset_type"]
    assert (workspace / "storage_report.md").exists()
