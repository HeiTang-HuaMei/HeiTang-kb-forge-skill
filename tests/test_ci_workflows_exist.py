from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_ci_and_release_check_workflows_are_local_and_offline_safe():
    ci = (ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
    release = (ROOT / ".github" / "workflows" / "release-check.yml").read_text(encoding="utf-8")
    assert 'python -m pip install -e ".[dev]"' in ci
    assert "python -m pytest" in ci
    assert "doctor --output ./tmp_doctor" in release
    assert "tmp_quickstart_output/manifest.json" in release
    assert "quality-gate --workspace ./tmp_release_workspace" in release
    assert "validate-golden-samples --workspace ./tmp_release_golden_samples" in release
    assert "certify-export --export ./tmp_platform_export" in release
    assert "release-readiness --workspace ." in release
    assert "r['release_ready'] is True" in release
    assert "curl " not in release
    assert "Invoke-WebRequest" not in release
