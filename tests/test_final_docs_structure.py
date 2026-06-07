from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_required_documentation_structure_exists():
    required = [
        "docs/DOCS_INDEX.md",
        "docs/DOCS_INDEX.zh-CN.md",
        "docs/VERSION_MATRIX.md",
        "docs/VERSION_MATRIX.zh-CN.md",
        "docs/USER_MANUAL.md",
        "docs/USER_MANUAL.zh-CN.md",
        "docs/COMMAND_REFERENCE.md",
        "docs/COMMAND_REFERENCE.zh-CN.md",
        "docs/OUTPUT_REPORT_GUIDE.md",
        "docs/OUTPUT_REPORT_GUIDE.zh-CN.md",
        "docs/LOCAL_PRIVACY_SECURITY.md",
        "docs/LOCAL_PRIVACY_SECURITY.zh-CN.md",
        "docs/TROUBLESHOOTING.md",
        "docs/TROUBLESHOOTING.zh-CN.md",
        "docs/GOLDEN_DEMO_GUIDE.md",
        "docs/GOLDEN_DEMO_GUIDE.zh-CN.md",
        "docs/ARCHITECTURE.md",
        "docs/ARCHITECTURE.zh-CN.md",
    ]
    for relative in required:
        path = ROOT / relative
        assert path.exists(), relative
        assert path.stat().st_size > 0, relative
