from pathlib import Path
import shutil

from heitang_kb_forge.agent_package.profile import make_agent_profile, render_profile_yaml
from heitang_kb_forge.agent_package.prompts import make_agent_texts
from heitang_kb_forge.agent_package.report import render_agent_package_report
from heitang_kb_forge.agent_package.retrieval_config import make_retrieval_config
from heitang_kb_forge.agent_package.tool_config import make_tool_config


AGENT_PACKAGE_FILES = [
    "soul.md",
    "role.md",
    "system_prompt.md",
    "agent_profile.yaml",
    "tool_config.yaml",
    "retrieval_config.yaml",
    "skill_manifest.yaml",
    "memory_policy.md",
    "safety_boundary.md",
    "launch_checklist.md",
    "agent_package_report.md",
]


def generate_agent_package(
    package: Path,
    skill: Path,
    output: Path,
    agent_name: str,
    agent_type: str = "generic",
    generated_by: str = "rule_template",
) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    profile = make_agent_profile(package, skill, agent_name, agent_type)
    texts = make_agent_texts(agent_name, agent_type, generated_by)
    for file_name, content in texts.items():
        (output / file_name).write_text(content, encoding="utf-8")
    (output / "agent_profile.yaml").write_text(render_profile_yaml(profile), encoding="utf-8")
    (output / "tool_config.yaml").write_text(make_tool_config(), encoding="utf-8")
    (output / "retrieval_config.yaml").write_text(make_retrieval_config(), encoding="utf-8")
    if (skill / "skill_manifest.yaml").exists():
        shutil.copyfile(skill / "skill_manifest.yaml", output / "skill_manifest.yaml")
    else:
        (output / "skill_manifest.yaml").write_text("skill_id: unknown\n", encoding="utf-8")
    (output / "agent_package_report.md").write_text(
        render_agent_package_report(agent_name, AGENT_PACKAGE_FILES, generated_by),
        encoding="utf-8",
    )
    return {
        "agent_id": profile.agent_id,
        "agent_name": agent_name,
        "agent_type": agent_type,
        "output_files": AGENT_PACKAGE_FILES,
        "generated_by": generated_by,
    }
