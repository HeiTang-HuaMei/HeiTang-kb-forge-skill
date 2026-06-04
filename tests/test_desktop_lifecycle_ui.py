from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DESKTOP = ROOT / "desktop" / "tauri"


def test_lifecycle_page_reserves_required_files_and_actions():
    page = (DESKTOP / "src" / "pages" / "LifecycleUpdate.tsx").read_text(encoding="utf-8")
    for text in [
        "source_registry.json",
        "source_change_report.md",
        "changed_sources.jsonl",
        "missing_sources.jsonl",
        "incremental_update_report.md",
        "update_quality_gate_report.json",
        "quality_regression_report.md",
        "retry_manifest.json",
        "notice.futureLifecycle",
    ]:
        assert text in page


def test_settings_reserves_storage_vector_and_agent_connector():
    page = (DESKTOP / "src" / "pages" / "Settings.tsx").read_text(encoding="utf-8")
    i18n = (DESKTOP / "src" / "i18n.ts").read_text(encoding="utf-8")
    for text in [
        "knowledgeStoreBackend",
        "vectorStoreBackend",
        "qdrant_future",
        "milvus_future",
        "agentTarget",
        "connectorMode",
        "mcp_server_future",
        "custom_agent_api_future",
        "知识库存储后端",
        "向量库后端",
        "Agent 对接目标",
    ]:
        assert text in page or text in i18n
