import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
GOVERNANCE = DOCS / "治理"
POLICY = GOVERNANCE / "历史版本说明.md"
PLAN_LOCK = DOCS / "路线图.md"
MATRIX = GOVERNANCE / "目标验收矩阵.md"
STAGE_GATE = DOCS / "测试与验收.md"
SUPPLEMENT_3_0 = GOVERNANCE / "Campaign_1_3_总结.md"
SUPPLEMENT_4_0 = DOCS / "Skill与Agent生成说明.md"
REPO_CLEANUP = GOVERNANCE / "v4.2主分支清理清单.md"
CURRENT_RUN = ROOT / "artifacts" / "audits" / "current_run"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def _current_checkpoint() -> dict:
    checkpoint = CURRENT_RUN / "checkpoint.json"
    if not checkpoint.exists():
        return {}
    return json.loads(checkpoint.read_text(encoding="utf-8-sig"))


def test_integrated_closure_policy_exists_and_separates_4_0_from_campaign_4():
    text = _read(SUPPLEMENT_4_0) + "\n" + _read(PLAN_LOCK)

    for marker in [
        "Campaign 3 Supplement 4.0 的完整产品边界是 `Knowledge-to-Skill-to-Agent Package & Product Handoff Contract`",
        "不是 Campaign 4 UI",
        "不是 Campaign 5 Bridge",
        "Campaign 4 | Goal-Oriented Product UI Workbench",
        "Campaign 5 | Chain-Level Local Core Bridge",
    ]:
        assert marker in text


def test_post_3_0_sequence_keeps_supplement_4_0_before_stage_closure_and_campaign_4():
    combined = "\n".join(
        [
            _read(POLICY),
            _read(PLAN_LOCK),
            _read(MATRIX),
            _read(STAGE_GATE),
            _read(SUPPLEMENT_3_0),
            _read(SUPPLEMENT_4_0),
        ]
    )

    ordered_markers = [
        "Campaign 3 Supplement 3.0 External Source Memory & Verification complete",
        "Pre-4.0 Workspace Partition & Knowledge Base Access Scope Foundation Gate complete",
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff complete",
        "Campaign 3 Final Consistency Gate",
        "Campaign 1-3 Stage Test Gate passed",
        "Campaign 1-3 Integrated Closure passed",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate",
        "Repository push succeeded",
        "Baseline Tag created",
        "GitHub CI Green",
        "Closure Checklist Green",
        "Campaign 4 Entry Gate",
    ]
    for marker in ordered_markers:
        assert marker in combined

    assert "Campaign 3 Supplement 4.0 的完整产品边界" in combined
    assert "Campaign 4 allowed: `false`" in combined


def test_failures_stop_before_upload_tag_ci_and_campaign_4():
    text = _read(GOVERNANCE / "当前运行状态.md") + "\n" + _read(GOVERNANCE / "标签命名策略.md")

    for marker in [
        "不得进入 Campaign 4",
        "不得创建 GitHub Release",
        "不得创建稳定 `campaign-1-3-baseline`",
        "`campaign-1-3-baseline-rc.4`",
        "`campaign-1-3-baseline`：不得在当前任务中创建",
    ]:
        assert marker in text


def test_campaign_4_requires_full_closure_upload_tag_and_ci_green_chain():
    combined = "\n".join([_read(POLICY), _read(PLAN_LOCK), _read(MATRIX), _read(STAGE_GATE)])

    for marker in [
        "Campaign 3 Supplement 4.0 Knowledge-to-Skill-to-Agent Package & Product Handoff complete",
        "Campaign 3 Final Consistency Gate passed",
        "Campaign 1-3 Stage Test Gate passed",
        "Campaign 1-3 Integrated Closure passed",
        "Closure Pack generated",
        "Repository Public Surface Cleanup / Rename / Push-Tag Safety Gate passed",
        "Repository push succeeded",
        "Baseline Tag created",
        "GitHub CI Green",
        "Closure Checklist green",
    ]:
        assert marker.lower() in combined.lower()


def test_forbidden_misinterpretations_cover_user_correction():
    text = _read(GOVERNANCE / "当前运行状态.md") + "\n" + _read(SUPPLEMENT_4_0) + "\n" + _read(PLAN_LOCK)

    for marker in [
        "不得进入 Campaign 4",
        "Campaign 3 Supplement 4.0 的完整产品边界",
        "不是 Campaign 4 UI",
        "不是 Campaign 5 Bridge",
        "TasteSkill 或 Product Design Plugin 不属于 Campaign 4 base scope",
        "Campaign 5 是链路级 Local Core Bridge",
        "`not_goal_complete = true`",
    ]:
        assert marker in text


