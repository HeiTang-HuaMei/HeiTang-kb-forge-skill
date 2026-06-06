import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"


REQUIRED_PAGE_IDS = [
    "dashboard",
    "file-upload",
    "job-progress",
    "knowledge-base-list",
    "knowledge-base-detail",
    "review-queue",
    "corrected-text-editor",
    "kb-query",
    "document-generation",
    "agent-skill-management",
    "multi-agent-workflow",
    "memory-scope-viewer",
    "settings",
    "export-center",
]


def load_contracts():
    return json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))


def test_workbench_declares_required_pages_in_order():
    contracts = load_contracts()
    assert [page["id"] for page in contracts["pages"]] == REQUIRED_PAGE_IDS


def test_workbench_app_contains_page_routes_and_navigation_hosts():
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")
    index = (WORKBENCH / "index.html").read_text(encoding="utf-8")

    for page_id in REQUIRED_PAGE_IDS:
        assert f'id: "{page_id}"' in app or f'"{page_id}":' in app

    assert 'id="nav-list"' in index
    assert 'id="mobile-page-select"' in index
    assert 'data-testid="workbench-app"' in index


def test_workbench_specs_cover_required_pages():
    english_spec = (ROOT / "docs" / "WORKBENCH_UI_SPEC.md").read_text(encoding="utf-8")
    chinese_spec = (ROOT / "docs" / "WORKBENCH_UI_SPEC.zh-CN.md").read_text(encoding="utf-8")

    for heading in [
        "Dashboard",
        "File Upload",
        "Job Progress",
        "Knowledge Base List",
        "Knowledge Base Detail",
        "Review Queue",
        "Corrected Text Editor",
        "KB Query",
        "Document Generation",
        "Agent / Skill Management",
        "Multi-Agent Workflow",
        "Memory Scope Viewer",
        "Settings",
        "Export Center",
    ]:
        assert heading in english_spec

    for heading in [
        "仪表盘",
        "文件上传",
        "任务进度",
        "知识库列表",
        "知识库详情",
        "复核队列",
        "校正文稿编辑器",
        "知识库查询",
        "文档生成",
        "Agent / Skill 管理",
        "多 Agent 工作流",
        "记忆范围查看器",
        "设置",
        "导出中心",
    ]:
        assert heading in chinese_spec
