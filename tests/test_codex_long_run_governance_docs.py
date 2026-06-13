from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "governance"


REQUIRED_FILES = [
    "DEPENDENCY_REMEDIATION_POLICY.md",
    "CODEX_RESILIENCE_RULES.md",
    "SUB_AGENT_LIFECYCLE.md",
    "RECOVERY_CHECKPOINT_POLICY.md",
    "INTEGRATION_DECISION_POLICY.md",
    "UI_STATUS_TRUTHFULNESS_POLICY.md",
    "GOAL_ACCEPTANCE_LEDGER.json",
    "GOAL_ACCEPTANCE_LEDGER.md",
    "GOAL_DRIFT_CONTROL_POLICY.md",
    "FULL_ACCESS_EXECUTION_POLICY.md",
    "PRE_APPROVED_EXECUTION_POLICY.md",
    "HUMAN_INTERRUPT_ONLY_POLICY.md",
    "DOCUMENT_OUTPUT_GOVERNANCE_POLICY.md",
]


def _text(name: str) -> str:
    return (GOVERNANCE / name).read_text(encoding="utf-8")


def test_codex_long_run_governance_policy_files_exist():
    for name in REQUIRED_FILES:
        assert (GOVERNANCE / name).exists(), name


def test_dependency_remediation_policy_requires_attempt_before_final_blocked():
    text = _text("DEPENDENCY_REMEDIATION_POLICY.md")

    for marker in [
        "Local dependency download and installation is allowed",
        "Initial missing dependency evidence is not enough",
        "Attempt dependency remediation",
        "<adapter>_dependency_remediation_report.json",
        "post_install_smoke_result",
        "final_decision",
    ]:
        assert marker in text


def test_resilience_policy_has_checkpoint_and_bounded_retry_rules():
    text = _text("CODEX_RESILIENCE_RULES.md")

    for marker in [
        "Before any retry, write checkpoint",
        "retry 1: wait 3 minutes",
        "retry 2: wait 7 minutes",
        "retry 3: wait 15 minutes",
        "retry 4: stop further requests",
        "no infinite retries",
        "no duplicate sub-agent spawn",
    ]:
        assert marker in text


def test_recovery_checkpoint_policy_lists_required_runtime_artifacts_and_fields():
    text = _text("RECOVERY_CHECKPOINT_POLICY.md")

    for marker in [
        ".codex/recovery_checkpoint.json",
        ".codex/retry_log.jsonl",
        ".codex/recovery_report.md",
        ".codex/active_agents.json",
        "current_goal",
        "current_slice_or_task",
        "current_diff_summary",
        "last_successful_command",
        "last_failed_command",
        "active_agents_snapshot",
    ]:
        assert marker in text


def test_sub_agent_lifecycle_policy_limits_concurrency_and_requires_consolidation():
    text = _text("SUB_AGENT_LIFECYCLE.md")

    for marker in [
        "Default maximum running sub-agents: 2",
        "at most 3 running sub-agents",
        "idle sub-agent older than 15 minutes",
        "blocked sub-agent older than 20 minutes",
        "more than 3 retries",
        "Sub-agent output cannot directly decide final state",
        "adopted suggestions",
        "rejected suggestions",
    ]:
        assert marker in text


def test_integration_and_ui_policies_prevent_truth_overclaims():
    integration = _text("INTEGRATION_DECISION_POLICY.md")
    ui = _text("UI_STATUS_TRUTHFULNESS_POLICY.md")

    for marker in [
        "real_integration",
        "reference_only",
        "needs_strengthening",
        "stop_integration",
        "If missing, attempt dependency remediation",
        "<adapter>_ui_impact_note.md",
    ]:
        assert marker in integration
    for marker in [
        "dependency_missing",
        "installing_dependency",
        "install_failed",
        "smoke_pending",
        "structured_skipped",
        "must not display `ready`, `passed`, or `available`",
        "Static web builds may display evidence",
    ]:
        assert marker in ui
