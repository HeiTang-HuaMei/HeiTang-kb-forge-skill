import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app

LLM_FILES = {
    "llm_cards.jsonl",
    "llm_qa_pairs.jsonl",
    "llm_glossary.jsonl",
    "frameworks.jsonl",
    "case_cards.jsonl",
    "metrics.jsonl",
}


def test_build_llm_prompt_profile_writes_metadata_manifest_and_report(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Prompt profile fixture for product manager metrics", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--llm",
            "--no-llm-cache",
            "--prompt-profile",
            "examples/prompt_profiles/product_manager.yaml",
        ],
    )

    assert result.exit_code == 0, result.output
    record = json.loads((output_dir / "llm_cards.jsonl").read_text(encoding="utf-8").splitlines()[0])
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    report = (output_dir / "ingest_report.md").read_text(encoding="utf-8")
    assert record["prompt_profile"] == "product_manager"
    assert record["prompt_profile_hash"]
    assert manifest["llm_prompt_profile"] == "product_manager"
    assert manifest["llm_prompt_profile_file"].endswith("examples/prompt_profiles/product_manager.yaml")
    assert "- Prompt profile: product_manager" in report


def test_prompt_profile_changes_cache_key(tmp_path):
    input_dir = tmp_path / "input"
    output_product = tmp_path / "product"
    output_shop = tmp_path / "shop"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Prompt profile cache key fixture", encoding="utf-8")

    product_result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_product),
            "--llm",
            "--no-llm-cache",
            "--prompt-profile",
            "examples/prompt_profiles/product_manager.yaml",
        ],
    )
    shop_result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_shop),
            "--llm",
            "--no-llm-cache",
            "--prompt-profile",
            "examples/prompt_profiles/shopping_guide.yaml",
        ],
    )

    assert product_result.exit_code == 0, product_result.output
    assert shop_result.exit_code == 0, shop_result.output
    product_record = json.loads((output_product / "llm_cards.jsonl").read_text(encoding="utf-8").splitlines()[0])
    shop_record = json.loads((output_shop / "llm_cards.jsonl").read_text(encoding="utf-8").splitlines()[0])
    assert product_record["prompt_profile"] == "product_manager"
    assert shop_record["prompt_profile"] == "shopping_guide"
    assert product_record["cache_key"] != shop_record["cache_key"]


def test_llm_without_prompt_profile_keeps_existing_metadata_shape(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("No prompt profile fixture", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output_dir), "--llm", "--no-llm-cache"])

    assert result.exit_code == 0, result.output
    record = json.loads((output_dir / "llm_cards.jsonl").read_text(encoding="utf-8").splitlines()[0])
    manifest = json.loads((output_dir / "manifest.json").read_text(encoding="utf-8"))
    assert record["prompt_profile"] is None
    assert record["prompt_profile_hash"] is None
    assert "llm_prompt_profile" not in manifest


def test_prompt_profile_requires_llm(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Profile without LLM fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "build",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--prompt-profile",
            "examples/prompt_profiles/product_manager.yaml",
        ],
    )

    assert result.exit_code != 0
    assert "--prompt-profile requires --llm" in str(result.exception)


def test_batch_llm_prompt_profile_writes_metadata(tmp_path):
    input_dir = tmp_path / "input"
    output_dir = tmp_path / "output"
    input_dir.mkdir()
    (input_dir / "001_lesson.md").write_text("Batch prompt profile fixture", encoding="utf-8")

    result = CliRunner().invoke(
        app,
        [
            "batch",
            "--input",
            str(input_dir),
            "--output",
            str(output_dir),
            "--llm",
            "--no-llm-cache",
            "--prompt-profile",
            "examples/prompt_profiles/product_manager.yaml",
        ],
    )

    assert result.exit_code == 0, result.output
    assert LLM_FILES.issubset({path.name for path in (output_dir / "001_lesson").iterdir()})
    record = json.loads((output_dir / "001_lesson" / "llm_cards.jsonl").read_text(encoding="utf-8").splitlines()[0])
    assert record["prompt_profile"] == "product_manager"
