from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_cli_command_module_layout_exists():
    root = ROOT / "heitang_kb_forge" / "cli_commands"
    for name in [
        "common.py",
        "build_commands.py",
        "batch_commands.py",
        "pipeline_commands.py",
        "quality_commands.py",
        "release_commands.py",
        "regression_commands.py",
        "platform_commands.py",
        "provider_commands.py",
        "workspace_commands.py",
        "skill_commands.py",
        "agent_commands.py",
        "rag_commands.py",
        "doctor_commands.py",
    ]:
        assert (root / name).exists()

