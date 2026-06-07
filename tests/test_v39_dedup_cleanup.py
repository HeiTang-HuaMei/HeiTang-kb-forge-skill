from heitang_kb_forge.workspace_storage import write_workspace_storage_outputs
from tests.v39_helpers import make_workspace, read_json


def test_dedup_and_cleanup_are_recommendation_only(tmp_path):
    workspace = make_workspace(tmp_path)

    write_workspace_storage_outputs(workspace)

    dedup = read_json(workspace / "dedup_report.json")
    cleanup = read_json(workspace / "cleanup_plan.json")
    archive = read_json(workspace / "archive_plan.json")
    assert dedup["duplicate_group_count"] >= 1
    assert cleanup["recommendation_only"] is True
    assert cleanup["destructive_action_taken"] is False
    assert archive["recommendation_only"] is True
