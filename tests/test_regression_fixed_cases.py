from heitang_kb_forge.regression.baseline import REGRESSION_BASELINE


def test_regression_baseline_covers_v16_to_v26():
    versions = [item[0] for item in REGRESSION_BASELINE]
    assert versions[0] == "v1.6"
    assert "v2.5.0-dev" in versions
    assert "v2.5.1-alpha.1" in versions
    assert "v2.7.0-alpha.1" in versions
