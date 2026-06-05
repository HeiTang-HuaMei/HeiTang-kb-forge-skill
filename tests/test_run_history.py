import json

from heitang_kb_forge.studio_v22 import write_studio_v22_outputs


def test_studio_run_history_jsonl(tmp_path):
    write_studio_v22_outputs(tmp_path)

    rows = [json.loads(line) for line in (tmp_path / "run_history.jsonl").read_text(encoding="utf-8").splitlines()]
    assert rows[0]["status"] == "recorded"

