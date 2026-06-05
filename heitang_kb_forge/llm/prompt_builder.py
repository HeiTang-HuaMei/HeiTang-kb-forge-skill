from pathlib import Path


def build_skill_prompt(package: Path, skill_name: str) -> str:
    return f"Generate package-scoped Skill files for {skill_name} from {package}."


def build_agent_prompt(package: Path, skill: Path, agent_name: str) -> str:
    return f"Generate package-scoped Agent files for {agent_name} from {package} and {skill}."
