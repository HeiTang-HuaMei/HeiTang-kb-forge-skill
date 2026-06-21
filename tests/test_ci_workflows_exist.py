from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_ci_and_release_check_workflows_are_local_and_offline_safe():
    ci = (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
    release = (ROOT / ".github" / "workflows" / "release-check.yml").read_text(encoding="utf-8")
    assert 'python -m pip install -e ".[dev]"' in ci
    assert "python -m pytest" in ci
    assert "doctor --output ./tmp_doctor" in release
    assert "tmp_quickstart_output/manifest.json" in release
    assert "release-readiness --workspace ." in release
    assert "curl " not in release
    assert "Invoke-WebRequest" not in release


def test_github_governance_surface_exists():
    required = [
        ".github/workflows/pr-fast-gate.yml",
        ".github/workflows/nightly-full-gate.yml",
        ".github/workflows/rc-candidate-gate.yml",
        ".github/workflows/release-gate.yml",
        ".github/workflows/docs-check.yml",
        ".github/workflows/security-scan.yml",
        ".github/pull_request_template.md",
        ".github/CODEOWNERS",
        ".github/dependabot.yml",
        ".github/ISSUE_TEMPLATE/bug_report.yml",
        ".github/ISSUE_TEMPLATE/capability_gap.yml",
        ".github/ISSUE_TEMPLATE/owner_retest_failure.yml",
        ".github/ISSUE_TEMPLATE/external_project_verification.yml",
        ".github/ISSUE_TEMPLATE/release_blocker.yml",
        "docs/current/CURRENT_PRODUCT_BASELINE.md",
        "docs/product/PRODUCT_ARCHITECTURE.md",
        "docs/product/PRD.md",
        "docs/product/FEATURE_ACCEPTANCE_MATRIX.md",
        "docs/governance/BRANCH_POLICY.md",
        "docs/governance/TAG_POLICY.md",
        "docs/governance/RELEASE_POLICY.md",
        "docs/governance/EXTERNAL_PROJECT_REGISTRY.md",
        "docs/governance/MODEL_GATEWAY_PROVIDER_POLICY.md",
        "docs/governance/OWNER_RETEST_POLICY.md",
    ]

    for path in required:
        assert (ROOT / path).exists(), path

    baseline = (ROOT / "docs" / "current" / "CURRENT_PRODUCT_BASELINE.md").read_text(encoding="utf-8")
    assert "PRODUCT_ARCHITECTURE_V3_2026-06-19.md" in baseline
    assert "PRD_V3_2026-06-19.md" in baseline
    assert "FEATURE_ACCEPTANCE_MATRIX_V3_2026-06-19.md" in baseline

