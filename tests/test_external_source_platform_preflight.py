import json
from pathlib import Path

from typer.testing import CliRunner

from heitang_kb_forge.cli_runtime import app
from heitang_kb_forge.external_sources import (
    detect_platform_link,
    preflight_platform_links,
    validate_platform_preflight,
)


def _json(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path: Path) -> list[dict]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def test_detect_platform_link_identifies_required_platforms():
    cases = {
        "https://www.xiaohongshu.com/explore/abc": "xiaohongshu",
        "https://v.douyin.com/abc": "douyin",
        "https://www.zhihu.com/question/1/answer/2": "zhihu",
        "https://www.bilibili.com/video/BV123": "bilibili",
        "https://mp.weixin.qq.com/s/example": "wechat_public_article",
        "https://weibo.com/123/abc": "weibo",
        "https://example.com/post": "other_or_unknown_platform",
    }

    for url, platform in cases.items():
        detection = detect_platform_link(url)
        assert detection["platform"] == platform
        assert detection["is_platform_link"] is True


def test_platform_preflight_records_structured_states_without_fetch_or_overclaim(tmp_path):
    urls = [
        "https://www.xiaohongshu.com/explore/abc",
        "https://v.douyin.com/abc",
        "https://www.zhihu.com/question/1/answer/2",
        "https://www.bilibili.com/video/BV123",
        "https://mp.weixin.qq.com/s/example",
        "https://weibo.com/123/abc",
        "https://example.com/post",
    ]

    result = preflight_platform_links(
        tmp_path / "out",
        urls=urls,
        checked_at="2026-06-13T00:00:00+08:00",
    )
    validation = validate_platform_preflight(tmp_path / "out")
    report = _json(tmp_path / "out" / "platform_preflight_report.json")
    next_paths = _json(tmp_path / "out" / "platform_next_paths.json")
    visible = _jsonl(tmp_path / "out" / "platform_visible_content.jsonl")
    run = _json(tmp_path / "out" / "run_manifest.json")

    assert result["status"] == "passed"
    assert validation["status"] == "passed"
    assert validation["boundary_errors"] == []
    assert report["integration_decision"] == "real_integration"
    assert report["decision_qualifier"] == "platform_preflight_only"
    assert report["runtime_boundary"]["platform_link_preflight_implemented"] is True
    assert report["runtime_boundary"]["opencli_runtime_integrated"] is False
    assert report["runtime_boundary"]["manual_evidence_processing_implemented"] is False
    assert report["runtime_boundary"]["campaign_3_3_0_accepted"] is False
    assert report["runtime_boundary"]["campaign_4_allowed"] is False
    assert report["safety_boundary"]["content_fetch_forbidden_in_this_step"] is True
    assert report["safety_boundary"]["no_cookie_import"] is True
    assert report["safety_boundary"]["no_anti_detection_behavior"] is True
    by_platform = {item["platform"]: item for item in report["records"]}
    assert by_platform["xiaohongshu"]["readability_state"] == "auth_required"
    assert by_platform["douyin"]["readability_state"] == "video_without_transcript"
    assert by_platform["zhihu"]["readability_state"] == "partial_readable"
    assert by_platform["bilibili"]["readability_state"] == "video_without_transcript"
    assert by_platform["wechat_public_article"]["readability_state"] == "partial_readable"
    assert by_platform["weibo"]["readability_state"] == "login_required"
    assert by_platform["other_or_unknown_platform"]["readability_state"] == "needs_opencli_verification"
    assert all(item["content_fetched"] is False for item in report["records"])
    assert all(item["content_extracted"] is False for item in report["records"])
    assert all(item["cookies_saved"] is False for item in report["records"])
    assert all(item["failure_reason"] for item in report["records"])
    assert next_paths["sources"][0]["next_available_paths"]
    assert visible == []
    assert run["campaign_state_after_run"]["platform_preflight_implemented"] is True
    assert run["campaign_state_after_run"]["opencli_runtime_integrated"] is False
    assert run["campaign_state_after_run"]["campaign_3_3_0_accepted"] is False
    assert run["campaign_state_after_run"]["next_business_item"] == (
        "Campaign 3 Supplement 3.0 P0 OpenCLI External Search Verification"
    )
    assert run["not_goal_complete"] is True


def test_platform_preflight_validation_rejects_runtime_or_safety_drift(tmp_path):
    output = tmp_path / "out"
    preflight_platform_links(
        output,
        urls=["https://www.xiaohongshu.com/explore/abc"],
    )
    report_path = output / "platform_preflight_report.json"
    report = _json(report_path)
    report["runtime_boundary"]["opencli_runtime_integrated"] = True
    report["records"][0]["content_fetched"] = True
    report["safety_boundary"]["no_cookie_import"] = False
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    validation = validate_platform_preflight(output)

    assert validation["status"] == "failed"
    assert "opencli_runtime_integrated_must_be_false" in validation["boundary_errors"]
    assert "content_fetched_must_be_false" in validation["boundary_errors"]
    assert "no_cookie_import_must_be_true" in validation["boundary_errors"]


def test_platform_preflight_cli_writes_reports(tmp_path):
    runner = CliRunner()

    preflight_result = runner.invoke(
        app,
        [
            "preflight-platform-link",
            "https://www.bilibili.com/video/BV123",
            "https://weibo.com/123/abc",
            "--output",
            str(tmp_path / "library"),
        ],
    )
    validation_result = runner.invoke(
        app,
        [
            "validate-platform-preflight",
            "--library",
            str(tmp_path / "library"),
            "--output",
            str(tmp_path / "validation"),
        ],
    )

    assert preflight_result.exit_code == 0, preflight_result.output
    assert "status=passed" in preflight_result.output
    assert validation_result.exit_code == 0, validation_result.output
    assert "status=passed" in validation_result.output
    assert _json(tmp_path / "validation" / "platform_preflight_validation_report.json")[
        "status"
    ] == "passed"
