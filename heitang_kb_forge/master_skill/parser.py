from pathlib import Path


SKILL_FILES = {
    "SKILL.md",
    "skill_manifest.yaml",
    "README.md",
    "rules.md",
    "prompt.md",
    "examples.md",
    "eval_cases.jsonl",
    "workflow.yaml",
    "tool_config.yaml",
    "retrieval_config.yaml",
    "CLAUDE.md",
    "codex_instructions.md",
    "mcp_manifest.json",
    "mcp_resources.json",
}


def collect_skill_files(path: Path) -> list[Path]:
    if path.is_file():
        return [path]
    return sorted(item for item in path.rglob("*") if item.is_file() and item.name in SKILL_FILES)


def read_skill_text(path: Path) -> str:
    return "\n\n".join(f"# File: {item.name}\n{item.read_text(encoding='utf-8', errors='ignore')}" for item in collect_skill_files(path))


def detect_skill_type(path: Path, text: str) -> str:
    lowered = text.lower()
    if "xiaohongshu" in lowered or "小红书" in text:
        return "xiaohongshu_content_skill"
    if "claude" in lowered:
        return "claude_code_instructions_package"
    if "codex" in lowered:
        return "codex_instructions_package"
    if "mcp" in lowered:
        return "mcp_skill_package"
    if (path / "SKILL.md").exists() if path.is_dir() else path.name == "SKILL.md":
        return "generic_skill"
    return "instructions_package"
