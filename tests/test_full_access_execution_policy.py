from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"


def _text(name: str) -> str:
    return (GOVERNANCE / name).read_text(encoding="utf-8")


def test_full_access_policy_files_exist():
    for name in [
        "FULL_ACCESS_EXECUTION_POLICY.md",
        "PRE_APPROVED_EXECUTION_POLICY.md",
        "HUMAN_INTERRUPT_ONLY_POLICY.md",
    ]:
        assert (GOVERNANCE / name).exists(), name


def test_scope_expansion_and_project_dependency_install_do_not_require_confirmation():
    policy = _text("PRE_APPROVED_EXECUTION_POLICY.md")

    assert "expand the working scope required by the final goal" in policy
    assert "install project-local dependencies" in policy
    assert "These actions do not trigger routine human confirmation" in policy


def test_system_dependency_install_requires_checkpoint_without_confirmation():
    policy = _text("PRE_APPROVED_EXECUTION_POLICY.md")
    row = next(line for line in policy.splitlines() if line.startswith("| system dependency install |"))

    assert "pre-action checkpoint" in row
    assert "source/version/path" in row
    assert "rollback plan" in row
    assert row.endswith("| no |")


def test_push_tag_release_require_checkpoint_without_confirmation():
    policy = _text("PRE_APPROVED_EXECUTION_POLICY.md")
    row = next(line for line in policy.splitlines() if line.startswith("| push, tag, GitHub Release |"))

    assert "pre-action checkpoint" in row
    assert "rollback plan" in row
    assert "post-action report" in row
    assert row.endswith("| no |")
    assert "until the full target is complete remains controlling" in policy


def test_destructive_project_cleanup_requires_rollback_without_confirmation():
    policy = _text("PRE_APPROVED_EXECUTION_POLICY.md")
    row = next(line for line in policy.splitlines() if line.startswith("| destructive project-file cleanup |"))

    assert "file inventory or backup" in row
    assert "rollback plan" in row
    assert row.endswith("| no |")


def test_retry_checkpoint_and_sub_agent_cleanup_do_not_require_confirmation():
    policy = _text("PRE_APPROVED_EXECUTION_POLICY.md")

    assert "| retry or recovery | recovery checkpoint and bounded retry log | no |" in policy
    assert "| sub-agent cleanup | lifecycle registry update and archive/termination record | no |" in policy


def test_only_hard_interrupt_conditions_allow_pause():
    policy = _text("HUMAN_INTERRUPT_ONLY_POLICY.md")

    for marker in [
        "API key",
        "Payment is required",
        "bounded retry policy is exhausted",
        "outside the current project, workspace, or local-machine authorization boundary",
        "legal, security, privacy, or license risk",
        "No rollback plan can be produced",
        "platform-enforced control",
    ]:
        assert marker in policy

    for marker in [
        "reasonable goal-serving scope expansion",
        "project dependency installation",
        "system dependency installation after checkpoint",
        "dependency remediation",
        "real adapter smoke",
        "bounded retry, checkpoint, recovery, or sub-agent cleanup",
    ]:
        assert marker in policy


def test_high_risk_protocol_requires_checkpoint_rollback_validation_and_report():
    policy = _text("FULL_ACCESS_EXECUTION_POLICY.md")

    for marker in [
        "Write `pre_action_checkpoint`",
        "Record a rollback plan or backup location",
        "Run the relevant validation",
        "Write `post_action_report`",
        "enter bounded recovery",
    ]:
        assert marker in policy

    assert "Do not wait for routine human confirmation" in policy
    assert "platform-enforced approval or sandbox requirements" in policy
