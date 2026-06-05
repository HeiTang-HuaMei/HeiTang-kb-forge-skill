from pathlib import Path

from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.llm.call_log import write_call_log
from heitang_kb_forge.llm.provider import ProviderSettings, get_provider
from heitang_kb_forge.llm.rule_generator import generation_mode
from heitang_kb_forge.llm.skill_generation_report import render_llm_skill_generation_report
from heitang_kb_forge.schemas.llm_skill_schema import LLMSkillGenerationReport
from heitang_kb_forge.skill.generator import SKILL_PACKAGE_FILES, generate_skill_package


def generate_llm_skill_package(
    package: Path,
    output: Path,
    skill_name: str,
    skill_type: str,
    settings: ProviderSettings,
    enabled: bool,
    call_log: bool = True,
) -> tuple[str, LLMSkillGenerationReport]:
    fallback = False
    if enabled:
        try:
            provider = get_provider(settings)
            provider.generate_json(f"Skill generation for {skill_name}", "skill_generation")
            if call_log:
                write_call_log(output / "llm_call_log.jsonl", {"task": "skill_generation", "provider": settings.provider, "api_key": settings.api_key, "status": "success"})
        except Exception:
            fallback = True
            if call_log:
                write_call_log(output / "llm_call_log.jsonl", {"task": "skill_generation", "provider": settings.provider, "api_key": settings.api_key, "status": "fallback"})
    mode = generation_mode(enabled, settings.provider, fallback)
    generate_skill_package(package, output, skill_name, skill_type, mode)
    report = LLMSkillGenerationReport(
        enabled=enabled,
        provider=settings.provider,
        fallback=fallback,
        generated_files=SKILL_PACKAGE_FILES,
        generated_by=mode,
        review_required=["human_review_recommended"] if enabled else [],
    )
    write_json(output / "llm_skill_generation_report.json", report.model_dump(mode="json"))
    (output / "llm_skill_generation_report.md").write_text(render_llm_skill_generation_report(report), encoding="utf-8")
    return mode, report
