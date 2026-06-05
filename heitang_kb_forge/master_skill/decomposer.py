from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.master_skill.parser import read_skill_text
from heitang_kb_forge.schemas.master_skill_schema import SkillDecomposition


def analyze_master_skill(skill: Path, output: Path) -> tuple[SkillDecomposition, str]:
    output.mkdir(parents=True, exist_ok=True)
    text = read_skill_text(skill)
    lines = [line.strip("-*# ") for line in text.splitlines() if line.strip()]
    name = skill.stem if skill.is_file() else skill.name
    decomposition = SkillDecomposition(
        skill_name=name,
        positioning=_first_matching(lines, ["use", "用于", "负责", "skill"]) or f"{name} task skill",
        scenarios=_matching(lines, ["when", "use", "场景", "适用"])[:8],
        input_types=_matching(lines, ["input", "输入", "file", "document"])[:8],
        output_types=_matching(lines, ["output", "输出", "report", "json", "md"])[:8],
        workflow_steps=_matching(lines, ["step", "流程", "before", "after", "run"])[:12],
        style_features=_matching(lines, ["style", "tone", "风格", "语气"])[:8],
        boundary_rules=_matching(lines, ["do not", "must not", "禁止", "不要", "边界"])[:12],
        prompt_patterns=_matching(lines, ["prompt", "instruction", "system", "提示词"])[:8],
    )
    payload = decomposition.model_dump(mode="json")
    write_json(output / "skill_decomposition.json", payload)
    write_json(output / "skill_capability_map.json", {"capabilities": decomposition.workflow_steps})
    write_json(output / "skill_workflow_graph.json", {"nodes": decomposition.workflow_steps, "edges": []})
    _write_yaml(output / "style_profile.yaml", "style_features", decomposition.style_features)
    _write_yaml(output / "strategy_profile.yaml", "workflow_steps", decomposition.workflow_steps)
    _write_yaml(output / "task_pattern_profile.yaml", "scenarios", decomposition.scenarios)
    _write_yaml(output / "boundary_profile.yaml", "boundary_rules", decomposition.boundary_rules)
    _write_yaml(output / "prompt_pattern_profile.yaml", "prompt_patterns", decomposition.prompt_patterns)
    report = f"# Skill Decomposition Report\n\n- Skill: {name}\n- Workflow steps: {len(decomposition.workflow_steps)}\n- Boundary rules: {len(decomposition.boundary_rules)}\n"
    (output / "skill_decomposition_report.md").write_text(report, encoding="utf-8")
    return decomposition, report


def _matching(lines: list[str], needles: list[str]) -> list[str]:
    return [line for line in lines if any(needle.lower() in line.lower() for needle in needles)]


def _first_matching(lines: list[str], needles: list[str]) -> str | None:
    matches = _matching(lines, needles)
    return matches[0] if matches else None


def _write_yaml(path: Path, key: str, values: list[str]) -> None:
    body = "\n".join(f"  - {value}" for value in values) or "  - generic"
    path.write_text(f"{key}:\n{body}\n", encoding="utf-8")
