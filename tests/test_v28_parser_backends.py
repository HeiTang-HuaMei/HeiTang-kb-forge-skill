import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.exporters.jsonl_exporter import write_json


STANDARD_FILES = {
    "chunks.jsonl",
    "cards.jsonl",
    "qa_pairs.jsonl",
    "glossary.jsonl",
    "manifest.json",
    "ingest_report.md",
    "quality_report.json",
}

PARSER_FILES = {
    "parser_backend_result.json",
    "parser_backend_output.md",
    "parser_backend_output.json",
    "parse_quality_report.json",
    "parse_quality_report.md",
    "ocr_risk_report.json",
    "high_risk_pages.jsonl",
    "high_risk_parse_pages.jsonl",
    "high_risk_chunks.jsonl",
    "manual_review_queue.jsonl",
    "kb_trust_status.json",
    "trusted_kb_gate.json",
    "knowledge_reliability_report.json",
}


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def _jsonl(path):
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]


def test_parser_backend_list_reports_builtin_docling_and_marker():
    result = CliRunner().invoke(app, ["parser-backend-list"])

    assert result.exit_code == 0, result.output
    assert "builtin: available" in result.output
    assert "docling:" in result.output
    assert "marker:" in result.output


def test_parse_with_backend_builtin_writes_normalized_outputs(tmp_path):
    source = tmp_path / "input.md"
    output = tmp_path / "parse"
    source.write_text("# Title\n\nParser backend fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "builtin"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "success"
    assert payload["backend_name"] == "builtin"
    assert payload["records"][0]["status"] == "success"
    assert "Parser backend fixture" in payload["records"][0]["text"]
    assert (output / "parser_backend_output.md").exists()
    assert (output / "parser_backend_output.json").exists()


def test_parse_with_backend_unsupported_only_returns_warning(tmp_path):
    source = tmp_path / "input.bin"
    output = tmp_path / "parse"
    source.write_bytes(b"unsupported")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "builtin"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "warning"
    assert payload["source_count"] == 0
    assert "no_supported_sources" in payload["warnings"]


def test_optional_docling_backend_is_unavailable_without_crashing(tmp_path):
    source = tmp_path / "input.md"
    output = tmp_path / "docling"
    source.write_text("Docling optional fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(output), "--backend", "docling"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parser_backend_result.json")
    assert payload["status"] == "unavailable"
    assert payload["backend_name"] == "docling"
    assert payload["records"][0]["status"] in {"unavailable", "disabled"}


def test_parse_compare_records_optional_backend_differences(tmp_path):
    source = tmp_path / "input.md"
    output = tmp_path / "compare"
    source.write_text("Compare parser backend fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["parse-compare", "--input", str(source), "--output", str(output), "--backends", "builtin,docling,marker"])

    assert result.exit_code == 0, result.output
    payload = _json(output / "parse_compare_result.json")
    assert payload["status"] == "warning"
    assert payload["backends"] == ["builtin", "docling", "marker"]
    assert "docling" in payload["unavailable_backends"]
    assert "marker" in payload["unavailable_backends"]
    assert (output / "parse_compare_report.md").exists()


def test_default_build_keeps_standard_output_without_parser_files(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Default build parser backend remains off.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output)])

    assert result.exit_code == 0, result.output
    for file_name in STANDARD_FILES:
        assert (output / file_name).exists()
    for file_name in PARSER_FILES:
        assert not (output / file_name).exists()
    manifest = _json(output / "manifest.json")
    assert "parser_backend_enabled" not in manifest


def test_build_with_builtin_backend_writes_reliability_outputs_and_draft_metadata(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "package"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Parser backend build fixture.", encoding="utf-8")

    result = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(output), "--parser-backend", "builtin"])

    assert result.exit_code == 0, result.output
    for file_name in STANDARD_FILES | PARSER_FILES:
        assert (output / file_name).exists()
    manifest = _json(output / "manifest.json")
    assert manifest["parser_backend_enabled"] is True
    assert manifest["parser_backend"] == "builtin"
    assert manifest["kb_trust_status"] == "draft_knowledge_package"
    assert manifest["trusted_kb_gate_status"] == "fail"
    chunk = _jsonl(output / "chunks.jsonl")[0]
    assert chunk["metadata"]["parser_backend"] == "builtin"
    assert chunk["metadata"]["kb_trust_status"] == "draft_knowledge_package"
    assert chunk["metadata"]["parse_confidence"] == 0.95
    gate = _json(output / "trusted_kb_gate.json")
    assert gate["status"] == "fail"
    assert gate["blocked"] is True


