from heitang_kb_forge.platform_distribution.platforms import required_files


def test_export_certification_required_files_include_mock_and_platform_boundaries():
    assert "mock_publish_result.json" in required_files("generic")
    assert "platform_policy.md" in required_files("xhs")
    assert "mcp_manifest.json" in required_files("mcp")
    assert "codex_instructions.md" in required_files("codex")

