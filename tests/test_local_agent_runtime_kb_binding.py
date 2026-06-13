from heitang_kb_forge.agent_package import generate_agent_package
from heitang_kb_forge.local_agent_runtime import run_local_agent_runtime
from heitang_kb_forge.skill.generator import generate_skill_package
from tests.p0_helpers import write_json
from tests.v310_helpers import make_package, read_json


def test_generated_kb_bound_agent_uses_manifest_package_id_for_own_kb(tmp_path):
    package = make_package(tmp_path, "pkg-alpha", "Own KB evidence.")
    skill = tmp_path / "skill"
    agent = tmp_path / "agent"
    generate_skill_package(package, skill, "Alpha Skill")
    generate_agent_package(package, skill, agent, "Alpha Agent")

    profile = (agent / "agent_profile.yaml").read_text(encoding="utf-8")
    assert "source_package_id: pkg-alpha" in profile

    output = tmp_path / "runtime"
    run_local_agent_runtime([package], output, [agent], "Own KB evidence")
    access = read_json(output / "child_kb_access_report.json")
    trace = read_json(output / "local_agent_runtime_trace.json")

    assert access["authorized"] is True
    assert access["allowed_kbs"] == ["pkg-alpha"]
    assert read_json(output / "local_agent_runtime_status.json")["status"] == "pass"
    assert trace["steps"][2]["status"] == "pass"


def test_generated_agent_from_skill_pack_binds_own_kb_and_runtime_passes(tmp_path):
    package = make_package(tmp_path, "pkg-alpha", "Skill Pack bound KB evidence.")
    skill_pack = tmp_path / "skill_pack"
    agent = tmp_path / "agent"
    skill_pack.mkdir()
    write_json(
        skill_pack / "skill_pack_manifest.json",
        {"suite_id": "suite_pkg-alpha", "status": "ready"},
    )
    write_json(skill_pack / "suite.json", {"suite_id": "suite_pkg-alpha"})

    generate_agent_package(package, skill_pack, agent, "Skill Pack Agent")

    assert "source_skill_id: suite_pkg-alpha" in (
        agent / "agent_profile.yaml"
    ).read_text(encoding="utf-8")
    assert "skill_id: suite_pkg-alpha" in (
        agent / "skill_manifest.yaml"
    ).read_text(encoding="utf-8")

    output = tmp_path / "runtime"
    run_local_agent_runtime([package], output, [agent], "Need Skill Pack bound KB evidence")

    access = read_json(output / "child_kb_access_report.json")
    session = read_json(output / "local_agent_runtime_session.json")
    assert access["authorized"] is True
    assert access["allowed_kbs"] == ["pkg-alpha"]
    assert session["llm_used"] is False
    assert session["network_used"] is False
    assert session["evidence"][0]["text"] == "Skill Pack bound KB evidence."
    assert read_json(output / "local_agent_runtime_status.json")["status"] == "pass"


def test_generated_kb_bound_agent_still_denies_unauthorized_kb(tmp_path):
    package = make_package(tmp_path, "pkg-alpha")
    other = make_package(tmp_path, "pkg-beta")
    skill = tmp_path / "skill"
    agent = tmp_path / "agent"
    generate_skill_package(other, skill, "Beta Skill")
    generate_agent_package(other, skill, agent, "Beta Agent")

    output = tmp_path / "runtime"
    run_local_agent_runtime([package], output, [agent], "Need alpha evidence")
    access = read_json(output / "child_kb_access_report.json")

    assert access["authorized"] is False
    assert access["allowed_kbs"] == []
    assert access["blocked_kbs"] == ["pkg-beta"]
    assert read_json(output / "local_agent_runtime_status.json")["status"] == "blocked"
