from heitang_kb_forge.workbench import make_p1_workbench_bundle


def test_p1_workbench_registry_ids_are_stable_and_unique():
    bundle = make_p1_workbench_bundle()

    _assert_unique([action.action_id for action in bundle.action_contracts])
    _assert_unique([report.report_id for report in bundle.report_registry])
    _assert_unique([artifact.artifact_id for artifact in bundle.artifact_registry])
    _assert_unique([error.error_code for error in bundle.error_taxonomy])


def test_p1_workbench_registry_cross_references_are_valid():
    bundle = make_p1_workbench_bundle()
    action_ids = {action.action_id for action in bundle.action_contracts}
    report_ids = {report.report_id for report in bundle.report_registry}
    artifact_ids = {artifact.artifact_id for artifact in bundle.artifact_registry}
    error_codes = {error.error_code for error in bundle.error_taxonomy}
    task_statuses = set(bundle.task_schema.statuses)

    for area in bundle.capability_areas:
        assert set(area.action_ids) <= action_ids
        assert set(area.report_ids) <= report_ids
        assert set(area.artifact_ids) <= artifact_ids
    for action in bundle.action_contracts:
        assert set(action.report_ids) <= report_ids
        assert set(action.artifact_ids) <= artifact_ids
        assert set(action.error_codes) <= error_codes
        assert set(action.task_statuses) <= task_statuses


def test_p1_workbench_task_schema_contains_job_center_fields():
    fields = {field.field_id: field for field in make_p1_workbench_bundle().task_schema.fields}

    assert set(fields) >= {
        "task_id",
        "action_id",
        "progress",
        "current_step",
        "output_reports",
        "output_artifacts",
        "can_cancel",
        "can_retry",
        "can_resume",
    }
    assert set(make_p1_workbench_bundle().task_schema.statuses) == {
        "queued",
        "running",
        "succeeded",
        "failed",
        "blocked",
        "cancelled",
        "degraded",
        "timed_out",
        "review_required",
    }


def test_p1_workbench_fixtures_do_not_embed_private_inputs():
    text = str(make_p1_workbench_bundle().deterministic_fixtures).lower()

    assert "c:\\users\\" not in text
    assert "sk-" not in text
    assert "api_key" not in text
    assert "raw_input" not in text
    assert "<workspace>" in text


def _assert_unique(values):
    assert len(values) == len(set(values))
