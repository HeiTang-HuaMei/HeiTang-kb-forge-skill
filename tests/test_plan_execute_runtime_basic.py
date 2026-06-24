from heitang_kb_forge.plan_execute import run_plan_execute


def test_plan_execute_runs_ready_steps_in_order():
    report = run_plan_execute(
        {
            "steps": [
                {"step_id": "read", "title": "Read facts"},
                {"step_id": "test", "title": "Run tests", "depends_on": ["read"]},
                {"step_id": "commit", "title": "Commit", "depends_on": ["test"]},
            ]
        }
    )

    assert report.status == "executed"
    assert report.execution_order == ["read", "test", "commit"]
    assert report.remaining_step_ids == []
    assert report.blocked_step_ids == []


def test_plan_execute_preserves_blocked_steps():
    report = run_plan_execute(
        {
            "steps": [
                {"step_id": "read", "title": "Read facts", "completed": True},
                {"step_id": "repair", "title": "Repair", "blocked": True, "depends_on": ["read"]},
                {"step_id": "retest", "title": "Retest", "depends_on": ["repair"]},
            ]
        }
    )

    assert report.status == "blocked"
    assert report.completed_step_ids == ["read"]
    assert report.blocked_step_ids == ["repair"]
    assert report.remaining_step_ids == ["retest"]


def test_plan_execute_reports_missing_dependencies():
    report = run_plan_execute(
        {
            "steps": [
                {"step_id": "commit", "title": "Commit", "depends_on": ["test"]},
            ]
        }
    )

    assert report.status == "missing_dependencies"
    assert report.execution_order == []
    assert report.missing_dependency_step_ids == ["commit"]
