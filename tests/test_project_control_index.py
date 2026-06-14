from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GOVERNANCE = ROOT / "docs" / "治理"


def test_project_control_surface_is_chinese_and_concise():
    expected = {
        "当前运行状态.md",
        "目标验收矩阵.md",
        "标签命名策略.md",
        "Campaign_1_3_总结.md",
        "Campaign_1_3_能力矩阵.md",
        "Campaign_1_3_外部项目集成审查.md",
        "历史版本说明.md",
        "仓库结构规范.md",
        "归档说明.md",
    }
    present = {path.name for path in GOVERNANCE.glob("*.md")}
    assert expected <= present


def test_project_control_index_replacement_preserves_forbidden_actions():
    text = "\n".join(path.read_text(encoding="utf-8") for path in GOVERNANCE.glob("*.md"))

    for phrase in [
        "不得进入 Campaign 4",
        "不得创建 GitHub Release",
        "不得创建稳定 `campaign-1-3-baseline`",
        "Campaign 5 未启动",
        "LongLive",
        "不做 GPU 视频生成",
    ]:
        assert phrase in text


def test_public_control_surface_does_not_reintroduce_legacy_directories():
    tracked = _tracked_files()
    for prefix in [
        "docs/governance/",
        "docs/testing/",
        "docs/product/",
        "docs/bridge/",
        "docs/roadmap/",
    ]:
        assert not any(path.startswith(prefix) for path in tracked)


def _tracked_files() -> set[str]:
    import subprocess

    result = subprocess.run(["git", "ls-files"], cwd=ROOT, text=True, capture_output=True, check=True)
    return set(result.stdout.splitlines())