def test_parse_quality_gate_writes_trust_status_and_review_outputs(tmp_path):
    source = tmp_path / "input.md"
    parse_output = tmp_path / "parse"
    quality_output = tmp_path / "quality"
    source.write_text("Quality gate parser backend fixture.", encoding="utf-8")
    parse_result = CliRunner().invoke(app, ["parse-with-backend", "--input", str(source), "--output", str(parse_output), "--backend", "builtin"])
    assert parse_result.exit_code == 0, parse_result.output

    result = CliRunner().invoke(app, ["parse-quality-gate", "--input", str(parse_output), "--output", str(quality_output)])

    assert result.exit_code == 0, result.output
    quality = _json(quality_output / "parse_quality_report.json")
    assert quality["kb_trust_status"] == "draft_knowledge_package"
    assert quality["trusted_kb_gate_status"] == "fail"
    assert (quality_output / "manual_review_queue.jsonl").exists()
    reliability = _json(quality_output / "knowledge_reliability_report.json")
    assert reliability["status"] == "fail"


def test_corrected_text_reimport_promotes_non_empty_text_and_keeps_empty_text_draft(tmp_path):
    corrected = tmp_path / "corrected"
    reviewed_output = tmp_path / "reviewed"
    empty_output = tmp_path / "empty"
    corrected.mkdir()
    (corrected / "fixed.md").write_text("Reviewed corrected parser text.", encoding="utf-8")

    reviewed = CliRunner().invoke(app, ["parse-reimport-corrected-text", "--corrected-text", str(corrected), "--output", str(reviewed_output)])

    assert reviewed.exit_code == 0, reviewed.output
    assert _json(reviewed_output / "parser_backend_result.json")["kb_trust_status"] == "reviewed_knowledge_base"
    assert _json(reviewed_output / "trusted_kb_gate.json")["status"] == "pass"
    assert _json(reviewed_output / "before_after_quality_diff.json")["status"] == "pass"

    empty_file = tmp_path / "empty.md"
    empty_file.write_text("", encoding="utf-8")
    empty = CliRunner().invoke(app, ["parse-reimport-corrected-text", "--corrected-text", str(empty_file), "--output", str(empty_output)])

    assert empty.exit_code == 0, empty.output
    assert _json(empty_output / "parser_backend_result.json")["kb_trust_status"] == "draft_knowledge_package"
    assert _json(empty_output / "trusted_kb_gate.json")["status"] == "fail"


def test_trusted_kb_gate_blocks_draft_allows_explicit_untrusted_and_keeps_legacy_compatible(tmp_path):
    draft = tmp_path / "draft"
    gate = tmp_path / "gate"
    allow_gate = tmp_path / "allow_gate"
    unknown = tmp_path / "unknown"
    legacy = tmp_path / "legacy"
    for path in [draft, unknown, legacy]:
        path.mkdir()
    write_json(draft / "kb_trust_status.json", {"kb_trust_status": "draft_knowledge_package"})
    write_json(unknown / "kb_trust_status.json", {"kb_trust_status": "surprise_status"})

    result = CliRunner().invoke(app, ["trusted-kb-gate", "--package", str(draft), "--output", str(gate)])
    assert result.exit_code == 1, result.output
    assert _json(gate / "trusted_kb_gate.json")["blocked"] is True

    allow = CliRunner().invoke(app, ["trusted-kb-gate", "--package", str(draft), "--output", str(allow_gate), "--allow-untrusted"])
    assert allow.exit_code == 0, allow.output
    allow_payload = _json(allow_gate / "trusted_kb_gate.json")
    assert allow_payload["status"] == "pass"
    assert allow_payload["trusted"] is False

    unknown_result = CliRunner().invoke(app, ["trusted-kb-gate", "--package", str(unknown), "--output", str(tmp_path / "unknown_gate")])
    assert unknown_result.exit_code == 1, unknown_result.output

    legacy_result = CliRunner().invoke(app, ["trusted-kb-gate", "--package", str(legacy), "--output", str(tmp_path / "legacy_gate")])
    assert legacy_result.exit_code == 0, legacy_result.output