def test_post_ci_review_and_new_conversation_handoff_gate_respects_current_stage():
    combined = "\n".join(
        [
            _read(PLAN_LOCK),
            _read(MATRIX),
            _read(STAGE_GATE),
            _read(REPO_CLEANUP),
            _read(GOVERNANCE / "当前运行状态.md"),
        ]
    )

    for marker in [
        "v4.2 Clean Public Repository Reset only",
        "campaign-1-3-baseline-rc.4",
        "不得进入 Campaign 4",
        "不得创建 GitHub Release",
    ]:
        assert marker in combined

    final_outputs = [
        GOVERNANCE / "Campaign_1_3_总结.md",
        GOVERNANCE / "Campaign_1_3_外部项目集成审查.md",
        GOVERNANCE / "Campaign_1_3_能力矩阵.md",
        CURRENT_RUN / "new_conversation_handoff_prompt.md",
        CURRENT_RUN / "campaign_1_2_3_handoff_manifest.json",
    ]
    checkpoint = _current_checkpoint()
    if checkpoint.get("checkpoint_id") == "campaign_1_2_3_integrated_review_handoff_gate_passed":
        for final_output in final_outputs[:3]:
            assert final_output.exists(), f"{final_output} must exist after review/handoff gate"
        assert checkpoint["next_safe_action"] == "Open a new conversation and start Campaign 4 Entry Gate only"
        assert checkpoint["campaign_4_active"] is False
    else:
        tracked = _tracked_files()
        assert "artifacts/audits/current_run/new_conversation_handoff_prompt.md" not in tracked
        assert "artifacts/audits/current_run/campaign_1_2_3_handoff_manifest.json" not in tracked


def test_post_ci_review_contract_covers_external_projects_capabilities_and_release_facts():
    text = "\n".join(
        [
            _read(GOVERNANCE / "Campaign_1_3_总结.md"),
            _read(GOVERNANCE / "Campaign_1_3_外部项目集成审查.md"),
            _read(GOVERNANCE / "Campaign_1_3_能力矩阵.md"),
            _read(DOCS / "产品定位.md"),
        ]
    )

    for marker in [
        "Campaign 1-3 已形成 v4.2 产品基线",
        "Supplement 2.0 / 3.0 / Pre-4.0 / 4.0",
        "Repository cleanup / rename / push-tag safety",
        "Knowledge Package",
        "Document Outputs：Markdown / DOCX / PDF / PPTX",
    ]:
        assert marker in text

    for field in [
        "项目",
        "状态",
        "当前边界",
    ]:
        assert field in text

    for status in [
        "real_integration",
        "reference_only",
        "planned_not_active",
        "needs_verification",
        "stopped_or_rejected",
    ]:
        assert status in text

    for marker in [
        "LLM Wiki v2",
        "本地记忆分离 / Knowledge Lifecycle 能力已纳入 Core",
        "Redis / Vector DB memory store",
        "Campaign 8 future target",
        "andrej-karpathy-skills",
        "Knowledge-to-Skill methodology reference",
        "Presenton",
        "Document/PPT workflow reference",
        "CodeGraph",
        "Understand Anything",
        "LongLive",
        "不做 GPU 视频生成",
        "pi-mono",
        "claude-plugins-official",
    ]:
        assert marker in text

    for marker in [
        "Knowledge Package",
        "Document Outputs：Markdown / DOCX / PDF / PPTX",
        "Skill Outputs：Skill Template / Skill Suite",
        "Agent Creation Package",
        "Memory Separation / Knowledge Lifecycle",
        "Evidence Map / Source Trace",
        "Retrieval / Verification",
        "Workspace Partition / KB Access Scope",
        "External Source Memory & Verification",
        "Document generation",
        "Skill generation",
        "Agent package generation",
    ]:
        assert marker in text


def test_post_ci_review_forbidden_boundaries_match_user_lock():
    text = "\n".join(
        [
            _read(GOVERNANCE / "当前运行状态.md"),
            _read(GOVERNANCE / "历史版本说明.md"),
            _read(GOVERNANCE / "仓库结构规范.md"),
            _read(DOCS / "产品定位.md"),
            _read(DOCS / "路线图.md"),
        ]
    )

    for marker in [
        "Campaign 4 UI 未启动",
        "Campaign 8：Full Testing / Review",
        "EXE packaging 未启动",
        "不做 GPU 视频生成",
        "_local_dependency_remediation/",
        "不把 Redis / Vector DB future target 写成当前 runtime",
        "不把旧文件搬进 `docs/archive` 或 `artifacts/archive`",
        "push/tag/CI Green",
        "不得进入 Campaign 4",
    ]:
        assert marker in text


def _tracked_files() -> set[str]:
    import subprocess

    result = subprocess.run(["git", "ls-files"], cwd=ROOT, text=True, capture_output=True, check=True)
    return set(result.stdout.splitlines())
