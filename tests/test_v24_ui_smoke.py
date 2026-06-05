from heitang_kb_forge.web.app import load_package_summary


def test_v24_web_summary_reads_platform_distribution_outputs(tmp_path):
    package = tmp_path / "package"
    platform = package / "platform_distribution"
    platform.mkdir(parents=True)
    (platform / "platform_manifest.json").write_text('{"platform":"generic"}', encoding="utf-8")
    (platform / "mock_publish_result.json").write_text('{"real_upload_performed":false}', encoding="utf-8")

    summary = load_package_summary(package)

    assert summary["platform_distribution/platform_manifest.json"]["platform"] == "generic"
    assert summary["platform_distribution/mock_publish_result.json"]["real_upload_performed"] is False
