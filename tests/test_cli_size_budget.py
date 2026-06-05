from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_cli_entrypoint_is_under_first_phase_size_budget():
    assert (ROOT / "heitang_kb_forge" / "cli.py").stat().st_size < 5_000
    legacy = ROOT / "heitang_kb_forge" / "cli_commands" / "legacy.py"
    assert not legacy.exists() or legacy.stat().st_size < 10_000
    for path in (ROOT / "heitang_kb_forge" / "cli_commands").glob("*.py"):
        assert path.stat().st_size < 30_000
