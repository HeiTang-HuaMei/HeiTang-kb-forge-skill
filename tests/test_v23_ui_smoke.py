from heitang_kb_forge.web.app import load_package_summary


def test_v23_web_summary_reads_batch_governance_outputs(tmp_path):
    package = tmp_path / "package"
    package.mkdir()
    (package / "batch_job_manifest.json").write_text('{"total_items":1}', encoding="utf-8")
    (package / "batch_item_status.jsonl").write_text('{"item_id":"001","status":"success"}\n', encoding="utf-8")
    (package / "impacted_skills.json").write_text('{"skills":[]}', encoding="utf-8")

    summary = load_package_summary(package)

    assert summary["batch_job_manifest.json"]["total_items"] == 1
    assert summary["batch_item_status.jsonl"][0]["status"] == "success"
    assert summary["impacted_skills.json"]["skills"] == []
