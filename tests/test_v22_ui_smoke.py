from heitang_kb_forge.web.app import load_package_summary


def test_v22_web_summary_reads_gap_fill_outputs(tmp_path):
    package = tmp_path / "package"
    (package / "workspace").mkdir(parents=True)
    (package / "workspace" / "action_center.json").write_text('{"actions":[]}', encoding="utf-8")
    (package / "workspace" / "run_history.jsonl").write_text('{"status":"recorded"}\n', encoding="utf-8")
    (package / "provider_readiness").mkdir()
    (package / "provider_readiness" / "provider_readiness_result.json").write_text('{"network_required":false}', encoding="utf-8")

    summary = load_package_summary(package)

    assert summary["workspace/action_center.json"]["actions"] == []
    assert summary["workspace/run_history.jsonl"][0]["status"] == "recorded"
    assert summary["provider_readiness/provider_readiness_result.json"]["network_required"] is False
