from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_cli_architecture_docs_define_future_command_rules():
    english = (ROOT / "docs" / "CLI_ARCHITECTURE.md").read_text(encoding="utf-8")
    chinese = (ROOT / "docs" / "CLI_ARCHITECTURE.zh-CN.md").read_text(encoding="utf-8")

    for text in [english, chinese]:
        assert "4.0.0rc1" in text
        assert "v4.0.0-rc.1" in text
        assert "cli.py" in text
        assert "cli_commands" in text
        assert "30 KB" in text
        assert "legacy.py" in text
        assert "release-readiness" in text


