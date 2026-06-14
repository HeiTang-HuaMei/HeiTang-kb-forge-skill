import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKSPACE = Path(r"D:\HeiTang-Codex-WorkSpace")
PROJECT_AGENTS = ROOT / "AGENTS.md"
CONTROL_INDEX = ROOT / "docs" / "governance" / "PROJECT_CONTROL_INDEX.md"
NON_FORGETTABLE = ROOT / "docs" / "governance" / "NON_FORGETTABLE_RULES.md"
LEDGER = ROOT / "docs" / "governance" / "GOAL_ACCEPTANCE_LEDGER.json"
PLAN_SEQUENCE_LOCK = ROOT / "docs" / "governance" / "PLAN_SEQUENCE_LOCK.md"
CAMPAIGN_STAGE_GATE_POLICY = ROOT / "docs" / "governance" / "CAMPAIGN_STAGE_GATE_POLICY.md"
PRE_CAMPAIGN_ACCEPTANCE_GATE = ROOT / "docs" / "governance" / "PRE_CAMPAIGN_ACCEPTANCE_GATE.md"
TARGET_ACCEPTANCE_MATRIX = ROOT / "docs" / "governance" / "TARGET_ACCEPTANCE_MATRIX.md"
CAMPAIGN_3_0_PLAN = ROOT / "docs" / "governance" / "CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md"
CAMPAIGN_3_4_0_PLAN = ROOT / "docs" / "governance" / "CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md"
CAMPAIGN_1_2_3_CLOSURE = ROOT / "docs" / "governance" / "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md"
REPOSITORY_PUBLIC_SURFACE_GATE = (
    ROOT / "docs" / "governance" / "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md"
)
PRODUCT_OUTPUT_SURFACE_GATE = (
    ROOT / "docs" / "governance" / "PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md"
)
PRE_4_0_GATE_PLAN = ROOT / "docs" / "governance" / "PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md"
CAMPAIGN_4_9_REPLACEMENT = ROOT / "docs" / "governance" / "CAMPAIGN_4_9_REPLACEMENT_PLAN.md"
CAMPAIGN_4_5_REPLACEMENT = ROOT / "docs" / "governance" / "CAMPAIGN_4_5_REPLACEMENT_PLAN.md"
VALIDATION_MANIFEST = ROOT / "docs" / "testing" / "VALIDATION_GATE_MANIFEST.json"

REQUIRED_WORKSPACE_RULES = [
    r"D:\HeiTang-Codex-WorkSpace\AGENTS.md",
    r"D:\HeiTang-Codex-WorkSpace\00_全局控制台.md",
    r"D:\HeiTang-Codex-WorkSpace\01_全局复利与踩坑日志.md",
    r"D:\HeiTang-Codex-WorkSpace\03_测试与发布总规则.md",
    r"D:\HeiTang-Codex-WorkSpace\09_项目记忆锁与执行规则.md",
    r"D:\HeiTang-Codex-WorkSpace\10_文档产物治理规则.md",
    r"D:\HeiTang-Codex-WorkSpace\11_Runtime缓存与依赖规则.md",
    r"D:\HeiTang-Codex-WorkSpace\12_Codex长任务恢复与子智能体规则.md",
]

NON_FORGETTABLE_MARKERS = [
    "Full Access Execution",
    "Dependency Remediation",
    "Retry / Recovery",
    "Sub-Agent Lifecycle",
    "Goal Drift Control",
    "Document Output Governance",
    "Runtime Cache Policy",
    "Progress Events",
    "Pitfall Prevention",
    "External Source Safety",
]


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_workspace_rule_files_exist_and_are_indexed():
    project_agents = _read(PROJECT_AGENTS)
    index = _read(CONTROL_INDEX)
    local_workspace_rules_available = WORKSPACE.exists()

    for path in REQUIRED_WORKSPACE_RULES:
        if local_workspace_rules_available:
            assert Path(path).exists(), path
        assert path in project_agents
        assert path in index


