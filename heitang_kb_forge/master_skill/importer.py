from hashlib import sha256
from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.master_skill.parser import collect_skill_files, detect_skill_type, read_skill_text
from heitang_kb_forge.schemas.master_skill_schema import MasterSkillInventory


def import_master_skill(input_path: Path, output: Path) -> tuple[MasterSkillInventory, str]:
    output.mkdir(parents=True, exist_ok=True)
    files = collect_skill_files(input_path)
    text = read_skill_text(input_path)
    name = input_path.stem if input_path.is_file() else input_path.name
    inventory = MasterSkillInventory(
        master_skill_id=sha256(str(input_path).encode("utf-8")).hexdigest()[:16],
        skill_name=name,
        source_path=str(input_path).replace("\\", "/"),
        detected_files=[str(file.relative_to(input_path) if input_path.is_dir() else file.name).replace("\\", "/") for file in files],
        detected_skill_type=detect_skill_type(input_path, text),
        parse_status="success" if files else "partial",
        warnings=[] if files else ["no_known_skill_files_found"],
    )
    write_json(output / "master_skill_inventory.json", inventory.model_dump(mode="json"))
    report = f"# Master Skill Parse Report\n\n- Skill: {inventory.skill_name}\n- Type: {inventory.detected_skill_type}\n- Files: {len(inventory.detected_files)}\n- Status: {inventory.parse_status}\n"
    (output / "master_skill_parse_report.md").write_text(report, encoding="utf-8")
    return inventory, report
