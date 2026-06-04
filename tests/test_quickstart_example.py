from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_quickstart_example_files_exist_and_reference_core_flow():
    sample = ROOT / "examples" / "quickstart" / "input" / "001_sample.md"
    runner = ROOT / "examples" / "quickstart" / "run_quickstart.ps1"
    expected = ROOT / "examples" / "quickstart" / "expected_outputs.md"

    assert sample.exists()
    assert runner.exists()
    assert expected.exists()
    script = runner.read_text(encoding="utf-8")
    assert "doctor" in script
    assert "build" in script
    assert "store import-package" in script
    assert "retrieve" in script
    assert "mcp export-config" in script
