import json

import pytest

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.knowledge_bound_factory import generate_knowledge_bound_agent


def test_knowledge_bound_factory_writes_skill_agent_and_reports(tmp_path):
    package = _package(tmp_path, "reviewed_knowledge_base")
    output = tmp_path / "factory"

    result = generate_knowledge_bound_agent(package, output, "Bound Skill", "Bound Agent")

    assert result["status"] == "pass"
    assert (output / "skill_package" / "SKILL.md").exists()
    assert (output / "agent_package" / "system_prompt.md").exists()
    assert (output / "skill_validation" / "skill_validation_result.json").exists()
    assert _json(output / "knowledge_bound_factory_quality_report.json")["kb_trust_status"] == "reviewed_knowledge_base"
    assert (output / "knowledge_bound_factory_report.md").exists()


def test_knowledge_bound_factory_blocks_draft_package_without_override(tmp_path):
    package = _package(tmp_path, "draft_knowledge_package")

    with pytest.raises(ValueError):
        generate_knowledge_bound_agent(package, tmp_path / "factory", "Draft Skill", "Draft Agent")


def _package(tmp_path, trust_status):
    package = tmp_path / trust_status
    package.mkdir()
    write_json(package / "manifest.json", {"package_id": "pkg-test", "kb_trust_status": trust_status})
    (package / "chunks.jsonl").write_text(
        json.dumps({"id": "c1", "text": "Grounded factory evidence.", "source": "lesson.md"}) + "\n",
        encoding="utf-8",
    )
    return package


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
