from pathlib import Path

from heitang_kb_forge.audit.report_writer import write_v36_audit_outputs


ROOT = Path(__file__).resolve().parents[1]


def test_v36_audit_outputs_remain_generatable_without_kept_root_artifacts(tmp_path):
    written = write_v36_audit_outputs(tmp_path)
    names = {path.relative_to(tmp_path).as_posix() for path in written}

    assert "architecture_gap_audit_report.json" in names
    assert "external_project_benchmark_report.json" in names
    assert "capability_gap_map.json" in names
    assert "external_fusion_plan.json" in names
    assert "docs/ARCHITECTURE_GAP_AUDIT.md" in names
    assert "docs/EXTERNAL_FUSION_PLAN.md" in names


def test_v36_historical_docs_are_not_kept_on_main():
    governance = (ROOT / "docs" / "治理" / "历史版本说明.md").read_text(encoding="utf-8")

    for relative in [
        "docs/ARCHITECTURE_GAP_AUDIT.md",
        "docs/EXTERNAL_PROJECT_BENCHMARK.md",
        "docs/CAPABILITY_GAP_MAP.md",
        "docs/EXTERNAL_FUSION_PLAN.md",
        "architecture_gap_audit_report.json",
        "external_project_benchmark_report.json",
        "capability_gap_map.json",
        "external_fusion_plan.json",
    ]:
        assert not (ROOT / relative).exists(), relative

    assert "旧 Campaign 中间证据" in governance
    assert "根目录旧 JSON" in governance
