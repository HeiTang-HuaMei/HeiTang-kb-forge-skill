from heitang_kb_forge.web.app import load_package_summary


def test_v25_web_summary_reads_release_quality_outputs(tmp_path):
    package = tmp_path / "package"
    package.mkdir()
    (package / "quality_gate_result.json").write_text('{"status":"warning","release_ready":false}', encoding="utf-8")
    (package / "release_readiness_result.json").write_text('{"status":"warning","release_ready":false}', encoding="utf-8")
    (package / "compatibility_matrix.json").write_text('{"status":"pass","objects":[]}', encoding="utf-8")
    (package / "quality_gate_report.md").write_text("# Quality Gate", encoding="utf-8")

    summary = load_package_summary(package)

    assert summary["quality_gate_result.json"]["status"] == "warning"
    assert summary["release_readiness_result.json"]["release_ready"] is False
    assert summary["compatibility_matrix.json"]["status"] == "pass"
    assert "Quality Gate" in summary["quality_gate_report.md"]

