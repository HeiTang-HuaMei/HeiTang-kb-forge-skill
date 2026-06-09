import json

from heitang_kb_forge.workbench import P1_WORKBENCH_OUTPUT_FILES, make_p1_workbench_bundle, write_p1_workbench_bundle


def test_p1_workbench_bundle_covers_required_productization_surface(tmp_path):
    bundle = make_p1_workbench_bundle()

    assert bundle.profile == "p1"
    assert len(bundle.capability_areas) == 16
    assert len(bundle.action_contracts) >= 50
    assert len(bundle.report_registry) >= 40
    assert len(bundle.artifact_registry) >= 40
    assert len(bundle.error_taxonomy) == 20
    assert {area.title for area in bundle.capability_areas} >= {
        "Dashboard",
        "Workspace",
        "Import & Parsing",
        "Knowledge Package Management",
        "Retrieval & Verification",
        "Vector Hub / Provider / Storage",
        "Document Generation",
        "Skill Factory",
        "Agent Factory & Runtime",
        "Reports & Audit",
        "Task / Job Center",
        "Artifact Management",
    }

    output = tmp_path / "p1_contracts"
    manifest = write_p1_workbench_bundle(output)

    assert manifest["profile"] == "p1"
    assert manifest["p1_full_operation_gate_status"] == "blocked"
    for filename in P1_WORKBENCH_OUTPUT_FILES:
        assert (output / filename).exists(), filename
    for path in output.glob("*.json"):
        json.loads(path.read_text(encoding="utf-8"))


def test_every_p1_page_has_actions_reports_and_artifacts():
    bundle = make_p1_workbench_bundle()

    for area in bundle.capability_areas:
        assert area.action_ids, area.page_id
        assert area.report_ids, area.page_id
        assert area.artifact_ids, area.page_id
        assert "Windows desktop Workbench" in area.desktop_web_boundary
        assert "no raw input" in area.privacy_boundary


def test_buttons_are_action_ids_or_blocked_with_reasons():
    bundle = make_p1_workbench_bundle()

    for action in bundle.action_contracts:
        assert action.button_id == f"btn_{action.action_id}"
        assert action.status in {"ready", "dry_run", "planned_adapter", "ui_pending", "blocked"}
        if action.status == "ready":
            assert action.command
            assert action.blocked_reason is None
        if action.status in {"planned_adapter", "ui_pending", "blocked"}:
            assert action.blocked_reason
