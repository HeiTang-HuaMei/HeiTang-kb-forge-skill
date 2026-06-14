from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "治理"


def _read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def test_v4_2_public_sequence_lock_is_expressed_in_chinese_governance_docs():
    required = [
        GOVERNANCE / "当前运行状态.md",
        GOVERNANCE / "目标验收矩阵.md",
        GOVERNANCE / "标签命名策略.md",
        GOVERNANCE / "仓库结构规范.md",
        GOVERNANCE / "v4.2主分支清理清单.md",
        GOVERNANCE / "4.2之前版本残留清理映射表.md",
    ]
    for path in required:
        assert path.exists(), path


def test_current_next_action_is_rc4_validation_not_campaign_4_or_release():
    text = _read(GOVERNANCE / "当前运行状态.md") + "\n" + _read(GOVERNANCE / "标签命名策略.md")

    assert "campaign-1-3-baseline-rc.4" in text
    assert "不得进入 Campaign 4" in text
    assert "不得创建 GitHub Release" in text
    assert "不得创建稳定 `campaign-1-3-baseline`" in text


def test_campaign_4_and_5_remain_inactive_after_cleanup():
    text = _read(GOVERNANCE / "当前运行状态.md") + "\n" + _read(GOVERNANCE / "目标验收矩阵.md")

    assert "Campaign 4 active：false" in text
    assert "Campaign 4 未启动" in text
    assert "Campaign 5 未启动" in text
    assert "当前任务只允许完成 v4.2 Clean Public Repository Reset" in text
    assert "EXE packaging 未启动" in text


def test_target_acceptance_matrix_keeps_four_product_outputs_distinct():
    text = _read(GOVERNANCE / "目标验收矩阵.md")

    for phrase in [
        "Knowledge Package",
        "Document Outputs",
        "Markdown / DOCX / PDF / PPTX",
        "Skill Outputs",
        "Agent Creation Package",
    ]:
        assert phrase in text
    assert "不是 Agent Runtime ready" in text


def test_old_plan_lock_docs_are_removed_from_tracked_public_surface():
    tracked = _tracked_files()
    forbidden = [
        "docs/governance/PLAN_SEQUENCE_LOCK.md",
        "docs/governance/TARGET_ACCEPTANCE_MATRIX.md",
        "docs/testing/VALIDATION_GATE_MANIFEST.json",
    ]
    for path in forbidden:
        assert path not in tracked


def _tracked_files() -> set[str]:
    import subprocess

    result = subprocess.run(["git", "ls-files"], cwd=ROOT, text=True, capture_output=True, check=True)
    return set(result.stdout.splitlines())