def test_generate_skill_blocks_draft_parser_package_unless_allowed(tmp_path):
    input_dir = tmp_path / "input"
    package = tmp_path / "package"
    skill = tmp_path / "skill"
    allowed_skill = tmp_path / "allowed_skill"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Skill export gate parser backend fixture.", encoding="utf-8")
    build = CliRunner().invoke(app, ["build", "--input", str(input_dir), "--output", str(package), "--parser-backend", "builtin"])
    assert build.exit_code == 0, build.output

    blocked = CliRunner().invoke(app, ["generate-skill", "--package", str(package), "--output", str(skill)])
    assert blocked.exit_code != 0
    assert not (skill / "skill_manifest.yaml").exists()

    allowed = CliRunner().invoke(app, ["generate-skill", "--package", str(package), "--output", str(allowed_skill), "--allow-untrusted"])
    assert allowed.exit_code == 0, allowed.output
    manifest = (allowed_skill / "skill_manifest.yaml").read_text(encoding="utf-8")
    assert "kb_trust_status: draft_knowledge_package" in manifest


def test_config_skill_generation_blocks_parser_draft_unless_allow_untrusted(tmp_path):
    input_dir = tmp_path / "input"
    blocked_output = tmp_path / "blocked"
    allowed_output = tmp_path / "allowed"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Config skill trust gate fixture.", encoding="utf-8")
    blocked_config = tmp_path / "blocked.yaml"
    allowed_config = tmp_path / "allowed.yaml"
    blocked_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {blocked_output.as_posix()}
domain: parser_backend
mode: reliability
parser_backend:
  use_for_build: true
  default: builtin
skill:
  enabled: true
""",
        encoding="utf-8",
    )
    allowed_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {allowed_output.as_posix()}
domain: parser_backend
mode: reliability
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
skill:
  enabled: true
""",
        encoding="utf-8",
    )

    blocked = CliRunner().invoke(app, ["run", "--config", str(blocked_config)])
    assert blocked.exit_code != 0
    assert not (blocked_output / "skill_package" / "skill_manifest.yaml").exists()

    allowed = CliRunner().invoke(app, ["run", "--config", str(allowed_config)])
    assert allowed.exit_code == 0, allowed.output
    assert (allowed_output / "skill_package" / "skill_manifest.yaml").exists()


def test_pipeline_reports_parser_backend_gate_failure_and_allow_untrusted_success(tmp_path):
    input_dir = tmp_path / "input"
    fail_output = tmp_path / "pipeline_fail"
    pass_output = tmp_path / "pipeline_pass"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pipeline parser backend fixture.", encoding="utf-8")
    fail_config = tmp_path / "fail.yaml"
    pass_config = tmp_path / "pass.yaml"
    fail_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {fail_output.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
""",
        encoding="utf-8",
    )
    pass_config.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {pass_output.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
""",
        encoding="utf-8",
    )

    failed = CliRunner().invoke(app, ["pipeline", "--config", str(fail_config)])
    assert failed.exit_code == 0, failed.output
    failed_manifest = _json(fail_output / "pipeline_manifest.json")
    failed_stages = {stage["name"]: stage for stage in failed_manifest["stages"]}
    assert failed_stages["parser_backend_parse"]["status"] == "success"
    assert failed_stages["trusted_kb_gate"]["status"] == "failed"
    assert failed_stages["knowledge_reliability_report"]["status"] == "failed"
    assert failed_manifest["final_status"] == "fail"

    passed = CliRunner().invoke(app, ["pipeline", "--config", str(pass_config)])
    assert passed.exit_code == 0, passed.output
    passed_manifest = _json(pass_output / "pipeline_manifest.json")
    passed_stages = {stage["name"]: stage for stage in passed_manifest["stages"]}
    assert passed_stages["trusted_kb_gate"]["status"] == "success"
    assert passed_stages["knowledge_reliability_report"]["status"] == "success"
    assert passed_manifest["final_status"] == "pass"
