from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_readmes_are_concise_release_entrypoints():
    assert len((ROOT / "README.md").read_text(encoding="utf-8").splitlines()) <= 220
    assert len((ROOT / "README.zh-CN.md").read_text(encoding="utf-8").splitlines()) <= 240

