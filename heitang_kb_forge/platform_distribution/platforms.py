SUPPORTED_PLATFORMS = ["openclaw", "xhs", "codex", "claude_code", "mcp", "generic", "local_registry"]


def expand_platforms(platform: str) -> list[str]:
    if platform == "all":
        return list(SUPPORTED_PLATFORMS)
    if platform not in SUPPORTED_PLATFORMS:
        raise ValueError(f"Unsupported platform: {platform}")
    return [platform]


def required_files(platform: str) -> list[str]:
    base = [
        "platform_manifest.json",
        "platform_upload_check_result.json",
        "platform_upload_check_report.md",
        "mock_publish_result.json",
        "install_guide.md",
        "upload_guide.md",
    ]
    if platform == "xhs":
        base.extend(
            [
                "xhs_skill_manifest.json",
                "xhs_skill_link_manifest.json",
                "platform_policy.md",
                "violation_risk_checklist.md",
            ]
        )
    return base
