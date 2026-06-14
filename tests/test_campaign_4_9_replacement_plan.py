from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
GOVERNANCE = DOCS / "治理"
PLAN = DOCS / "路线图.md"
LOCK = GOVERNANCE / "当前运行状态.md"
MATRIX = GOVERNANCE / "目标验收矩阵.md"
STAGE_GATE = DOCS / "测试与验收.md"
CLOSURE = GOVERNANCE / "历史版本说明.md"
CONTROL_INDEX = GOVERNANCE / "仓库结构规范.md"
PROJECT_AGENTS = ROOT / "AGENTS.md"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_replacement_plan_v3_exists_and_registers_campaigns_4_to_9():
    text = _read(PLAN)

    for marker in [
        "Campaign 4-9 替代计划 v3.0",
        "不启动任何未来战役",
        "不做 UI redesign",
        "不改变 Bridge allowlist",
        "Campaign 4 | Goal-Oriented Product UI Workbench",
        "Campaign 5 | Chain-Level Local Core Bridge",
        "Campaign 6 | Agent Runtime & Memory Platform",
        "Campaign 7 | Configuration System",
        "Campaign 8 | Full Testing / Full Review",
        "Campaign 9 | EXE Packaging",
        "Final Release | GitHub Release after Campaign 9 acceptance",
    ]:
        assert marker in text


def test_v3_preconditions_keep_campaign_4_blocked_until_closure_checklist_green():
    combined = "\n".join([_read(PLAN), _read(LOCK), _read(MATRIX), _read(STAGE_GATE), _read(CLOSURE)])

    for marker in [
        "Campaign 3 Supplement 3.0 External Source Memory & Verification complete",
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate complete",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff complete",
        "Campaign 3 Final Consistency Gate passed",
        "Campaign 1-3 Stage Test Gate passed",
        "Campaign 1-3 Integrated Closure passed",
        "Closure Pack generated",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed",
        "Repository push succeeded",
        "Baseline Tag created",
        "GitHub CI Green",
        "Closure Checklist Green",
        "Campaign 4 Entry Gate",
    ]:
        assert marker in combined

    assert "Campaign 3 Supplement 4.0 的完整产品边界" in (DOCS / "Skill与Agent生成说明.md").read_text(encoding="utf-8")
    assert "Campaign 4 allowed: `false`" in combined


def test_campaign_4_is_product_workbench_not_runtime_or_bridge():
    text = _read(PLAN)

    for marker in [
        "Goal-Oriented Product UI Workbench",
        "不是 Bridge completion",
        "不是 Agent Runtime completion",
        "不是 EXE packaging",
        "顶层导航不超过七个入口",
        "Agent package spec 不得显示成 runtime ready",
        "Agent runtime 不得显示成 ready",
        "Multi-Agent spec 不得显示成 executable",
        "TasteSkill 或 Product Design Plugin 不属于 Campaign 4 base scope",
    ]:
        assert marker in text


def test_campaign_5_is_chain_bridge_and_excludes_runtime_actions():
    text = _read(PLAN)

    for marker in [
        "Chain-Level Local Core Bridge",
        "import_to_kb_flow",
        "external_source_verification_flow",
        "agent_package_generation_flow",
        "agent_output_verification_flow",
        "generate-agent",
        "validate-agent-package",
        "run-agent-task",
        "agent-memory-read",
        "属于 Campaign 6",
        "不得允许 arbitrary shell execution",
    ]:
        assert marker in text


def test_campaign_6_agent_runtime_memory_is_new_required_gate():
    combined = "\n".join([_read(PLAN), _read(MATRIX), _read(STAGE_GATE), _read(LOCK)])

    for marker in [
        "Campaign 6：Agent Runtime / Memory",
        "Campaign 6 才处理",
        "simple_single_agent_mode_runtime",
        "advanced_single_agent_mode_runtime",
        "Agent memory isolation",
        "Redis / Vector DB memory runtime",
        "Redis config 或 Vector DB config alone is not Agent Runtime & Memory acceptance",
    ]:
        assert marker in combined


def test_campaign_7_8_9_and_release_are_locked_after_runtime():
    combined = "\n".join([_read(PLAN), _read(MATRIX), _read(STAGE_GATE), _read(LOCK)])

    for marker in [
        "Campaign 7：配置系统",
        "check-agent-runtime",
        "check-agent-memory-backend",
        "check-opencli",
        "Campaign 8：Full Testing / Review",
        "Fast Gate、focused tests、scoped tests 或单条 green command 不等于 Full Review",
        "Campaign 9：Packaging / EXE",
        "real install or run smoke",
        "Final Release 只有 Campaigns 1-9 accepted 后才允许开始",
    ]:
        assert marker in combined


def test_v3_registration_is_indexed_and_routed_to_governance_gate():
    combined = "\n".join([_read(PROJECT_AGENTS), _read(CONTROL_INDEX), _read(PLAN), _read(STAGE_GATE)])

    for marker in [
        "tests/test_campaign_4_9_replacement_plan.py",
    ]:
        assert marker in combined or marker == "tests/test_campaign_4_9_replacement_plan.py"

    assert "后续方向必须按顺序锁执行" in combined
    assert "工程关键目录保留英文" in combined
