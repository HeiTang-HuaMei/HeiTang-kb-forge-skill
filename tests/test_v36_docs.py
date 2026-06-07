import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_v36_required_docs_exist_and_reference_machine_reports():
    docs = [
        "docs/ARCHITECTURE_GAP_AUDIT.md",
        "docs/ARCHITECTURE_GAP_AUDIT.zh-CN.md",
        "docs/EXTERNAL_PROJECT_BENCHMARK.md",
        "docs/EXTERNAL_PROJECT_BENCHMARK.zh-CN.md",
        "docs/CAPABILITY_GAP_MAP.md",
        "docs/CAPABILITY_GAP_MAP.zh-CN.md",
        "docs/EXTERNAL_FUSION_PLAN.md",
        "docs/EXTERNAL_FUSION_PLAN.zh-CN.md",
    ]

    for item in docs:
        path = ROOT / item
        assert path.exists(), item
        assert path.read_text(encoding="utf-8").strip()


def test_v36_docs_explain_external_retrieval_is_validation_not_acquisition():
    architecture = (ROOT / "docs/ARCHITECTURE_GAP_AUDIT.md").read_text(encoding="utf-8")
    architecture_zh = (ROOT / "docs/ARCHITECTURE_GAP_AUDIT.zh-CN.md").read_text(encoding="utf-8")
    fusion = (ROOT / "docs/EXTERNAL_FUSION_PLAN.md").read_text(encoding="utf-8")

    assert "External Retrieval for Knowledge Accuracy Verification" in architecture
    assert "not unrestricted information acquisition" in architecture
    assert "answering from retrieval for validation" in architecture
    assert "验证现有 KB 的准确性" in architecture_zh
    assert "Use external sources to validate claims first" in fusion


def test_v36_docs_explain_local_pdf_parsing_and_token_reduction():
    architecture = (ROOT / "docs/ARCHITECTURE_GAP_AUDIT.md").read_text(encoding="utf-8")
    benchmark = (ROOT / "docs/EXTERNAL_PROJECT_BENCHMARK.md").read_text(encoding="utf-8")
    capability = (ROOT / "docs/CAPABILITY_GAP_MAP.md").read_text(encoding="utf-8")
    fusion = (ROOT / "docs/EXTERNAL_FUSION_PLAN.md").read_text(encoding="utf-8")

    assert "Raw PDF should not be sent wholesale to an LLM by default" in architecture
    assert "local parsing -> structured Markdown/JSON -> chunking -> retrieval" in architecture
    assert "Local PDF Parsing and Token Reduction Benchmark" in benchmark
    assert "LiteDoc: local browser-side PDF to Markdown" in benchmark
    assert "Local PDF parsing and token reduction capabilities" in capability
    assert "parse locally into Markdown/JSON first" in fusion


def test_v36_docs_explain_llm_is_optional_assistive_layer():
    architecture = (ROOT / "docs/ARCHITECTURE_GAP_AUDIT.md").read_text(encoding="utf-8")
    capability = (ROOT / "docs/CAPABILITY_GAP_MAP.md").read_text(encoding="utf-8")

    assert "LLM must be treated as an optional assistive layer" in architecture
    assert "not a required dependency" in architecture
    assert "Core features must remain usable without configured LLM providers" in architecture
    assert "tests_require_real_llm_api_network=false" in capability


def test_v36_json_reports_parse():
    for item in [
        "architecture_gap_audit_report.json",
        "external_project_benchmark_report.json",
        "capability_gap_map.json",
        "external_fusion_plan.json",
    ]:
        assert json.loads((ROOT / item).read_text(encoding="utf-8"))


def test_v36_docs_do_not_reference_ui_repo_dependency():
    text = "\n".join(
        (ROOT / item).read_text(encoding="utf-8")
        for item in [
            "docs/ARCHITECTURE_GAP_AUDIT.md",
            "docs/EXTERNAL_PROJECT_BENCHMARK.md",
            "docs/CAPABILITY_GAP_MAP.md",
            "docs/EXTERNAL_FUSION_PLAN.md",
        ]
    )

    assert "kb-forge-skill-ui" not in text
