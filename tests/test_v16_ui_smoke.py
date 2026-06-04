import json

from heitang_kb_forge.web.app import load_package_summary


def test_web_package_summary_loads_multimodal_and_contract_outputs(tmp_path):
    package = tmp_path / "package"
    package.mkdir()
    (package / "manifest.json").write_text(json.dumps({"contract_version": "2.0"}), encoding="utf-8")
    (package / "contract_check_result.json").write_text(json.dumps({"status": "pass"}), encoding="utf-8")
    (package / "multimodal_assets.jsonl").write_text(json.dumps({"asset_id": "asset_1", "review_required": True}) + "\n", encoding="utf-8")
    (package / "multimodal_report.md").write_text("# Multimodal Report\n", encoding="utf-8")
    (package / "contract_check_report.md").write_text("# Contract Check Report\n", encoding="utf-8")

    summary = load_package_summary(package)

    assert summary["manifest.json"]["contract_version"] == "2.0"
    assert summary["contract_check_result.json"]["status"] == "pass"
    assert summary["multimodal_asset_count"] == 1
    assert len(summary["review_required_assets"]) == 1
