from pathlib import Path

from heitang_kb_forge.agent_package.generator import AGENT_PACKAGE_FILES, generate_agent_package
from heitang_kb_forge.exporters.jsonl_exporter import write_json
from heitang_kb_forge.llm.agent_generation_report import render_llm_agent_generation_report
from heitang_kb_forge.llm.call_log import write_call_log
from heitang_kb_forge.llm.provider import ProviderSettings, get_provider
from heitang_kb_forge.llm.rule_generator import generation_mode
from heitang_kb_forge.schemas.llm_agent_schema import LLMAgentGenerationReport


def generate_llm_agent_package(
    package: Path,
    skill: Path,
    output: Path,
    agent_name: str,
    agent_type: str,
    settings: ProviderSettings,
    enabled: bool,
    call_log: bool = True,
) -> tuple[str, LLMAgentGenerationReport]:
    fallback = False
    if enabled:
        try:
            provider = get_provider(settings)
            provider.generate_json(f"Agent generation for {agent_name}", "agent_generation")
            if call_log:
                write_call_log(output / "llm_call_log.jsonl", {"task": "agent_generation", "provider": settings.provider, "api_key": settings.api_key, "status": "success"})
        except Exception:
            fallback = True
            if call_log:
                write_call_log(output / "llm_call_log.jsonl", {"task": "agent_generation", "provider": settings.provider, "api_key": settings.api_key, "status": "fallback"})
    mode = generation_mode(enabled, settings.provider, fallback)
    generate_agent_package(package, skill, output, agent_name, agent_type, mode)
    report = LLMAgentGenerationReport(
        enabled=enabled,
        provider=settings.provider,
        fallback=fallback,
        generated_files=AGENT_PACKAGE_FILES,
        generated_by=mode,
        review_required=["human_review_recommended"] if enabled else [],
    )
    write_json(output / "llm_agent_generation_report.json", report.model_dump(mode="json"))
    (output / "llm_agent_generation_report.md").write_text(render_llm_agent_generation_report(report), encoding="utf-8")
    return mode, report
