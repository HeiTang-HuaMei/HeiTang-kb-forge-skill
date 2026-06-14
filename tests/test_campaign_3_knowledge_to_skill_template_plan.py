from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
GOVERNANCE = DOCS / "治理"
PLAN = DOCS / "Skill与Agent生成说明.md"
SEQUENCE = DOCS / "路线图.md"
MATRIX = GOVERNANCE / "目标验收矩阵.md"
POLICY = GOVERNANCE / "当前运行状态.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_supplement_4_0_replacement_is_registered_without_activation():
    text = _read(PLAN)

    for marker in [
        "Knowledge-to-Skill-to-Agent Package & Product Handoff Contract",
        "替代了早期只覆盖 `Knowledge-to-Skill Template Generator` 的窄范围",
        "Plan state: `accepted_for_campaign_3_final_consistency_gate`",
        "Current active phase: `Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`",
            "Current completed item: `Campaign 3 Supplement 4.0 Acceptance Gate`",
        "Current business item: `Campaign 3 Final Consistency Gate only`",
            "Supplement 3.0 Acceptance Gate、Pre-4.0 gate、bounded industrial-grade Entry Reconciliation Gate、4.0B Verified Knowledge-to-Skill Template、4.0C Skill Import & Dedicated Skill Composer、4.0D-I Product Handoff Contract Bundle、Supplement 4.0 Acceptance Gate 均已通过",
            "Campaign 3 Final Consistency Gate 是 4.0 后唯一 next safe action",
        "不是 Campaign 4 UI",
        "不是 Campaign 5 Bridge",
        "4.0B 不 profile real knowledge base",
        "不发布 Skill",
        "不在 4.0B 创建 Agent Package",
        "4.0C 已作为 bounded industrial-grade Skill Import & Dedicated Skill Composer implementation 通过",
    ]:
        assert marker in text


def test_supplement_4_0_sequence_preserves_total_plan_and_macro_order():
    combined = "\n".join([_read(PLAN), _read(SEQUENCE), _read(MATRIX), _read(POLICY)])

    for marker in [
        "Campaign 3 Supplement 3.0 External Source Memory & Verification",
        "Campaign 3 Final Consistency Gate",
        "Campaign 1-3 Stage Test Gate passed",
        "Campaign 1-3 Integrated Closure passed",
        "Closure Pack",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "Repository push succeeded",
        "GitHub CI Green",
        "Closure Checklist Green",
        "Campaign 4 | Goal-Oriented Product UI Workbench",
        "Campaign 5 | Chain-Level Local Core Bridge",
    ]:
        assert marker in combined

    assert "Campaign 3 Supplement 4.0 的完整产品边界" in combined
    assert "Campaign 4：目标导向 UI 工作台" in combined
    assert "Campaign 5：链路级 Local Core Bridge" in combined


def test_supplement_4_0_handoff_chain_extends_beyond_skill_template():
    text = _read(PLAN)

    for marker in [
        "Verified Knowledge Base",
        "Skill Template",
        "Dedicated Skill",
        "Agent Package",
        "Workspace-bound Agent",
        "Multi-Agent Workflow Spec",
        "UI Handoff Contract",
        "Bridge Handoff Contract",
        "Supplement 4.0 must not stop at",
        "Knowledge Base -> Skill Template",
    ]:
        assert marker in text


def test_supplement_4_0_agent_package_memory_and_workspace_boundaries():
    text = _read(PLAN)

    for marker in [
        "agent_package_ready = true",
        "agent_runtime_ready = false",
        "agent_executable_platform_ready = false",
        "agent_memory_runtime_ready = false",
        "multi_agent_runtime_ready = false",
        "KB + Skill -> Agent Package",
        "agent_package_ready` must not be written as `agent_executable`",
        "workspace_basic_supported = true / not_proven",
        "runtime_enforcement_ready = false",
        "agent_memory_spec_ready = true",
        "agent_short_term_redis_runtime_ready = false",
        "agent_long_term_vector_runtime_ready = false",
        "agent_memory_isolation_runtime_ready = false",
        "cross_agent_memory_leak_tests_required = true",
        "Redis config existence is not Agent short-term memory completion",
        "Vector DB config existence is not Agent long-term memory completion",
    ]:
        assert marker in text


def test_supplement_4_0_skill_and_agent_statuses_are_truthful():
    text = _read(PLAN)

    for skill_type in [
        "domain_expert_skill",
        "research_learning_skill",
        "product_business_skill",
        "operation_growth_skill",
        "literary_skill",
        "visual_video_skill",
        "general_personal_skill",
    ]:
        assert f"`{skill_type}`" in text

    for marker in [
        "skill_draft",
        "skill_generated_from_kb",
        "skill_validated",
        "skill_needs_review",
        "skill_reference_only",
        "skill_imported",
        "skill_composed",
        "skill_publish_ready",
        "agent_draft",
        "agent_package_ready",
        "agent_bound_to_kb",
        "agent_bound_to_skill",
        "agent_runtime_not_integrated",
        "agent_executable_not_ready",
        "`visual_video_skill` is one subtype only",
    ]:
        assert marker in text


def test_supplement_4_0_ui_and_bridge_handoff_do_not_complete_campaigns_4_or_5():
    text = _read(PLAN)

    for marker in [
        "UI Handoff Contract",
        "Bridge Handoff Contract",
        "future_allowlist_candidate",
        "Campaign 5 allowlist",
        "Every new allowlist action must have separate acceptance",
        "UI Handoff Contract is not Campaign 4 UI completion",
        "Bridge Handoff Contract is not Campaign 5 Bridge completion",
        "Campaigns 4-9, EXE packaging, final release",
        "`not_goal_complete = true`",
    ]:
        assert marker in text


def test_supplement_4_0_acceptance_gate_requires_full_product_handoff():
    text = _read(PLAN)

    for marker in [
        "Verified Knowledge-to-Skill passed",
        "Skill Import / Composer passed",
        "Existing Agent Package capability reconciled",
        "KB + Skill -> Agent Package passed",
        "Agent Workspace Binding Spec passed",
        "Agent Memory Isolation Spec passed",
        "Single / Multi-Agent Mode Spec passed",
        "Multi-Agent Workflow Spec passed",
        "Campaign 4 UI Handoff Contract generated",
        "Campaign 5 Bridge Handoff Contract generated",
        "Agent runtime not claimed ready",
        "Redis/Vector Agent memory runtime not claimed ready",
    ]:
        assert marker in text
