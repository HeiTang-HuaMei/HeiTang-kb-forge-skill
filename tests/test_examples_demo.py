from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def test_portfolio_demo_directories_exist():
    demos = [
        "demo_product_manager_agent",
        "demo_shopping_guide_agent",
        "demo_education_tutor_agent",
    ]

    for demo in demos:
        demo_dir = ROOT / "examples" / demo
        assert demo_dir.exists()
        assert (demo_dir / "input").exists()
        assert (demo_dir / "README_demo.md").exists()
        assert (demo_dir / "run_demo.ps1").exists()


def test_product_manager_demo_output_sample_exists():
    output = ROOT / "examples" / "demo_product_manager_agent" / "output_sample"

    required_files = [
        "demo_report.md",
        "demo_manifest.json",
        "eval_summary.json",
        "agent_profile.yaml",
        "system_prompt.md",
        "retrieval_config.yaml",
        "tools.yaml",
        "eval_cases.jsonl",
        "rag_manifest.json",
        "embedding_input.jsonl",
        "retrieval_metadata.jsonl",
        "citation_map.json",
        "quality_report.json",
        "manifest.json",
    ]

    for name in required_files:
        assert (output / name).exists()


def test_demo_directories_do_not_include_cache_or_temp_files():
    examples = ROOT / "examples"
    demo_dirs = [
        examples / "demo_product_manager_agent",
        examples / "demo_shopping_guide_agent",
        examples / "demo_education_tutor_agent",
    ]

    forbidden_fragments = [
        ".heitang_cache",
        "__pycache__",
    ]
    forbidden_suffixes = {
        ".tmp",
        ".log",
        ".pyc",
    }

    for demo_dir in demo_dirs:
        for path in demo_dir.rglob("*"):
            path_text = str(path)
            assert not any(fragment in path_text for fragment in forbidden_fragments)
            assert path.suffix not in forbidden_suffixes
