import json
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WORKBENCH = ROOT / "web" / "workbench"


REQUIRED_PAGE_IDS = [
    "dashboard",
    "workspace",
    "operation-gate",
    "capability-matrix",
    "import-parsing",
    "knowledge-package-management",
    "retrieval-verification",
    "vector-hub-provider-storage",
    "document-generation",
    "skill-factory",
    "agent-factory-runtime",
    "memory-center",
    "task-job-center",
    "artifact-management",
    "error-repair-center",
    "reports-audit",
    "governance",
    "template-library",
]


def load_contracts():
    return json.loads((WORKBENCH / "contracts.json").read_text(encoding="utf-8"))


def test_workbench_declares_required_pages_in_order():
    contracts = load_contracts()
    assert [page["id"] for page in contracts["pages"]] == REQUIRED_PAGE_IDS


def test_workbench_app_contains_page_routes_and_navigation_hosts():
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")
    index = (WORKBENCH / "index.html").read_text(encoding="utf-8")
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")

    for page_id in REQUIRED_PAGE_IDS:
        assert f'id: "{page_id}"' in app or f'"{page_id}":' in app
        assert re.search(rf"WorkbenchPage\(\s*'{re.escape(page_id)}'", flutter_main)

    assert 'id="nav-list"' in index
    assert 'id="mobile-page-select"' in index
    assert 'data-testid="workbench-app"' in index


def test_flutter_scaffold_declares_all_required_pages_once():
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")

    assert len(re.findall(r"WorkbenchPage\(\s*'", flutter_main)) == len(REQUIRED_PAGE_IDS)
    for page_id in REQUIRED_PAGE_IDS:
        assert f"'{page_id}'" in flutter_main


def test_workbench_specs_cover_required_pages():
    app = (WORKBENCH / "src" / "app.js").read_text(encoding="utf-8")
    flutter_main = (WORKBENCH / "flutter_app" / "lib" / "main.dart").read_text(encoding="utf-8")

    for heading in [
        "Dashboard",
        "Workspace",
        "Import & Parsing",
        "Knowledge Package Management",
        "Retrieval & Verification",
        "Vector Hub / Provider / Storage",
        "Document Generation",
        "Skill Factory",
        "Agent Factory & Runtime",
        "Reports & Audit",
        "Task / Job Center",
        "Artifact Management",
    ]:
        assert heading in app or heading in flutter_main

    for heading in [
        "仪表盘",
        "工作空间",
        "导入与解析",
        "知识包管理",
        "检索与验证",
        "文档生成",
        "报表与审计",
    ]:
        assert heading in app or heading in flutter_main