def test_project_agents_replaces_obsolete_mvp_scope_with_target_mode_lock():
    text = _read(PROJECT_AGENTS)

    assert "Older MVP-only constraints are obsolete" in text
    assert "local executable Agent knowledge supply-chain workbench" in text
    assert "Full Access Execution is authorized" in text
    assert "Runtime cache is project/workspace-local" in text
    assert "Markdown parsing" not in text
    assert "Do not implement yet" not in text


def test_project_control_index_lists_pre_run_checklist_and_fast_gate_binding():
    text = _read(CONTROL_INDEX)

    for marker in [
        "Pre-Run Checklist",
        "WorkSpace `AGENTS.md`",
        "Project `AGENTS.md`",
        "PROJECT_CONTROL_INDEX.md",
        "GOAL_ACCEPTANCE_LEDGER.json",
        "NON_FORGETTABLE_RULES.md",
        "PLAN_SEQUENCE_LOCK.md",
        "CAMPAIGN_STAGE_GATE_POLICY.md",
        "PRE_CAMPAIGN_ACCEPTANCE_GATE.md",
        "TARGET_ACCEPTANCE_MATRIX.md",
        "CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md",
        "CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md",
        "CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md",
        "REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md",
        "PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md",
        "PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md",
        "CAMPAIGN_4_9_REPLACEMENT_PLAN.md",
        "CAMPAIGN_4_5_REPLACEMENT_PLAN.md",
        r"D:\HeiTang-Codex-WorkSpace\01_全局复利与踩坑日志.md",
        "Fast Gate Binding",
        "tests/test_project_control_index.py",
        "tests/test_plan_sequence_lock.py",
        "git diff --check",
    ]:
        assert marker in text


def test_plan_sequence_lock_and_matrix_are_project_controls():
    project_agents = _read(PROJECT_AGENTS)
    index = _read(CONTROL_INDEX)

    for path in [
        PLAN_SEQUENCE_LOCK,
        CAMPAIGN_STAGE_GATE_POLICY,
        PRE_CAMPAIGN_ACCEPTANCE_GATE,
        TARGET_ACCEPTANCE_MATRIX,
        CAMPAIGN_3_0_PLAN,
        CAMPAIGN_3_4_0_PLAN,
        CAMPAIGN_1_2_3_CLOSURE,
        REPOSITORY_PUBLIC_SURFACE_GATE,
        PRODUCT_OUTPUT_SURFACE_GATE,
        PRE_4_0_GATE_PLAN,
        CAMPAIGN_4_9_REPLACEMENT,
        CAMPAIGN_4_5_REPLACEMENT,
    ]:
        assert path.exists()
        project_relative = str(path.relative_to(ROOT)).replace("\\", "/")
        assert project_relative in project_agents
        assert project_relative in index


def test_non_forgettable_rules_cover_required_memory_lock_topics():
    text = _read(NON_FORGETTABLE)

    for marker in NON_FORGETTABLE_MARKERS:
        assert marker in text
    for marker in [
        "Do not repeatedly ask",
        "cannot be treated as final blockers until remediation has been attempted",
        "checkpoint plus bounded retry",
        "concurrency-limited",
        "single command with exit code 0",
        "artifacts/audits/latest/<run_id>/run_manifest.json",
        "must not silently write to C drive system paths",
        "Tasks longer than 3 seconds",
        "Tasks longer than 30 seconds",
        "test, Gate, checklist, or manifest",
        "Do not bypass login, CAPTCHA, paywalls, or platform controls",
        "do not import, save, or upload cookies",
    ]:
        assert marker in text


def test_goal_ledger_remains_active_and_not_completed_by_memory_lock():
    ledger = json.loads(LEDGER.read_text(encoding="utf-8"))
    statuses = {item["id"]: item["status"] for item in ledger["capabilities"]}

    assert ledger["goal_active"] is True
    assert statuses["skill_generation"] == "e2e_passed"
    assert statuses["skill_import_decomposition_learning"] == "contract_only"
    assert statuses["owned_skill_generation"] == "contract_only"
    assert statuses["agent_creation"] == "e2e_passed"
    assert statuses["agent_binding"] == "e2e_passed"
    assert statuses["multi_agent_workflow"] == "contract_only"
    assert statuses["external_evidence_verification"] == "e2e_passed"
    assert statuses["exe_packaging"] == "not_started"
    assert "done" not in set(statuses.values())


