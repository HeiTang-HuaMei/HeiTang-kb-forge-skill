import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = ROOT / "docs" / "roadmap" / "external_projects" / "external_project_registry.json"
ROADMAP_ZH = ROOT / "docs" / "roadmap" / "external_projects" / "POST_V4_EXTERNAL_ROADMAP.zh-CN.md"


def _registry() -> dict:
    return json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))


def test_post_v4_roadmap_contains_ordering_rule():
    text = ROADMAP_ZH.read_text(encoding="utf-8")

    assert "强化功能优先" in text
    assert "加强体验第二" in text
    assert "生态拓展后置" in text
    assert "function strengthening first, experience second, ecosystem later" in text


def test_post_v4_roadmap_limits_each_p2_stage_to_two_s_a_directions():
    phases = _registry()["post_v4_roadmap"]
    p2_phases = [phase for phase in phases if phase["phase"].startswith("P2.")]

    assert {phase["phase"] for phase in p2_phases} == {
        "P2.1",
        "P2.2",
        "P2.3",
        "P2.4",
        "P2.5",
        "P2.6",
        "P2.7",
        "P2.8",
        "P2.9",
    }
    for phase in p2_phases:
        if phase["phase"] == "P2.1":
            continue
        assert len(phase["primary_s_a_directions"]) <= 2


def test_post_v4_roadmap_keeps_registry_as_pre_v4_only():
    payload = _registry()

    assert payload["external_features_implemented"] is False
    assert payload["planned_adapters_marked_ready"] is False
    assert payload["v4_0_started"] is False
    assert payload["tag_created"] is False
    assert payload["release_written"] is False
