from pathlib import Path

REQUIRED_ENHANCED_SKILL_FILES = [
    "TASKS.md",
    "INPUT_OUTPUT.md",
    "FAILURE_MODES.md",
    "SAFE_REFUSAL.md",
    "EVIDENCE_USAGE.md",
    "OPERATION_GUIDE.md",
    "RELEASE_CHECKLIST.md",
]


def validate_enhanced_skill(skill: Path, skill_type: str = "qa_skill") -> dict:
    missing = [file_name for file_name in REQUIRED_ENHANCED_SKILL_FILES if not (skill / file_name).exists()]
    return {
        "skill_type": skill_type,
        "required_files": REQUIRED_ENHANCED_SKILL_FILES,
        "missing_files": missing,
        "status": "passed" if not missing else "failed",
    }
