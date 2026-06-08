from heitang_kb_forge.multi_source_ingestion import INGESTION_MODES, SOURCE_TYPES
from tests.multi_source_helpers import make_multi_source_run, read_json


def test_multi_source_ingestion_schema_and_required_reports(tmp_path):
    output = make_multi_source_run(tmp_path)

    assert {"official_api", "user_export", "manual_upload", "local_file", "opencli_bridge"} <= INGESTION_MODES
    assert {
        "x_post_export",
        "x_thread_export",
        "newsletter_export",
        "blog_article",
        "github_markdown",
        "youtube_transcript",
        "podcast_transcript",
        "forum_post",
        "exported_chat",
        "local_note",
        "document",
        "manual_source",
    } <= SOURCE_TYPES

    report = read_json(output / "multi_source_ingestion_report.json")
    assert report["status"] == "pass"
    assert report["hidden_scraping_implemented"] is False
    assert report["crawler_or_scraper_marketing"] is False
    assert report["tests_require_real_llm_api_network"] is False

    for name in report["reports"]:
        assert (output / name).exists(), name
