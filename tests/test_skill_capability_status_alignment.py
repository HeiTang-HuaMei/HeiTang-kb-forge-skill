import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_skill_json_capabilities_match_status_split():
    metadata = json.loads((ROOT / "skill.json").read_text(encoding="utf-8"))
    assert metadata["capabilities"] == [
        "build_knowledge_package",
        "batch_build_packages",
        "knowledge_lifecycle_check",
        "evidence_gate",
        "quality_report",
        "release_quality_gate",
        "regression_check",
        "release_blockers",
    ]
    assert "platform_distribution" in metadata["preview_capabilities"]
    assert "desktop_web_ui" in metadata["experimental_capabilities"]
    assert "saas_permissions_team_collaboration_v3x" in metadata["roadmap_capabilities"]