def test_validation_manifest_runs_fast_gate_for_project_memory_lock_files():
    manifest = json.loads(VALIDATION_MANIFEST.read_text(encoding="utf-8"))
    governance_rule = next(rule for rule in manifest["impact_rules"] if rule["name"] == "test_governance")

    for path in [
        "AGENTS.md",
        "docs/governance/PROJECT_CONTROL_INDEX.md",
        "docs/governance/TARGET_MODE_ACCEPTANCE_PLAN.md",
        "docs/governance/PLAN_SEQUENCE_LOCK.md",
        "docs/governance/CAMPAIGN_STAGE_GATE_POLICY.md",
        "docs/governance/PRE_CAMPAIGN_ACCEPTANCE_GATE.md",
        "docs/governance/TARGET_ACCEPTANCE_MATRIX.md",
        "docs/governance/CAMPAIGN_3_0_EXTERNAL_SOURCE_MEMORY_VERIFICATION_PLAN.md",
        "docs/governance/CAMPAIGN_3_SUPPLEMENT_4_0_KNOWLEDGE_TO_SKILL_TEMPLATE_GENERATOR_PLAN.md",
        "docs/governance/CAMPAIGN_1_2_3_INTEGRATED_CLOSURE_POLICY.md",
        "docs/governance/REPOSITORY_PUBLIC_SURFACE_CLEANUP_RENAME_PUSH_TAG_SAFETY_GATE_PLAN.md",
        "docs/governance/PRODUCT_OUTPUT_SURFACE_AND_EXTERNAL_TREND_ALIGNMENT_GATE.md",
        "docs/governance/PRE_4_0_WORKSPACE_PARTITION_FOUNDATION_GATE_PLAN.md",
        "docs/governance/CAMPAIGN_4_9_REPLACEMENT_PLAN.md",
        "docs/governance/CAMPAIGN_4_5_REPLACEMENT_PLAN.md",
        "docs/governance/NON_FORGETTABLE_RULES.md",
        "tests/test_project_control_index.py",
        "tests/test_plan_sequence_lock.py",
        "tests/test_campaign_stage_gate_policy.py",
        "tests/test_pre_campaign_acceptance_gate.py",
        "tests/test_campaign_1_2_3_integrated_closure_policy.py",
        "tests/test_repository_public_surface_cleanup_gate_plan.py",
        "tests/test_product_output_surface_external_trend_alignment.py",
        "tests/test_pre_4_0_workspace_partition_gate_plan.py",
        "tests/test_campaign_4_9_replacement_plan.py",
        "tests/test_campaign_4_5_replacement_plan.py",
        "tests/test_backend_remediation_acceptance.py",
        "tests/test_knowledge_supply_chain_acceptance.py",
        "tests/test_campaign_3_external_source_memory_plan.py",
    ]:
        assert path in governance_rule["patterns"]

    fast_gate = next(gate for gate in manifest["gates"] if gate["name"] == "core_fast_test_governance")
    assert "tests/test_project_control_index.py" in fast_gate["command"]
    assert "tests/test_plan_sequence_lock.py" in fast_gate["command"]
    assert "tests/test_campaign_stage_gate_policy.py" in fast_gate["command"]
    assert "tests/test_campaign_1_2_3_integrated_closure_policy.py" in fast_gate["command"]
    assert "tests/test_repository_public_surface_cleanup_gate_plan.py" in fast_gate["command"]
    assert "tests/test_product_output_surface_external_trend_alignment.py" in fast_gate["command"]
    assert "tests/test_pre_4_0_workspace_partition_gate_plan.py" in fast_gate["command"]
    assert "tests/test_campaign_4_9_replacement_plan.py" in fast_gate["command"]
    assert "tests/test_campaign_4_5_replacement_plan.py" in fast_gate["command"]
    assert "tests/test_pre_campaign_acceptance_gate.py" in fast_gate["command"]
    assert "tests/test_backend_remediation_acceptance.py" in fast_gate["command"]
    assert "tests/test_knowledge_supply_chain_acceptance.py" in fast_gate["command"]
    assert "tests/test_campaign_3_external_source_memory_plan.py" in fast_gate["command"]
