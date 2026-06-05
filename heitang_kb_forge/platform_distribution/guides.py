def install_guide(platform: str) -> str:
    return (
        f"# {platform} Install Guide\n\n"
        "This package is a local platform distribution artifact.\n\n"
        "- Inspect `platform_manifest.json`.\n"
        "- Validate with `platform_upload_check_result.json`.\n"
        "- No real platform runtime is started by this guide.\n"
    )


def upload_guide(platform: str) -> str:
    return (
        f"# {platform} Upload Guide\n\n"
        "This guide describes manual upload preparation only.\n\n"
        "- No real account is used.\n"
        "- No automatic publishing is performed.\n"
        "- Use mock publish results for local validation.\n"
    )


def xhs_policy() -> str:
    return (
        "# XHS Platform Policy\n\n"
        "This is a local XHS Skill package preparation artifact. It does not log in to XHS and does not publish notes automatically.\n"
    )


def xhs_violation_checklist() -> str:
    return (
        "# XHS Violation Risk Checklist\n\n"
        "- Check claims and evidence.\n"
        "- Check promotional wording.\n"
        "- Check sensitive content.\n"
        "- Confirm human review before any manual publication.\n"
    )
