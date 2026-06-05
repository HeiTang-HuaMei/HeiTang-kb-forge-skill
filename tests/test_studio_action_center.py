import json

from heitang_kb_forge.studio_v22 import write_studio_v22_outputs


def test_studio_action_center_outputs(tmp_path):
    write_studio_v22_outputs(tmp_path)

    actions = json.loads((tmp_path / "action_center.json").read_text(encoding="utf-8"))
    assert actions["action_center_version"] == "2.2"
    assert (tmp_path / "studio_v22_summary.json").exists()

