import json

from typer.testing import CliRunner

from heitang_kb_forge.cli import app
from heitang_kb_forge.knowledge_bound_factory import generate_knowledge_bound_agent, generate_standalone_agent
from heitang_kb_forge.multi_kb_orchestration import orchestrate_multi_kb_agents
from heitang_kb_forge.workbench_contracts import generate_workbench_contracts


def test_v30_v34_core_workbench_e2e_contract_bundle(tmp_path):
    input_dir = tmp_path / "input"
    output = tmp_path / "core"
    input_dir.mkdir()
    (input_dir / "lesson.md").write_text("Pricing policy evidence for local-first workbench contracts.", encoding="utf-8")
    config_path = tmp_path / "run.yaml"
    config_path.write_text(
        f"""
task: build
input: {input_dir.as_posix()}
output: {output.as_posix()}
parser_backend:
  use_for_build: true
  default: builtin
  allow_untrusted: true
document_generation:
  enabled: true
  formats: [md, docx, pdf, pptx]
  template: default_report
  grounding_policy: strict_grounded
""",
        encoding="utf-8",
    )

    result = CliRunner().invoke(app, ["run", "--config", str(config_path)])

    assert result.exit_code == 0, result.output
    assert (output / "generated_file_report.json").exists()
    assert (output / "generated.pptx").exists()
    manifest = _json(output / "manifest.json")
    manifest["kb_trust_status"] = "reviewed_knowledge_base"
    (output / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
    (output / "kb_trust_status.json").write_text(json.dumps({"kb_trust_status": "reviewed_knowledge_base"}), encoding="utf-8")

    bound = tmp_path / "bound"
    standalone = tmp_path / "standalone"
    mother = tmp_path / "mother"
    factory = generate_knowledge_bound_agent(output, bound, "Pricing Skill", "Pricing Agent")
    standalone_result = generate_standalone_agent(standalone, "Standalone Planner", "planning")
    generate_standalone_agent(mother, "Mother Agent", "routing")
    mother_manifest = _json(mother / "agent_manifest.json")
    mother_manifest["mode"] = "mother_agent"
    (mother / "agent_manifest.json").write_text(json.dumps(mother_manifest), encoding="utf-8")

    assert factory["status"] == "pass"
    assert standalone_result["mode"] == "standalone"
    orchestration = orchestrate_multi_kb_agents(
        [output],
        output,
        [bound / "agent_package", standalone],
        "pricing policy",
        mother,
        workflow_shared_memory=True,
        parent_writeback=True,
    )
    assert orchestration["status"] == "pass"
    assert orchestration["memory_candidate_count"] == 1

    contracts = generate_workbench_contracts(output, project_name="E2E Workbench")

    assert contracts["status"] == "ready"
    action_commands = {action["command"] for action in _json(output / "workbench_action_contract.json")["actions"]}
    assert {"generate-documents", "generate-agent --mode standalone", "generate-agent --mode kb_bound", "orchestrate-multi-kb --parent-writeback"}.issubset(action_commands)
    assert _json(output / "workbench_agent_contract.json")["supported_agent_modes"] == ["standalone", "kb_bound"]
    assert _json(output / "workbench_memory_contract.json")["policy"]["workflow_shared_memory"] == "explicit_only"
    storage = _json(output / "workbench_storage_contract.json")
    assert storage["storage_backend"] == "local_workspace"
    assert storage["future_backends"]["byo_cloud"]["platform_hosted_user_data"] is False
    hierarchy = _json(output / "hierarchy_trace.json")
    assert hierarchy["mother_agent"]["agent_id"] == "mother-agent"
    assert hierarchy["task_route"]["to"] == "pricing-agent"


def _json(path):
    return json.loads(path.read_text(encoding="utf-8"))
